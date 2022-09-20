import MetalKit

class GameObject: Node {
    var renderPipelineStateType: RenderPipelineStateTypes = .Custom 
    var modelConstants = ModelConstants()
    var mesh: Mesh!
    var texture: MTLTexture!
    var material = CustomMaterial()
    
    init(_ meshType: MeshTypes ) {
        super.init()
        self.mesh = MeshLibrary.Get(meshType)
    }
    
    func setTexture(_ texture: TextureTypes){
        self.texture = Textures.Get(texture)
        self.material.useTexture = true
    }
    
    override func update() {
        modelConstants.modelMatrix = modelMatrix
        super.update()
    }
    
    func getBoxVertices( _ scale: Float ) -> [Vector2D] {
        mesh.getBoxVertices( scale )
    }
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
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

class ColorGameObject: Node {

    var modelConstants = ModelConstants()
    var mesh: Mesh!
    var texture: MTLTexture!
    
    public var material : CustomMaterial = CustomMaterial()

    
    override init() {
        super.init()
    }
    
    private func updateModelConstants(){
        modelConstants.modelMatrix = self.modelMatrix
    }
    
    override func update() {
        updateModelConstants()
        super.update()
    }
    
}

extension ColorGameObject : Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        //renderCommandEncoder.setTriangleFillMode(.lines)
        // Send info to render command encoder
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        // Vertex
        renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
        //Fragment
        renderCommandEncoder.setFragmentBytes(&material, length : CustomMaterial.stride, index : 1)
        mesh.drawPrimitives(renderCommandEncoder)
    }
}

