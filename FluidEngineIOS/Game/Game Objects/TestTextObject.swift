import MetalKit

class TestTextObject: Node {
    
    private var _texture: MTLTexture!
    private var _vertexBuffer: MTLBuffer!
    private var _indexBuffer: MTLBuffer!
    
    private var _indexCount: Int!
    private var modelConstants = ModelConstants()
    
    init(_ fontType: FontRenderableTypes){
        let fontRenderable = FontRenderables.Get(fontType)
        _texture = fontRenderable.getTexture()
        _vertexBuffer = fontRenderable.getVertices()
        _indexBuffer = fontRenderable.getIndices()
        _indexCount = fontRenderable.getIndexCount()
    }
    
    override func update() {
        modelConstants.modelMatrix = modelMatrix
        super.update()
    }
    
}

extension TestTextObject: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Text))
        renderCommandEncoder.setVertexBuffer(_vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        renderCommandEncoder.setFragmentTexture(_texture, index: 0)
        renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: _indexCount, indexType: .uint16, indexBuffer: _indexBuffer, indexBufferOffset: 0)
    }
}

