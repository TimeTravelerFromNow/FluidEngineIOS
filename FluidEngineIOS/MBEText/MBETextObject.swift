import MetalKit

class MBETextObject: Node {
    
    var _textMesh: MBETextMesh!
    
    init(_ withString: String, inRect: CGRect, fontAtlas: MBEFontAtlas, atSize: CGFloat) {
        _textMesh = MBETextMesh(withString, inRect: inRect, fontAtlas: fontAtlas, atSize: atSize)
    }
    
}

extension MBETextObject: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Text))
        _textMesh.doRender(renderCommandEncoder)
    }
}
