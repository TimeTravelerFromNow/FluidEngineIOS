import MetalKit

struct Arrow2D {
    var tail: float2
    var head: float2
    var direction: float2
    var target: float2 = float2(0)
}

class Pipe: Node {
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
    
    private var _pipeWidth: Float = 0.4
    var debugging = false
    var segmentIndex = 0
    var totalSegments = 0
    
    var controlPoints: [float2] = [] { didSet { updateModelConstants()  }}
    let segmentDensity: Int!
    var doneBuilding = false
    
    func initializeVertexPositions() {
        setSourceVerticesFromControlPoints()
        buildPipeVertices()
    }
    
    func setSourceVerticesFromControlPoints(excludeFirstAndLast: Bool = true) {
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
        let xValues = trimmedControlPoints.map { $0.x }
        
        let xMin = xValues.min()!
        let xMax = xValues.max()!
        let xRange =  xMax - xMin
        let xStep = xRange / Float(totalSegmentCount)
        let xSourcePoints: [Float] = Array( stride(from: xMin, to: xMax, by: xStep) )

        getInterpolatedPosition(xSourcePoints, controlPoints)
    }
    
    func sylvestersFormula(_ x: Float, _ functionControlPts: [float2] ) -> Float { // yVal interpolation result from controlPoints
        var yVal: Float = 0.0;
        for i in 0..<functionControlPts.count {
            let x_i = functionControlPts[i].x
            let y_i = functionControlPts[i].y
            var product: Float = 1.0
            for j in 0..<functionControlPts.count {
                if( j != i ) {
                    let x_j = functionControlPts[j].x
                    if( x_i != x_j ) {
                        product *= ( x -  x_j ) / ( x_i - x_j )
                    }
                    else {
                        print("WARN:: sylvester formula will give bad result, two x values are identical."); return 0.0}
                }
            }
            product *= y_i
            yVal += product
        }
        return yVal
    }
    
    func getInterpolatedPosition(_ fromXPositions: [Float], _ functionControlPts: [float2] ) {
        var tangents: [float2] = []
        var positions: [float2] = []
        let desiredDerivativeAccuracy: Float = 0.98
        let maxDerivativeIterations: Int = 10
        
        for xVal in fromXPositions {
            let yVal = sylvestersFormula( xVal, functionControlPts )
            var derivativeIterations = 0
            var currentDerivativeAccuracy: Float = 0.0
            var currentDerivative: Float = 0.0
            var nextDerivative: Float  = 0.0
            var dX: Float = 0.01
        var tangent: float2 = float2(0)
            while( currentDerivativeAccuracy < desiredDerivativeAccuracy && derivativeIterations < maxDerivativeIterations ) {
                (currentDerivative, tangent) = getDerivativeAndTangent(ofInterpFunction: sylvestersFormula, x: xVal, dX: dX, functionControlPts: functionControlPts)
                dX *= 0.99
                (nextDerivative, tangent) = getDerivativeAndTangent(ofInterpFunction: sylvestersFormula, x: xVal, dX: dX, functionControlPts: functionControlPts)
                currentDerivativeAccuracy =  1.0 - ( currentDerivative - nextDerivative ) / nextDerivative // assume accuracy will be better for next to calc error
                derivativeIterations += 1
            }
            
            let position = float2(xVal, yVal)
            tangent = MoveableArrow2D.ninetyDegreeRotMat * tangent
            tangents.append( tangent )
            positions.append( position )
        }
        setSourceVectors(pathVertices: positions, pathVectors: tangents)
    }
    
    func getDerivativeAndTangent( ofInterpFunction: (Float, [float2] ) -> Float, x: Float, dX: Float, functionControlPts: [float2] ) -> (Float, float2) {
        let y0 = ofInterpFunction( x - dX , functionControlPts )
        let y1 = ofInterpFunction( x + dX , functionControlPts )
        let derivative = ( y1 - y0 ) / dX
        let angle = atan( derivative / 2 )
        let tangent = float2(sin(angle), cos(angle))
        return ( derivative , tangent )
    }
    
    init(_ pipeSegmentDensity: Int = 10) {
        self.segmentDensity = pipeSegmentDensity
        super.init()
        _mesh = CustomMesh()
        _fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
    }
    
    func updateModelConstants() {
        let fluidConstantsLength = FluidConstants.stride
        _fluidBuffer = Engine.Device.makeBuffer(bytes: &_fluidConstants, length: fluidConstantsLength, options: [])
        
        _controlPointsCount = controlPoints.count
        let controlPointsLength = float2.stride( _controlPointsCount )
        _controlPointsVertexBuffer = Engine.Device.makeBuffer(bytes: &controlPoints, length: controlPointsLength, options: [])
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
