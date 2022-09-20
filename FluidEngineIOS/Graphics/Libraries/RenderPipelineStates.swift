
import MetalKit

enum RenderPipelineStateTypes {
    case Final
    case Instanced
    case Basic // Like instanced, will render .obj with texture, but not instanced.
    
    case Custom
    case ColorFluid
    case ColorBG
    
    case Points
    case Lines
    case Select
}

enum VertexDescriptorTypes {
    case Basic
    case Custom
}

class RenderPipelineStates {
    
    private static var _library: [RenderPipelineStateTypes: MTLRenderPipelineState] = [:]
    private static var _descriptorLibrary: [VertexDescriptorTypes: MTLVertexDescriptor] = [:]
    
    private static var VertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        var offset: Int = 0
        //Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        offset += float3.size
        //Color
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = offset
        offset += float4.size
        //Texture Coordinate
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = offset
        offset += float3.size // use float3 because of padding
        //Normal
        vertexDescriptor.attributes[3].format = .float3
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[3].offset = offset
        offset += float3.size
        //Tangent
        vertexDescriptor.attributes[4].format = .float3
        vertexDescriptor.attributes[4].bufferIndex = 0
        vertexDescriptor.attributes[4].offset = offset
        offset += float3.size
        //Bitangent
        vertexDescriptor.attributes[5].format = .float3
        vertexDescriptor.attributes[5].bufferIndex = 0
        vertexDescriptor.attributes[5].offset = offset
        offset += float3.size
        vertexDescriptor.layouts[0].stride = Vertex.stride
        return vertexDescriptor
    }
    private static var CustomVertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        var offset: Int = 0
        //Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        offset += float3.size
        //Color
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = offset
        offset += float4.size
        //Texture Coordinate
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = offset
        vertexDescriptor.layouts[0].stride = CustomVertex.stride
        return vertexDescriptor
    }
    public static func Initialize() {
        generateSelectRenderPipelineState()
        generateInstancedRenderPipelineState()
        generatePointsRenderPipelineState()
        generateLinesRenderPipelineState()
        
        CustomPipelineState()
        generateColorFluidRenderPipelineState()
        generateFinalRenderPipelineState()
        CustomBGPipelineState()
        generateBasicRenderPipelineState()
        
        _descriptorLibrary.updateValue(VertexDescriptor, forKey: .Basic)
        _descriptorLibrary.updateValue(CustomVertexDescriptor, forKey: .Custom)
    }
    private static func generateColorFluidRenderPipelineState() {
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "color_fluid_vertex")
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "color_fluid_fragment")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = Preferences.MainPixelFormat

        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat
        
        renderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .ColorFluid)    }
    
    private static func generatePointsRenderPipelineState() {
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "draw_vertex")
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "draw_fragment")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = Preferences.MainPixelFormat

        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat

        renderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .Points)    }
    
    private static func generateLinesRenderPipelineState() {
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "draw_vertex")
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "draw_fragment")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = Preferences.MainPixelFormat

        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat

        renderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .Lines)    }
    
    private static func generateInstancedRenderPipelineState() {
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "instanced_vertex_shader")
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "basic_fragment_shader")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = Preferences.MainPixelFormat
        
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat

        renderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .Instanced)
    } // multiple textures gave unused resource error, see 2etime discord discussion about clouds
    private static func generateSelectRenderPipelineState() {
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "instanced_vertex_shader")
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "select_fragment_shader")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = Preferences.MainPixelFormat
        
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat

        renderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .Select)
    }
    private static func CustomPipelineState() {
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "basic_color_vertex_shader")
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "color_fragment_shader")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = Preferences.MainPixelFormat

        renderPipelineDescriptor.depthAttachmentPixelFormat =  Preferences.MainDepthPixelFormat

        renderPipelineDescriptor.vertexDescriptor = CustomVertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .Custom)
    }
    private static func CustomBGPipelineState() {
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "basic_color_vertex_shader")
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "bg_color_fragment")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = Preferences.MainPixelFormat

        renderPipelineDescriptor.depthAttachmentPixelFormat =  Preferences.MainDepthPixelFormat

        renderPipelineDescriptor.vertexDescriptor = CustomVertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .ColorBG)
    }
    
    private static func generateFinalRenderPipelineState() {
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "final_vertex_shader") // final vertex
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "final_fragment_shader")         // final fragment
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat

        renderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .Final)
    }
    
    private static func generateBasicRenderPipelineState() { // non instanced – for objs
        let vertexFunction = Engine.DefaultLibrary.makeFunction(name: "basic_color_vertex_shader")
        let fragmentFunction = Engine.DefaultLibrary.makeFunction(name: "basic_fragment_shader")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = Preferences.MainPixelFormat

        renderPipelineDescriptor.depthAttachmentPixelFormat =  Preferences.MainDepthPixelFormat

        renderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        var renderPipelineState: MTLRenderPipelineState!
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("ERROR::RENDERPIPELINESTATE::\(error)")
        }
        
        _library.updateValue(renderPipelineState, forKey: .Basic)
    }
    
    public static func Get(_ type: RenderPipelineStateTypes)->MTLRenderPipelineState {
        return _library[type]!
    }
    
    public static func GetDescriptor(_ type: VertexDescriptorTypes)->MTLVertexDescriptor {
        return _descriptorLibrary[type]!
    }
    
}
