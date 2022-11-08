import MetalKit

struct Arrow2D {
    var tail: float2
    var head: float2
    var direction: float2
    var target: float2 = float2(0)
}

class Pipe: Node {
    
    var particleSystemSharing: UnsafeMutableRawPointer?
    var fluidColor: TubeColors!
    var highlighted = false
    var selectColor: float3!

    private var _parentReservoirRef: UnsafeMutableRawPointer!
    var splineRef: UnsafeMutableRawPointer?
    var leftFixRef: UnsafeMutableRawPointer?
    var rightFixRef: UnsafeMutableRawPointer?
    private var _wallRef: UnsafeMutableRawPointer!
    func getWallRef() -> UnsafeMutableRawPointer { return _wallRef }
    
    private var _leftVertices:  [float2] = []
    private var _rightVertices: [float2] = []
    private var _b2leftVertices: [Vector2D] = []
    private var _b2rightVertices: [Vector2D] = []
    private var _sourceVertices: [float2] = [] // path vertices
    private var _sourceTangents: [Vector2D] = [] // perpendicular vector at each source vertex
    private var _perpendiculars: [float2] = []
    
    private var _textureType: TextureTypes = .PipeTexture
    private var _mesh: CustomMesh!
    
    var modelConstants = ModelConstants()
    private var _fluidConstants: FluidConstants!
    private var _fluidBuffer: MTLBuffer!
    private var _vertexBuffer: MTLBuffer!
    private var _vertexCount: Int = 0
    private var _controlPointsVertexBuffer: MTLBuffer!
    private var _controlPointsCount: Int = 0
    
    private var _interpolatedPointsBuffer: MTLBuffer!
    private var _interpolatedPointsCount: Int = 0
    
    private var _pipeWidth: Float = 0.4
    var debugging = false
    var segmentIndex = 0
    var totalSegments = 0
    
    var controlPoints: [float2] = [] { didSet { updateBox2DControlPts(); makeSpline(); updateModelConstants(); } }
    var tControlPoints: [Float] = []
    var _tSourcePoints: [Float] = []
    private var _interpolatedXValues: [Float] = []
    private var _interpolatedYValues: [Float] = []
    var interpolatedPoints: [float2] = []
    
    var box2DControlPts: [Vector2D] = []
    let segmentDensity: Int!
    var doneBuilding = false
    var originArrow: Arrow2D
    var wallSegmentPosition: Vector2D!
    private var _timeTicked: Float = 0.0
    
    init(_ pipeSegmentDensity: Int = 2, pipeWidth: Float, parentReservoir: UnsafeMutableRawPointer, wallRef: UnsafeMutableRawPointer, originArrow: Arrow2D, reservoirColor: TubeColors) {
        self.wallSegmentPosition = Vector2D(x:originArrow.head.x,y:originArrow.head.y)
        self._pipeWidth = pipeWidth
        self.fluidColor = reservoirColor
        self.segmentDensity = pipeSegmentDensity
        self._parentReservoirRef = parentReservoir
        self._wallRef = wallRef
        self.originArrow = originArrow
        super.init()
        _mesh = CustomMesh()
        _fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
        selectColor = WaterColors[ reservoirColor ]?.xyz ?? float3(1.0,0.0,0.0)
    }
    
    func shareFilter(_ withParticleSystem: UnsafeMutableRawPointer) {
        particleSystemSharing = withParticleSystem
        if(leftFixRef != nil && rightFixRef != nil ) {
            LiquidFun.shareParticleSystemFilter(withFixture: leftFixRef, particleSystem: withParticleSystem)
            LiquidFun.shareParticleSystemFilter(withFixture: rightFixRef, particleSystem: withParticleSystem)
        }
    }
    func resetFilter() {
        if(leftFixRef != nil && rightFixRef != nil ) {
            LiquidFun.setDefaultFilterForFixture(leftFixRef)
            LiquidFun.setDefaultFilterForFixture(rightFixRef)
        }
    }
    
