import MetalKit

class MBETextMesh: Mesh {
    
    private var _vertexBuffer: MTLBuffer!
    private var _indexBUffer: MTLBuffer!
    
    init(_ withString: String, inRect:CGRect, fontAtlas: MBEFontAtlas, atSize: CGFloat) {
        super.init()
        
    }
    
    func buildMeshWithString(string: String, inRect: CGRect, fontAtlas: MBEFontAtlas, atSize: CGFloat) {
        let font = fontAtlas.parentFont
        let attributes = [NSAttributedString.Key.font: font]
        let attrString = NSAttributedString.init(string: string, attributes: attributes)
        let stringRange = CFRangeMake( 0, attrString.length )
        let rectPath = CGPath(rect: inRect, transform: nil)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        
    }
    
}
