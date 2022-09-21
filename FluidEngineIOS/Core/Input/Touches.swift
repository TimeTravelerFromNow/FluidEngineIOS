import MetalKit

class Touches {

    private static var MAX_TOUCHES_COUNT = 10
    private static var touchList = [Bool].init(repeating: false, count: MAX_TOUCHES_COUNT)
    private static var touchIndex = 0
    
    private static var lastTouchPosition = float2(0,0)

    public static var IsDragging: Bool { return touchList[ touchIndex ] }
    
    public static func startTouch() {
        if touchIndex < MAX_TOUCHES_COUNT - 1 {
            touchIndex += 1
            touchList[ touchIndex ] = true
        }
    }

    public static func endTouch() {
        if touchIndex > 1 {
            touchIndex -= 1
            touchList[ touchIndex ] = false
        }
    }
    public static func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, _ view: MTKView) {
        if let loc = touches.first?.location(in: view) {
            lastTouchPosition.x = Float(loc.x)
            lastTouchPosition.y = Float(loc.y)
            startTouch()
        }
        print("screensize: \(Renderer.ScreenSize)")
        print("view bounds: \(view.bounds)")
    }
    
    public static func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch()
    }
    
    public static func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, _ view: MTKView) {
        if let loc = touches.first?.location(in: view) {
            lastTouchPosition.x = Float(loc.x)
            lastTouchPosition.y = Float(loc.y)
        }
        print(lastTouchPosition)
    }
    
    //Returns the touch position in screen-view coordinates [-1, 1], independent of camera zoom
    public static func GetTouchViewportPosition()->float2 {
        let x = (lastTouchPosition.x - Renderer.Bounds.x * 0.5) / (Renderer.Bounds.x * 0.5)
        let y = (-lastTouchPosition.y +  Renderer.Bounds.y * 0.5) / (Renderer.Bounds.y * 0.5)
        return float2(x, y)
    }
    
    public static func GetBoxPos()->float2 {
        var normalizedPosition = GetTouchViewportPosition()
        normalizedPosition.x *= SceneManager.currentScene.currentCamera.aspect
        var boxPosition = normalizedPosition * 5.0 // MARK: needs fixing still
        let cameraOffset = float2(x: SceneManager.currentScene.currentCamera.getPositionX(),
                                  y: SceneManager.currentScene.currentCamera.getPositionY())
        boxPosition += cameraOffset * 5.0
        return boxPosition
    }
}