    func toggleFixtures() {
        if ( _leftVertices.count < 2 || _rightVertices.count < 2 ) { return }
        let bulbPos = LiquidFun.getBulbPos(_parentReservoirRef)
        _b2leftVertices = _leftVertices.map { Vector2D(x:$0.x - bulbPos.x,y:$0.y - bulbPos.y) }
        _b2rightVertices = _rightVertices.map { Vector2D(x:$0.x - bulbPos.x,y:$0.y - bulbPos.y) }
        if(leftFixRef == nil && rightFixRef == nil) {
            leftFixRef = LiquidFun.makePipeFixture(_parentReservoirRef, lineVertices: &_b2leftVertices, vertexCount: _leftVertices.count)
            rightFixRef = LiquidFun.makePipeFixture(_parentReservoirRef, lineVertices: &_b2rightVertices, vertexCount: _rightVertices.count)
        } else {
            LiquidFun.destroyPipeFixture(_parentReservoirRef, lineRef: leftFixRef)
            LiquidFun.destroyPipeFixture(_parentReservoirRef, lineRef: rightFixRef)
            leftFixRef = nil
            rightFixRef = nil
        }
    }
    func attachFixtures() {
        toggleFixtures()
        if( leftFixRef == nil && rightFixRef == nil ) {
        toggleFixtures()
        }
    }
    
    var valveOpen = false
    var isRotatingSegment = false
    func toggleValve() {
        if( valveOpen ){
            destAngle = 0.0
            isRotatingSegment = true
            valveOpen = false
        } else {
            destAngle = .pi / 2
            isRotatingSegment = true
            valveOpen = true
        }
    }
    
    func closeValve() {
        if( valveOpen ) {
            destAngle = 0.0
            isRotatingSegment = true
            highlighted = true
            valveOpen = false
        } else { print("valve already closed")}
    }
    func openValve() {
        if( !valveOpen ) {
            destAngle = .pi / 2
            isRotatingSegment = true
            highlighted = true
            valveOpen = true
        } else { print("valve already open")}
    }
    func updatePipe( _ deltaTime: Float ){
        if( isRotatingSegment ) {
            rotateSegmentStep( deltaTime )
        }
        _timeTicked += deltaTime
    }
    
    func transferParticles( _ toSystem: UnsafeMutableRawPointer ) -> Int {
        if(particleSystemSharing == toSystem) { print("good transfer") }
        if(_parentReservoirRef != nil ) {
        return LiquidFun.transferParticles(_parentReservoirRef, wallSegmentPosition: wallSegmentPosition, toSystem: toSystem)
        } else {
            print("pipe transfer WARN::tried to transfer particles after reservoir destroyed")
            return 0
        }
    }
    
    var destAngle: Float = .pi / 2
    func rotateSegmentStep(_ deltaTime: Float) {
        var angV: Float = 4.0
        
        let currAngle = LiquidFun.getWallAngle(_parentReservoirRef, wallBodyRef: _wallRef)
        let angleToClose = destAngle - currAngle
        if( angleToClose < 0.0 ) {
            angV *= -1.0
        }
        var change = angV * deltaTime
        let maxIterations = 100
        var iterNum = 0
        while(abs( change ) > abs( angleToClose ) && iterNum < maxIterations) {
            angV *= 0.99
            change = angV * deltaTime
            iterNum += 1
        }
        LiquidFun.setWallAngV(_parentReservoirRef, wallBodyRef: _wallRef, angV: angV)
        if( abs(angleToClose) < 0.01 ){
            LiquidFun.setWallAngV(_parentReservoirRef, wallBodyRef: _wallRef, angV: 0.0)
            isRotatingSegment = false
            highlighted = false
        }
        if( particleSystemSharing != nil ){
            LiquidFun.transferParticles(_parentReservoirRef, wallSegmentPosition: wallSegmentPosition, toSystem: particleSystemSharing)
        }
    }
    
