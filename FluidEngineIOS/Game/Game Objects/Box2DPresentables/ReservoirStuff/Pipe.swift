import MetalKit

struct Arrow2D {
    var tail: float2
    var head: float2
    var direction: float2
    var target: float2 = float2(0)
}

class Pipe: Node {
    
    var splineRef: UnsafeMutableRawPointer?
    
    private var _leftVertices:  [float2] = []
    private var _rightVertices: [float2] = []
    private var _sourceVertices: [float2] = [] // path vertices
    private var _sourceTangents: [float2] = [] // perpendicular vector at each source vertex
    
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
    
    var controlPoints: [float2] = [] { didSet { updateBox2DControlPts(); makeSpline(); updateModelConstants(); }}
    var _ySourcePoints: [Float] = []
    var _interpolatedXValues: [Float] = []
    var interpolatedPoints: [float2] = []
    
    var box2DControlPts: [Vector2D] = []
    let segmentDensity: Int!
    var doneBuilding = false
    
    init(_ pipeSegmentDensity: Int = 10) {
        self.segmentDensity = pipeSegmentDensity
        super.init()
        _mesh = CustomMesh()
        _fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
    }
    
    func setSourceYValuesFromControlPoints(excludeFirstAndLast: Bool = true) {
        if( controlPoints.count < 2 ) { print("Pipe build from control points WARN:: none or not enough control points."); return}
        if( controlPoints.count < 4 && excludeFirstAndLast ) { print("Pipe build from control points WARN:: none or not enough control points."); return}
        var trimmedControlPoints = controlPoints
        if( excludeFirstAndLast ) {
            trimmedControlPoints.removeFirst()
            trimmedControlPoints.removeLast()
        }
        var totalControlPointsPathLength: Float = 0.0
        for i in 0..<trimmedControlPoints.count - 1 {
            totalControlPointsPathLength += length( trimmedControlPoints[i + 1]  - trimmedControlPoints[i] )
        }
        //segment density is number of segments per 1.0 length unit.
        let totalSegmentCount: Int = Int( Float( segmentDensity ) * totalControlPointsPathLength )
        totalSegments = totalSegmentCount
        let yValues = trimmedControlPoints.map { $0.y }
        
        let yMin = yValues.min()!
        let yMax = yValues.max()!
        let yRange =  yMax - yMin
        let yStep = yRange / Float(totalSegmentCount)
        _ySourcePoints = Array( stride(from: yMin, to: yMax, by: yStep) )
    }
    
    func setInterpolatedPositions() {
        _interpolatedXValues = _ySourcePoints
        let count = _ySourcePoints.count
        if( splineRef != nil ) {
        LiquidFun.setInterpolatedValues(splineRef, yVals: &_ySourcePoints, onXVals: &_interpolatedXValues, valCount: count)
            interpolatedPoints = [float2].init(repeating: float2(0), count: count)
            for i in 0..<interpolatedPoints.count {
                interpolatedPoints[i].x = _interpolatedXValues[i]
                interpolatedPoints[i].y = _ySourcePoints[i]
            }
        } else { print("setInterpolatedPositions WARN:: spline was nil")}
    }
    
    func updateBox2DControlPts() {
        box2DControlPts = (controlPoints.map { Vector2D(x:$0.x,y:$0.y) })
    }
    func makeSpline() {
        if controlPoints.count > 0{
            splineRef = LiquidFun.makeSpline( &box2DControlPts, controlPtsCount: controlPoints.count )
            setSourceYValuesFromControlPoints()
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
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if( _vertexCount > 3 ) { // we wont have indices set until we have at least 4 vertices
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.CustomBox2D))
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBytes(&_fluidConstants,
                                                length: FluidConstants.stride,
                                                index: 3)
        renderCommandEncoder.setFragmentTexture(Textures.Get(_textureType), index: 0)
        _mesh.drawPrimitives( renderCommandEncoder )
        }
        controlPointsRender( renderCommandEncoder )
        interpolatedPointsRender( renderCommandEncoder )
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

    func setSourceVectors(pathVertices: [float2], pathVectors: [float2]) {
        _sourceVertices = pathVertices
        _sourceTangents = [float2].init(repeating: float2(0), count: pathVectors.count)
        // rotate each pathVector ninety deg. (so it is tangent), from this we can construct pipe vertices
        for i in 0..<pathVectors.count {
            _sourceTangents[i] = MoveableArrow2D.ninetyDegreeRotMat * pathVectors[i]
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
            newLeftVertices[i] = v + _sourceTangents[i] * _pipeWidth / 2
            newRightVertices[i] = v - _sourceTangents[i] * _pipeWidth / 2
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
    
    func createFixtures(_ onReservoir: UnsafeMutableRawPointer, bulbCenter: float2, pipeIndex: Int ) {
        var b2LeftVertices = _leftVertices.map() { Vector2D(x:Float32($0.x - bulbCenter.x),y:Float32($0.y - bulbCenter.y))}
        var b2RightVertices = _rightVertices.map() { Vector2D(x:Float32($0.x - bulbCenter.x ),y:Float32($0.y - bulbCenter.y))}
        LiquidFun.makePipeFixture(onReservoir,
                                  leftVertices: &b2LeftVertices,
                                  rightVertices: &b2RightVertices,
                                  leftVertexCount: Int32(_leftVertices.count),
                                  rightVertexCount: Int32(_rightVertices.count),
                                  at: pipeIndex)
    }
    func destroyFixtures(_ onReservoir: UnsafeMutableRawPointer) {
        LiquidFun.destroyPipeFixtures( onReservoir )
    }
}
