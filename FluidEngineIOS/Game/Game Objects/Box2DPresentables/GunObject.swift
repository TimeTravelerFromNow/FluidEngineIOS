class GunObject: Friendly {
    
    let origin: float2!
    
    var circleMesh: Mesh!
    let circleTexture: TextureTypes = .MountTexture
    var circleModelConstants = ModelConstants()
    
    let mountRadius: Float = 0.1
    
    init(center: float2, scale: Float) {
        self.origin = center
        super.init(center: center, scale: scale, .Barrel, density: 60.0, restitution: 0.7)
    }
    
    override func setShape() {
        self.setAsPolygonShape()
        
        let radius: Float = mountRadius / scale
        LiquidFun.addFriendlyCircle(self.getFriendlyRef, radius: radius)
        
        circleMesh = MeshLibrary.Get(.Quad)
        setTexture( .MountTexture )
        useCustomTexture = true
        setScale( radius * GameSettings.stmRatio )
        updateModelConstants()
    }
    
    override func updateModelConstants() {
        self.setScale( GameSettings.stmRatio / scale )
        super.updateModelConstants()
        setScale( mountRadius * GameSettings.stmRatio )
        circleModelConstants.modelMatrix = modelMatrix
    }
    
    override func render( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        updateModelConstants()
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(renderPipelineStateType))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        
        renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)
        renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1 )
      
        
        renderCommandEncoder.setVertexBytes(&circleModelConstants, length: ModelConstants.stride, index: 2)
        circleMesh.drawPrimitives( renderCommandEncoder, baseColorTextureType: circleTexture )
        renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        if(!material.useMaterialColor) {
            renderCommandEncoder.setFragmentTexture(texture, index: 0)
        }
        mesh.drawPrimitives( renderCommandEncoder )
        
        
    }
}