    func buildPipeSegment() {
        if segmentIndex < totalSegments - 1 {
            _sourceVertices = [float2].init( repeating: float2(0), count: segmentIndex )
            for i in 0..<segmentIndex {
                _sourceVertices[i] = interpolatedPoints[i]
            }
            segmentIndex += 1
            buildPipeVertices()
        }
    }
    func unBuildPipeSegment() {
        if segmentIndex < totalSegments && ( segmentIndex > -1 ) {
            _sourceVertices = [float2].init( repeating: float2(0), count: segmentIndex )
            for i in 0..<segmentIndex {
                _sourceVertices[i] = interpolatedPoints[i]
            }
            segmentIndex -= 1
            buildPipeVertices()
        }
    }
    
    func setSourceTVals(excludeFirstAndLast: Bool = true) {
        if( controlPoints.count < 2 ) { print("Pipe build from control points WARN:: none or not enough control points."); return}
        if( controlPoints.count < 4 && excludeFirstAndLast ) { print("Pipe build from control points WARN:: none or not enough control points."); return}
        var trimmedControlPoints = tControlPoints
        if( excludeFirstAndLast ) {
            trimmedControlPoints.removeFirst()
            trimmedControlPoints.removeLast()
        }
        let minT = trimmedControlPoints.min()!
        let maxT = trimmedControlPoints.max()!
        totalSegments = trimmedControlPoints.count * segmentDensity
        let increment = (maxT - minT) / Float( totalSegments  )
        _tSourcePoints = Array( stride(from: minT, to: maxT + increment, by: increment ))
        if !(_tSourcePoints.count == totalSegments) {
            print("param t src array WARN::trimmed totalSegments \(totalSegments) not equal to array size \(_tSourcePoints.count)")
        }
        totalSegments = _tSourcePoints.count
    }
    
    func setInterpolatedPositions() {
        //initialize array sizes
        let count = _tSourcePoints.count
        _interpolatedXValues = _tSourcePoints
        _interpolatedYValues = _tSourcePoints
        _sourceTangents = [Vector2D].init(repeating: Vector2D(x:0,y:0), count: count)
        _perpendiculars = [float2].init(repeating: float2(0,0), count: count)
        interpolatedPoints = [float2].init(repeating: float2(0,0), count: count)
        // if we have the spline, write to the arrays with their pointers.
        if( splineRef != nil ) {
            LiquidFun.setInterpolatedValues(splineRef, tVals: &_tSourcePoints, onXVals: &_interpolatedXValues, onYVals: &_interpolatedYValues, onTangents: &_sourceTangents, valCount: count)
            for i in 0..<interpolatedPoints.count {
                interpolatedPoints[i].x = _interpolatedXValues[i]
                interpolatedPoints[i].y = _interpolatedYValues[i]
                // rotate each tangent vector ninety deg., from this we can construct pipe vertices
                _perpendiculars[i] = MoveableArrow2D.ninetyDegreeRotMat * float2(_sourceTangents[i].x, _sourceTangents[i].y)
            }
        } else { print("setInterpolatedPositions WARN:: spline was nil")}
    }
    
    func updateBox2DControlPts() {
        box2DControlPts = (controlPoints.map { Vector2D(x:$0.x,y:$0.y) })
    }
    
