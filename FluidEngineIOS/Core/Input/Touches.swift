//import MetalKit
//
//class Mouse {
//    
//    private static var firstTouchPosition = float2(0,0)
//    private static var positionDelta = float2(0,0)
//    
//    public static func setTouch(button: Int, isOn: Bool){
//        
//    }
//    
//    public static func IsMouseButtonPressed(button: MouseCodes)->Bool{
//        return mouseButtonList[Int(button.rawValue)] == true
//    }
//    
//    public static func SetOverallMousePosition(position: float2){
//        self.overallMousePosition = position
//    }
//    
//    ///Sets the delta distance the mouse had moved
//    public static func SetMousePositionChange(overallPosition: float2, deltaPosition: float2){
//        self.overallMousePosition = overallPosition
//        self.mousePositionDelta = deltaPosition
//    }
//    
//    public static func ScrollMouse(deltaY: Float){
//        scrollWheelChange = deltaY
//    }
//    
//    //Returns the overall position of the mouse on the current window
//    public static func GetMouseWindowPosition()->float2{
//        return overallMousePosition
//    }
//    
//    ///Returns the movement of the wheel since last time getDWheel() was called
//    public static func GetDWheel()->Float{
//        let position = -scrollWheelChange
//        return position
//    }
//    
//    ///Movement on the y axis since last time getDY() was called.
//    public static func GetDY()->Float{
//        let result = mousePositionDelta.y
//        mousePositionDelta.y = 0
//        return result
//    }
//    
//    ///Movement on the x axis since last time getDX() was called.
//    public static func GetDX()->Float{
//        let result = mousePositionDelta.x
//        mousePositionDelta.x = 0
//        return result
//    }
//    
//    //Returns the mouse position in screen-view coordinates [-1, 1], independent of camera zoom
//    public static func GetMouseViewportPosition()->float2{
//        let x = (overallMousePosition.x - Renderer.ScreenSize.x * 0.5) / (Renderer.ScreenSize.x * 0.5)
//        let y = (overallMousePosition.y - Renderer.ScreenSize.y * 0.5) / (Renderer.ScreenSize.y * 0.5)
//        return float2(x, y)
//    }
//}
