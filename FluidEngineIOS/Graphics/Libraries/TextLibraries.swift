import MetalKit

enum FontRenderableTypes {
    case HoeflerDefault
    case NewGameText
    case MenuText
    case StartGameText
    case TestText1
    case DevText
    
    case TubePouring
    
    case GenericInfoMessage
    case AdviseInfoMessage
    case BadInfoMessage
    case GoodInfoMessage
    
    // Alien gamemode
    case HumanStateLabel
    
    case LevelTime
    case LevelScore
}
enum TextLabelTypes {
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
    
    case LevelTimeLabel
    case LevelScoreLabel
    
    case CleanDescription
    
    // Alien gamemode
    case WeaponSelectText
    
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
        
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .GoodInfoMessage  )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .BadInfoMessage  )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .AdviseInfoMessage  )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .GenericInfoMessage  )

        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .LevelTime  )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .LevelScore  )
        fontRenderables.updateValue(FontRenderable(device: Engine.Device), forKey: .HumanStateLabel  )
    }
    
    public static func Get(_ fontType : FontRenderableTypes) -> FontRenderable {
        return fontRenderables[fontType]!
    }
}

class TextLabels: Library<TextLabelTypes, TextObject> {

    private static var textObjects : [TextLabelTypes : TextObject] = [:]
    
    public static func Initialize( ) {
        createDefaultButtonLabels()
    }
    private static func createDefaultButtonLabels() {
        textObjects.updateValue(TextObject(.MenuText, "menu" ), forKey: .MenuLabel)
        textObjects.updateValue(TextObject(.NewGameText, "tube lab"), forKey: .NewGameLabel)
        textObjects.updateValue(TextObject(.StartGameText, "start"), forKey: .StartGameLabel)
        textObjects.updateValue(TextObject(.TestText1, "test #1"), forKey: .TestLabel1)
        textObjects.updateValue(TextObject(.TestText1, "clean bugs"), forKey: .TestLabel2)
        textObjects.updateValue(TextObject(.TestText1, "test3"), forKey: .TestLabel3)
        textObjects.updateValue(TextObject(.DevText, "developer" ), forKey: .DevSceneLabel)
        
        textObjects.updateValue(TextObject(.BadInfoMessage, "this tube is pouring!" ), forKey: .TubePouringLabel)
        textObjects.updateValue(TextObject(.BadInfoMessage, "top colors not matching" ), forKey:  .TubeRejectLabel)
        textObjects.updateValue(TextObject(.GoodInfoMessage, "this tube is complete!" ), forKey:    .TubeDoneLabel)
        textObjects.updateValue(TextObject(.BadInfoMessage, "this tube is full!" ), forKey:    .TubeFullLabel)
        textObjects.updateValue(TextObject(.BadInfoMessage, "this tube is filling" ), forKey: .TubeFillingLabel)
        
        textObjects.updateValue(TextObject(.GenericInfoMessage, "Clean bugs refills all the tubes to the current game state. \n Use this button when something looks off." ), forKey: .CleanDescription)
        
        // Alien gamemode
        textObjects.updateValue(TextObject(.HumanStateLabel, "select your starting gun"), forKey:  .WeaponSelectText)

        textObjects.updateValue(TextObject(.LevelTime, "time: 0"), forKey: .LevelTimeLabel)
        textObjects.updateValue(TextObject(.LevelScore, "score: 0"), forKey:  .LevelScoreLabel)
    }
    
    public static func Get(_ labelType : TextLabelTypes) -> TextObject {
        return textObjects[labelType]!
    }
}

