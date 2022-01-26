import MetalKit

class GameView: MTKView {
                
    var renderer : Renderer!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        Engine.Ignite(device!)
        
        self.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)
        
        self.colorPixelFormat = Preferences.MainPixelFormat
            
        self.renderer = Renderer(self)
                
        self.framebufferOnly = false // needed for blit encoding

        self.delegate = renderer
        
    }

}
