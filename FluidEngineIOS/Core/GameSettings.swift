import MetalKit

class GameSettings {
    
    private static var _gridSize: float2 = float2(41, 41)
    
    public static var GridSize: float2 { return _gridSize }
    public static var GridCellsWide: Float { return _gridSize.x }
    public static var GridCellsHigh: Float { return _gridSize.y }
    public static var GridLinesWidth: Float = 0.05
    
    public static var SnakeSpeed: Float = 10.0
    public static var Score: Int = 0
    public static var GameOver: Bool = false
    
    public static var FPS: Int = 60
    public static var TimeScale: Float { return Float(FPS) / 60 }
    // physics
    public static var ptmRatio: Float = 200
    public static var particleRadius: Float = 10
    public static var BoxDimensions = float2( Renderer.ScreenSize.x / ptmRatio, Renderer.ScreenSize.y / ptmRatio )
    public static var DampingStrength: Float = 0.2// 0.2 originally
    public static var Density: Float = 1.2  // 1.2 originally
  
    public static var GroupScaleY: Float = 4.0
    public static var GroupScaleX: Float = 1.0
    public static var DropHeight: Float = 1.5
    public static var CapPlaceDelay: Float = 0.53
    public static var PourSpeed: Float =  4.0
    
    public static var stmRatio: Float { return ptmRatio * 0.001 } //experimentally determined  0.188 / 189
    public static var AspectRatio: Float { return Renderer.ScreenSize.x / Renderer.ScreenSize.y }
    public static var MaxParticles: Int32 = 10000
}
