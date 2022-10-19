import MetalKit

enum FontRenderableTypes {
    case HoeflerDefault
}

class FontRenderables: Library<FontRenderableTypes, FontRenderable> {
    private static var fontRenderables : [FontRenderableTypes : FontRenderable] = [:]
    
    public static func Initialize( ) {
        createDefaultFonts()
    }
    
    private static func createDefaultFonts() {
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .HoeflerDefault)
    }
    
    public static func Get(_ fontType : FontRenderableTypes) -> FontRenderable {
        return fontRenderables[fontType]!
    }
    
}
