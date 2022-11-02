import MetalKit

class Pipe: Node {
    private var _leftVertices:  [float2] = []
    private var _rightVertices: [float2] = []
    private var _sourceVertices: [float2] = [] // path vertices
    private var _sourceTangents: [float2] = [] // perpendicular vector at each source vertex
    
    private var _textureType: TextureTypes = .PipeTexture
    private var _mesh: CustomMesh!
    
    var modelConstants = ModelConstants()
    var fluidConstants: FluidConstants!
    private var _vertexBuffer: MTLBuffer!
    private var _vertexCount: Int = 0
    private let _ninetyDegreeRotMat = matrix_float2x2( float2( cos(.pi/2), sin(.pi/2) ),
                                                        float2( -sin(.pi/2), cos(.pi/2) ) )
    
    private var _pipeWidth: Float = 0.5
    var debugging = true
    var controlPointIndex = 0
    
    override init() {
        super.init()
        _mesh = CustomMeshes.Get(.Quad)
        self.setScale(1 / ( GameSettings.ptmRatio * 5 ) )
        self.setPositionZ(0.1)
        fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
    }
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if( _vertexCount > 3 ) { // we wont have indices set until we have at least 4 vertices
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.CustomBox2D))
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBytes(&fluidConstants,
                                                length: ModelConstants.stride,
                                                index: 3)
        renderCommandEncoder.setFragmentTexture(Textures.Get(_textureType), index: 0)
        _mesh.drawPrimitives( renderCommandEncoder )
        }
        if(debugging) {
            if _vertexCount > 2 {
                makeDebugVertexBuffer()
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Lines))
                renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
                renderCommandEncoder.setVertexBuffer(_vertexBuffer,
                                                     offset: 0,
                                                     index: 0)
//                renderCommandEncoder.setVertexBuffer(_fluidBuffer,
//                                                     offset: 0,
//                                                     index: 3)
//                renderCommandEncoder.setVertexBuffer(_colorBuffer,
//                                                     offset: 0,
//                                                     index: 4)
                renderCommandEncoder.drawPrimitives(type: .point,
                                                    vertexStart: 0,
                                                    vertexCount: _vertexCount * 2)
            }
        }
    }
    
   func makeDebugVertexBuffer() { // MARK: bad code (so only for debugging)
       var vertexBytes = _leftVertices
       vertexBytes.append(contentsOf: _rightVertices)
       _vertexBuffer = Engine.Device.makeBuffer(bytes: vertexBytes, length: float2.stride(_leftVertices.count + _rightVertices.count), options: [])
    }
    func setSourceVectors(pathVertices: [float2], pathVectors: [float2]) {
        _sourceVertices = pathVertices
        _sourceTangents = [float2].init(repeating: float2(0), count: pathVectors.count)
        // rotate each pathVector ninety deg. (so it is tangent), from this we can construct pipe vertices
        for i in 0..<pathVectors.count {
            _sourceTangents[i] = _ninetyDegreeRotMat * pathVectors[i]
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
    
    func createFixtures(_ onReservoir: UnsafeMutableRawPointer, bulbCenter: float2) {
        var b2LeftVertices = _leftVertices.map() { Vector2D(x:Float32($0.x - bulbCenter.x),y:Float32($0.y - bulbCenter.y))}
        var b2RightVertices = _rightVertices.map() { Vector2D(x:Float32($0.x - bulbCenter.x ),y:Float32($0.y - bulbCenter.y))}
        LiquidFun.makePipeFixture(onReservoir,
                                  leftVertices: &b2LeftVertices,
                                  rightVertices: &b2RightVertices,
                                  leftVertexCount: Int32(_leftVertices.count),
                                  rightVertexCount: Int32(_rightVertices.count))
    }
    func destroyFixtures(_ onReservoir: UnsafeMutableRawPointer) {
        LiquidFun.destroyPipeFixtures( onReservoir )
    }
}
