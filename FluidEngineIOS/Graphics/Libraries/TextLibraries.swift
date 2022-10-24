import MetalKit

enum FontRenderableTypes {
    case HoeflerDefault
    case NewGameText
    case MenuText
    case TestText
}
enum ButtonLabelTypes {
    case NewGameLabel
    case MenuLabel
    case TestLabel
    
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
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .TestText)
    }
    
    public static func Get(_ fontType : FontRenderableTypes) -> FontRenderable {
        return fontRenderables[fontType]!
    }
    
}

class ButtonLabels: Library<ButtonLabelTypes, TextObject> {

    private static var textObjects : [ButtonLabelTypes : TextObject] = [:]
    
    public static func Initialize( ) {
        createDefaultButtonLabels()
    }
    private static func createDefaultButtonLabels() {
        textObjects.updateValue(TextObject(.MenuText, "menu" ), forKey: .MenuLabel)
        textObjects.updateValue(TextObject(.NewGameText, "new game"), forKey: .NewGameLabel)
        textObjects.updateValue(TextObject(.TestText, "test action"), forKey: .TestLabel)
    }
    
    public static func Get(_ labelType : ButtonLabelTypes) -> TextObject {
        return textObjects[labelType]!
    }
}

