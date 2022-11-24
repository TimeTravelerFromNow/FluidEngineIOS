import MetalKit

class Alien: GameObject {

    private var _alienRef: UnsafeMutableRawPointer!
    var getAlienRef: UnsafeMutableRawPointer! { return _alienRef }
    var boxVertices: [float2]!
    
    init(center: float2, scale: Float = 1.0, _ meshType: MeshTypes, _ texture: TextureTypes, density: Float, health: Float = 1.0) {
        self.health = health
        super.init(meshType)
        setTexture(texture)
        renderPipelineStateType = .Basic
        boxVertices = getBoxVertices(scale)
        let polygonVerticesCount = boxVertices.count
        self.setPositionZ(0.11)
        self.setScale( GameSettings.stmRatio / scale )
      
        updateModelConstants()
    }
    
    var health: Float!
    
    func updateHealth() {
        health = 0
    }
    
    func updateModelConstants() {
        setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        setRotationZ( getRotationZ() )
        modelConstants.modelMatrix = modelMatrix
    }
    
    func getBoxPositionX() -> Float {
        return 0
    }
    func getBoxPositionY() -> Float {
        return 0
    }
    override func getRotationZ() -> Float {
        return 0
    }
    func getBoxPosition() -> float2 {
      
        return float2(0)
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