    func makeSpline() {
        if controlPoints.count > 0{
            splineRef = LiquidFun.makeSpline( &tControlPoints, withControlPoints: &box2DControlPts, controlPtsCount: controlPoints.count )
            setSourceTVals()
            setInterpolatedPositions()
        }
    }
    func updateModelConstants() {
        let fluidConstantsLength = FluidConstants.stride
        _fluidBuffer = Engine.Device.makeBuffer(bytes: &_fluidConstants, length: fluidConstantsLength, options: [])
        
        _controlPointsCount = controlPoints.count
        if _controlPointsCount > 0 {
            let controlPointsLength = float2.stride( _controlPointsCount )
            _controlPointsVertexBuffer = Engine.Device.makeBuffer(bytes: &controlPoints, length: controlPointsLength, options: [])
        }
        _interpolatedPointsCount = interpolatedPoints.count
        if _interpolatedPointsCount > 0 {
            let interpPointsSize = float2.stride( _interpolatedPointsCount )
            _interpolatedPointsBuffer = Engine.Device.makeBuffer(bytes: &interpolatedPoints, length: interpPointsSize, options: [])
        }
    }
    
    
    func buildPipeVertices() {
        if( _sourceVertices.count < 2 ) { // need at least 4 vertices (from 2 source points)
            return
        }
        var newLeftVertices = _sourceVertices
        var newRightVertices = _sourceVertices // resizes both arrays
        var customVertices = [CustomVertex].init(repeating: CustomVertex(position: float3(0),
                                                                         color: float4(1.0,0.0,0.0,1.0),
                                                                         textureCoordinate: float2(0)), count: _sourceVertices.count * 2)

        var indices: [UInt32] = []
        var currIndex: UInt32 = 1
        for (i, v) in _sourceVertices.enumerated() {
            newLeftVertices[i] = v + _perpendiculars[i] * _pipeWidth / 2
            newRightVertices[i] = v - _perpendiculars[i] * _pipeWidth / 2
            customVertices[ Int(currIndex) - 1 ].position = float3(newLeftVertices[i].x, newLeftVertices[i].y, 0)
            customVertices[ Int(currIndex) - 1 ].textureCoordinate = float2(0,Float(i % 2))
            customVertices[ Int(currIndex) ].position = float3(newRightVertices[i].x, newRightVertices[i].y, 0)
            customVertices[ Int(currIndex) ].textureCoordinate =  float2(1, Float(i % 2))
            if currIndex > 2 {
                let triangle0 = [ currIndex - 3, currIndex - 2, currIndex - 1].map( { UInt32($0) } )
                let triangle1 = [ currIndex - 2, currIndex - 1, currIndex ].map( { UInt32($0) } )
                indices.append(contentsOf: triangle0)
                indices.append(contentsOf: triangle1)
            }
            currIndex += 2
        }
        _leftVertices = newLeftVertices
        _rightVertices = newRightVertices
        _vertexCount = newLeftVertices.count + newRightVertices.count
        _mesh.setIndices( indices )
        _mesh.setVertices( customVertices )
    }
    }

extension Pipe: Renderable {
    func doRender( _ renderCommandEncoder : MTLRenderCommandEncoder ) {
        if( _vertexCount > 3 ) { // we wont have indices set until we have at least 4 vertices
            if highlighted {
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.SelectCustomBox2D))
                renderCommandEncoder.setFragmentBytes(&_timeTicked, length : Float.size, index : 0)
                renderCommandEncoder.setFragmentBytes(&selectColor, length : float3.size, index : 2)
            }
            else {
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.CustomBox2D))
            }
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBytes(&_fluidConstants,
                                                length: FluidConstants.stride,
                                                index: 3)
        renderCommandEncoder.setFragmentTexture(Textures.Get(_textureType), index: 0)
        _mesh.drawPrimitives( renderCommandEncoder )
        }
        if debugging {
        controlPointsRender( renderCommandEncoder )
        interpolatedPointsRender( renderCommandEncoder )
        }
    }
    
    func controlPointsRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if _controlPointsCount > 0 {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Points))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            renderCommandEncoder.setVertexBuffer(_controlPointsVertexBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBuffer(_fluidBuffer,
                                                 offset: 0,
                                                 index: 3)
            renderCommandEncoder.drawPrimitives(type: .point,
                                                vertexStart: 0,
                                                vertexCount: _controlPointsCount)
        }
    }
    func interpolatedPointsRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if _interpolatedPointsCount > 0 {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Points))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            renderCommandEncoder.setVertexBuffer(_interpolatedPointsBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBuffer(_fluidBuffer,
                                                 offset: 0,
                                                 index: 3)
            renderCommandEncoder.drawPrimitives(type: .point,
                                                vertexStart: 0,
                                                vertexCount: _interpolatedPointsCount)
        }
    }
}
