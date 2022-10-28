import MetalKit

class Renderer: NSObject {
    
    public static var ScreenSize = float2(0,0)
    public static var Bounds = float2(0,0)

    public static var AspectRatio: Float { return ScreenSize.x / ScreenSize.y }
    
    private var _baseRenderPassDescriptor: MTLRenderPassDescriptor!

    init(_ mtkView: MTKView) {
        super.init()
        
        updateScreenSize(view: mtkView)
        
        SceneManager.Initialize(.Dev)
        
        setupBaseRenderPass()

    }
    
}

extension Renderer: MTKViewDelegate{
    
    func baseRenderPass(commandBuffer: MTLCommandBuffer) {
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: _baseRenderPassDescriptor)
        renderCommandEncoder?.label = "Base Render Command Encoder"
        renderCommandEncoder?.pushDebugGroup("Starting Base Render")
        SceneManager.render( renderCommandEncoder!)
        renderCommandEncoder?.popDebugGroup()
        renderCommandEncoder?.endEncoding()
    }
    
    func finalRenderPass(view: MTKView, commandBuffer: MTLCommandBuffer) {
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)
        renderCommandEncoder?.label = "Final Render Command Encoder"
        renderCommandEncoder?.pushDebugGroup("Starting Final Render")

        renderCommandEncoder?.setRenderPipelineState(RenderPipelineStates.Get(.Final))
        renderCommandEncoder?.setFragmentTexture(Textures.Get(.BaseColorRender_0), index: 0)
        MeshLibrary.Get(.Quad).drawPrimitives(renderCommandEncoder!)

        renderCommandEncoder?.popDebugGroup()
        renderCommandEncoder?.endEncoding()
    }
    
    func draw(in view: MTKView) {
        GameTime.UpdateTime( 1 / Float(view.preferredFramesPerSecond))
        SceneManager.update(GameTime.DeltaTime)
        
        let commandBuffer = Engine.CommandQueue.makeCommandBuffer()
        commandBuffer?.label = "Base Command Buffer"

        baseRenderPass(commandBuffer: commandBuffer!)

        finalRenderPass(view: view, commandBuffer: commandBuffer!)
        
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.preferredFramesPerSecond = GameSettings.FPS // used to scale physical behavior timescale
        updateScreenSize(view: view)
    }
    
    public func updateScreenSize(view: MTKView){
        Renderer.ScreenSize = float2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        Renderer.Bounds  = float2(Float(view.bounds.width), Float(view.bounds.height))
        print("SCreensize : \(Renderer.ScreenSize)")
        SceneManager.currentScene?.sceneSizeWillChange()
    }
    
    func setupBaseRenderPass(){
        let baseTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.MainPixelFormat,
                                                                             width: Int(Renderer.ScreenSize.x),
                                                                             height: Int(Renderer.ScreenSize.y),
                                                                             mipmapped: false)
        baseTextureDescriptor.usage = [.renderTarget, .shaderRead]
        baseTextureDescriptor.storageMode = .private
        Textures.Set(textureType: .BaseColorRender_0,
                     texture: Engine.Device.makeTexture(descriptor: baseTextureDescriptor)!)
        // ---- BASE COLOR 1 TEXTURE ----
        let base1TextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.MainPixelFormat,
                                                                             width: Int(Renderer.ScreenSize.x),
                                                                             height: Int(Renderer.ScreenSize.y),
                                                                             mipmapped: false)
        base1TextureDescriptor.usage = [.renderTarget, .shaderRead]
        Textures.Set(textureType: .BaseColorRender_1,
                                   texture: Engine.Device.makeTexture(descriptor: base1TextureDescriptor)!)
        base1TextureDescriptor.storageMode = .private
        // base depth
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.MainDepthPixelFormat,
                                                                              width: Int(Renderer.ScreenSize.x),
                                                                              height: Int(Renderer.ScreenSize.y),
                                                                              mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget]
        depthTextureDescriptor.storageMode = .private
        Textures.Set(textureType: .BaseDepthRender, texture: Engine.Device.makeTexture(descriptor: depthTextureDescriptor)!)
        self._baseRenderPassDescriptor = MTLRenderPassDescriptor()
        self._baseRenderPassDescriptor.colorAttachments[0].texture = Textures.Get(.BaseColorRender_0)
        self._baseRenderPassDescriptor.colorAttachments[0].storeAction = .store
        self._baseRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        self._baseRenderPassDescriptor.colorAttachments[1].texture = Textures.Get(.BaseColorRender_1)
        self._baseRenderPassDescriptor.colorAttachments[1].storeAction = .store
        self._baseRenderPassDescriptor.colorAttachments[1].loadAction = .clear
        
        self._baseRenderPassDescriptor.depthAttachment.texture = Textures.Get(.BaseDepthRender)
        self._baseRenderPassDescriptor.depthAttachment.storeAction = .store
        self._baseRenderPassDescriptor.depthAttachment.loadAction = .clear
    }

}
