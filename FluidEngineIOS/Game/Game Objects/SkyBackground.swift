import MetalKit

class SkyBackground: Node {
    var modelConstants = ModelConstants()
    var cmesh: CustomMesh!
    var material = CustomMaterial()
    
    init(_ meshType: CustomMeshTypes ) {
        super.init()
        self.cmesh = CustomMeshes.Get(meshType)
    }
    
    override func update() {
        modelConstants.modelMatrix = modelMatrix
        super.update()
    }
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.ColorBG))
        var totalGameTime: Float = 0.1

        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.ColorBG))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        
        renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
       //fragment
        renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)
        renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1 )
        renderCommandEncoder.setFragmentBytes(&totalGameTime, length: Float.size, index: 0)

        cmesh.drawPrimitives(renderCommandEncoder)
    }
}
