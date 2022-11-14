import MetalKit

enum FontRenderableTypes {
    case HoeflerDefault
    case NewGameText
    case MenuText
    case StartGameText
    case TestText1
    case DevText
    
    case TubePouring
    case TubeReject
    case TubeDone
    case TubeFull
    case TubeFilling
}
enum ButtonLabelTypes {
    case NewGameLabel
    case MenuLabel
    
    case StartGameLabel
    case TestLabel1
    case TestLabel2
    case TestLabel3
    case DevSceneLabel
    
    case TubePouringLabel
    case TubeRejectLabel
    case TubeDoneLabel
    case TubeFullLabel
    case TubeFillingLabel
    
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
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .StartGameText)
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .TestText1)
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .DevText)
        
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .TubePouring  )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .TubeReject  )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .TubeDone  )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .TubeFull )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .TubeFilling  )
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
        textObjects.updateValue(TextObject(.StartGameText, "start"), forKey: .StartGameLabel)
        textObjects.updateValue(TextObject(.TestText1, "open \n valve 0"), forKey: .TestLabel1)
        textObjects.updateValue(TextObject(.TestText1, "autofill \n action"), forKey: .TestLabel2)
        textObjects.updateValue(TextObject(.TestText1, "test3"), forKey: .TestLabel3)
                
        textObjects.updateValue(TextObject(.TubePouring, "this tube is pouring!" ), forKey: .TubePouringLabel)
        textObjects.updateValue(TextObject(.TubeReject , "top colors not matching" ), forKey:  .TubeRejectLabel)
        textObjects.updateValue(TextObject(.TubeDone   , "this tube is complete!" ), forKey:    .TubeDoneLabel)
        textObjects.updateValue(TextObject(.TubeFull   , "this tube is full!" ), forKey:    .TubeFullLabel)
        textObjects.updateValue(TextObject(.TubeFilling, "this tube is filling" ), forKey: .TubeFillingLabel)
        
        textObjects.updateValue(TextObject(.DevText, "developer"), forKey: .DevSceneLabel)
    }
    
    public static func Get(_ labelType : ButtonLabelTypes) -> TextObject {
        return textObjects[labelType]!
    }
}

