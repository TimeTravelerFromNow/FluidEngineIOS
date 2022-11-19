import MetalKit

class Alien: GameObject {

    private var _alienRef: UnsafeMutableRawPointer!
    var getAlienRef: UnsafeMutableRawPointer! { return _alienRef }
    var boxVertices: [Vector2D]!
    
    init(center: float2, scale: Float = 1.0, _ meshType: MeshTypes, _ texture: TextureTypes, density: Float) {
        super.init(meshType)
        setTexture(texture)
        renderPipelineStateType = .Basic
        boxVertices = getBoxVertices(scale)
        let polygonVerticesCount = boxVertices.count
        self.setPositionZ(0.11)
        self.setScale( GameSettings.stmRatio / scale )
        
        _alienRef = LiquidFun.makeAlien(Vector2D(x:center.x,y:center.y),
                                        vertices: &boxVertices,
                                        vertexCount: polygonVerticesCount,
                                        density: density,
                                        health: 1.0,
                                        crashDamage: 0.1,
                                        categoryBits: 0x0001,
                                        maskBits: 0x0001,
                                        groupIndex: 0)
        updateModelConstants()
    }
    
    
    func updateModelConstants() {
        setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        setRotationZ( getRotationZ() )
        modelConstants.modelMatrix = modelMatrix
    }
    
    func getBoxPositionX() -> Float {
        return Float(LiquidFun.getAlienPosition(_alienRef).x)
    }
    func getBoxPositionY() -> Float {
        return Float(LiquidFun.getAlienPosition(_alienRef).y)
    }
    override func getRotationZ() -> Float {
        return LiquidFun.getAlienRotation(_alienRef)
    }
    func getBoxPosition() -> float2 {
        let boxPos = LiquidFun.getAlienPosition(_alienRef)
        return float2(x: boxPos.x, y: boxPos.y)
    }
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        updateModelConstants()
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(renderPipelineStateType))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        
        renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)
        renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1 )
        if(!material.useMaterialColor) {
                   renderCommandEncoder.setFragmentTexture(texture, index: 0)
        }
        mesh.drawPrimitives(renderCommandEncoder)
        super.render(renderCommandEncoder)
    }
}
