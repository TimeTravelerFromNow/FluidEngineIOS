import MetalKit

class GameSettings {
    public static var FPS: Int = 60
    // physics
    public static var ptmRatio: Float = 200
    public static var particleRadius: Float = 9
    public static var BoxDimensions = float2( Renderer.ScreenSize.x / ptmRatio, Renderer.ScreenSize.y / ptmRatio )
    public static var DampingStrength: Float = 0.2 // 0.2 originally
    public static var Density: Float = 1.2  // 1.2 originally
    
    public static var stmRatio: Float { return 0.2 } //experimentally determined  0.188 / 189
    public static var AspectRatio: Float { return Renderer.ScreenSize.x / Renderer.ScreenSize.y }
    public static var MaxParticles: Int32 = 10000
}
