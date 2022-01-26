import MetalKit

enum TextureTypes {
    case BaseColorRender_0
    case BaseColorRender_1
    case BaseDepthRender
    
    case Snake
    case SnakeDead
    case Apple
    
    case Cloud0
    case Cloud1
    case Cloud2
    case Cloud3
    
    case Jug
    case Cruiser
    case TT3D
    case ttFlat
    
    case None // special, no texture at all, not even in library
}

class Textures {
    
    private static var _library: [TextureTypes: MTLTexture] = [:]
    
    public static func Initialize() {
        _library.updateValue(Texture("apple").texture, forKey: .Apple)
        _library.updateValue(Texture("snake").texture, forKey: .Snake)
        _library.updateValue(Texture("snakedead").texture, forKey: .SnakeDead)
        
        _library.updateValue(Texture("Cloud0").texture, forKey: .Cloud0)
        
        _library.updateValue(Texture("Jug").texture, forKey: .Jug)
        _library.updateValue(Texture("cruiser",ext: "bmp").texture, forKey: .Cruiser)
        _library.updateValue(Texture("testflat", ext: "png").texture, forKey: .ttFlat)
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
