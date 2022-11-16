import MetalKit

enum TextureTypes {
    case BaseColorRender_0
    case BaseColorRender_1
    case BaseDepthRender

    case Cloud0
    case Cloud1
    case Cloud2
    case Cloud3
    
    case TestTube
    
    case ClearButton
    case TestButton
    case Cliff
    case PineTree
    case Menu
    case BeachButton
    case Sand
    
    case Reservoir
    case Bulb
    
    case Missing
    case None // special, no texture at all, not even in library
    
    //floating button Quad textures
    case EditTexture
    case ControlPointsTexture
    case ConstructPipesTexture
    case MoveObjectTexture
    case PipeTexture
    case BigValveTexture
    case SmallValveTexture
    
    case ReservoirSnapShot
    
    case AlienTexture
    case AsteroidTexture
}

class Textures {
    
    private static var _library: [TextureTypes: MTLTexture] = [:]
    
    public static func Initialize() {
        _library.updateValue(Texture("Cloud0").texture, forKey: .Cloud0)
        _library.updateValue(Texture("cloud1").texture, forKey: .Cloud1)
        _library.updateValue(Texture("cloud2").texture, forKey: .Cloud2)
        _library.updateValue(Texture("cloud3").texture, forKey: .Cloud3)

        _library.updateValue(Texture("testFlat", ext: "png").texture, forKey: .TestTube)
        
        _library.updateValue(Texture("clearButton", ext: "png").texture, forKey: .ClearButton)
        _library.updateValue(Texture("testButton", ext: "png").texture, forKey: .TestButton)
        _library.updateValue(Texture("cliff", ext: "png").texture, forKey: .Cliff)
        _library.updateValue(Texture("menuButton", ext: "png").texture, forKey: .Menu)
        _library.updateValue(Texture("beachButton", ext: "png").texture, forKey: .BeachButton)

        _library.updateValue(Texture("beach", ext: "png").texture, forKey: .Sand)

        _library.updateValue(Texture("pineTree", ext: "png").texture, forKey: .PineTree)
        _library.updateValue(Texture("reservoir", ext: "png").texture, forKey: .Reservoir)
        _library.updateValue(Texture("bulbMesh", ext: "png").texture, forKey: .Bulb)
        _library.updateValue(Texture("missingTexture", ext: "png").texture, forKey: .Missing)
        _library.updateValue(Texture("editTexture", ext: "png").texture, forKey: .EditTexture)
        _library.updateValue(Texture("controlPoints", ext: "png").texture, forKey: .ControlPointsTexture)
        _library.updateValue(Texture("constructPipe", ext: "png").texture, forKey: .ConstructPipesTexture)
        _library.updateValue(Texture("pipeTexture", ext: "png").texture, forKey: .PipeTexture)
        _library.updateValue(Texture("moveTexture", ext: "png").texture, forKey: .MoveObjectTexture)
        _library.updateValue(Texture("bigValve", ext: "png").texture, forKey: .BigValveTexture)
        _library.updateValue(Texture("smallValve", ext: "png").texture, forKey: .SmallValveTexture)
        
        _library.updateValue(Texture("Alien", ext: "png").texture, forKey: .AlienTexture)
        _library.updateValue(Texture("Asteroid", ext: "png").texture, forKey: .AsteroidTexture)

    }
    
    public static func Get(_ type: TextureTypes)->MTLTexture {
        return _library[type]!
    }
    
    public static func Set(textureType: TextureTypes, texture: MTLTexture ) {
        _library.updateValue(texture, forKey: textureType)
    }
    
}

class Texture: sizeable {
    var texture: MTLTexture!
    
    init(_ textureName: String, ext: String = "png", origin: MTKTextureLoader.Origin = .topLeft){
        let textureLoader = TextureLoader(textureName: textureName, textureExtension: ext, origin: origin)
        let texture: MTLTexture = textureLoader.loadTextureFromBundle()
        setTexture(texture)
    }
    
    func setTexture(_ texture: MTLTexture){
        self.texture = texture
    }
}
