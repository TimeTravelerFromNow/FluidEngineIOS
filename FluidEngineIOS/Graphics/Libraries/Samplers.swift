

import MetalKit

enum SamplerStateTypes {
    case None
    case Linear
}

class SamplerStates {
    
    private static var _library: [SamplerStateTypes : SamplerState] = [:]
    
    public static func Initialize() {
        _library.updateValue(Linear_SamplerState(), forKey: .Linear)
    }
    
    public static func Get(_ type: SamplerStateTypes) -> MTLSamplerState {
        return (_library[type]?.samplerState!)!
    }
    
}

class SamplerState {
    var name: String
    var samplerState: MTLSamplerState!
    init() {
        name = "None"
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.label = name
        samplerState = Engine.Device.makeSamplerState(descriptor: samplerDescriptor)
    }
}

class Linear_SamplerState: SamplerState {
    
    override init() {
        super.init()
        let name = "Linear Sampler State"
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.label = name
        self.name = name
        self.samplerState = Engine.Device.makeSamplerState(descriptor: samplerDescriptor)
    }
}
