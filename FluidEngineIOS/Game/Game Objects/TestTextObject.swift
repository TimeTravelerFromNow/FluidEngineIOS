import MetalKit
import CoreText

class TestTextObject: Node {
    
    private var _texture: MTLTexture!
    private var _vertexBuffer: MTLBuffer!
    private var _indexBuffer: MTLBuffer!
    
    private var _indexCount: Int!
    private var modelConstants = ModelConstants()
    
    private var _fontType: FontRenderableTypes!
    var currentText: String!
    private var _fontRenderable: FontRenderable!
    
    init(_ fontType: FontRenderableTypes){
        super.init()
        _fontType = fontType
        _fontRenderable = FontRenderables.Get(_fontType)
        currentText = _fontRenderable.getText()
        refreshBuffers()
    }
    
    func setText(_ text: String) {
        currentText = text
        _fontRenderable.setText(text)
        refreshBuffers()
    }
    func getText() -> String {
        if (_fontRenderable.getText() != currentText) { print("Text Object WARNING::Objective C text doesn't match swift class text")} //shouldnt
        return currentText
    }
    
    private func refreshBuffers() {
        _texture = _fontRenderable.getTexture()
        _vertexBuffer = _fontRenderable.getVertices()
        _indexBuffer = _fontRenderable.getIndices()
        _indexCount = _fontRenderable.getIndexCount()
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

