import MetalKit

enum FontRenderableTypes {
    case HoeflerDefault
    case NewGameText
    case MenuText
}
enum ButtonLabelTypes {
    case NewGameLabel
    case MenuLabel
    
    case None
}

class FontRenderables: Library<FontRenderableTypes, FontRenderable> {
    private static var fontRenderables : [FontRenderableTypes : FontRenderable] = [:]
    
    public static func Initialize( ) {
        createDefaultFonts()
    }
    
    private static func createDefaultFonts() {
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .HoeflerDefault)
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .NewGameText)
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .MenuText)
    }
    
    public static func Get(_ fontType : FontRenderableTypes) -> FontRenderable {
        return fontRenderables[fontType]!
    }
    
}

class ButtonLabels: Library<ButtonLabelTypes, TextObject> {
    private static let _buttonLabelOffsets: [ButtonLabelTypes:float2] = [.NewGameLabel:float2(x: -0.16, y: 0.06), .MenuLabel:float2(x: -0.09, y: 0.06)]

    private static var textObjects : [ButtonLabelTypes : TextObject] = [:]
    
    public static func Initialize( ) {
        createDefaultButtonLabels()
    }
    private static func createDefaultButtonLabels() {
        textObjects.updateValue(TextObject(.MenuText, "menu" ,_buttonLabelOffsets[.MenuLabel]), forKey: .MenuLabel)
        textObjects.updateValue(TextObject(.NewGameText, "new game" ,_buttonLabelOffsets[.NewGameLabel]), forKey: .NewGameLabel)
    }
    
    public static func Get(_ labelType : ButtonLabelTypes) -> TextObject {
        return textObjects[labelType]!
    }
}

