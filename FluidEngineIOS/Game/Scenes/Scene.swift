import MetalKit

class Scene: Node {
    var sceneConstants = SceneConstants()
    var cameras: [Camera] = []
    var currentCamera = Camera()
    override init() {
        super.init()
        cameras.append(currentCamera)
        buildScene()
    }
    
    func buildScene() { }
    
    override func update() {
        sceneConstants.viewMatrix = currentCamera.viewMatrix
        sceneConstants.projectionMatrix = currentCamera.projectionMatrix
        super.update()
    }
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        super.render(renderCommandEncoder)
    }
    func sceneSizeWillChange() {
      for camera in cameras {
        camera.aspect = Renderer.ScreenSize.x / Renderer.ScreenSize.y
      }
    }
    
     func keyDown( ) {
    }
    
     func keyUp( ) {
    }
     func mouseDown( ) {
    }
    
     func mouseUp( ) {
    }
    
     func rightMouseDown( ) {
    }
    
     func rightMouseUp( ) {
    }
    
     func otherMouseDown( ) {
    }
    
     func otherMouseUp( ) {
    }
     func mouseMoved( ) {
    }
    
     func scrollWheel( ) {
    }
    
     func mouseDragged( ) {
    }
    
     func rightMouseDragged( ) {
    }
    
     func otherMouseDragged( ) {
    }
}

enum SceneTypes {
    case TestTubes
}

class SceneManager: Library<SceneTypes, Scene> {
    private static var scenes : [SceneTypes : Scene] = [:]
    
    public static var currentScene: Scene!
    
    public static func Initialize(_ startingScene: SceneTypes ) {
        createScenes()
        currentScene = Get(startingScene)
    }
    
    private static func createScenes() {
        scenes.updateValue(TestTubeScene(), forKey: .TestTubes)
    }
    
    public static func Get(_ sceneType : SceneTypes) -> Scene {
        return scenes[sceneType]!
    }
    
    public static func SetCurrentScene(_ sceneType : SceneTypes) {
        currentScene = Get(sceneType)
    }
    
    public static func update(_ deltaTime: Float) {
        currentScene!.update(deltaTime: deltaTime)
    }
    
    public static func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        currentScene!.render(renderCommandEncoder)
    }
}

//
////--- Keyboard Input ---
//extension GameView {
//    override var acceptsFirstResponder: Bool { return true }
//    
//    override func keyDown(with event: NSEvent) {
//        KeyBoard.SetKeyPressed(event.keyCode, isOn: true)
//        SceneManager.currentScene.keyDown()
//    }
//    
//    override func keyUp(with event: NSEvent) {
//        KeyBoard.SetKeyPressed(event.keyCode, isOn: false)
//        SceneManager.currentScene.keyUp()
//    }
//}
//
////--- Mouse Button Input ---
//extension GameView {
//    override func mouseDown(with event: NSEvent) {
//        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: true)
//        SceneManager.currentScene.mouseDown()
//    }
//    
//    override func mouseUp(with event: NSEvent) {
//        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: false)
//        SceneManager.currentScene.mouseUp()
//    }
//    
//    override func rightMouseDown(with event: NSEvent) {
//        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: true)
//        SceneManager.currentScene.rightMouseDown()
//    }
//    
//    override func rightMouseUp(with event: NSEvent) {
//        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: false)
//        SceneManager.currentScene.rightMouseUp()
//    }
//    
//    override func otherMouseDown(with event: NSEvent) {
//        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: true)
//        SceneManager.currentScene.otherMouseDown()
//    }
//    
//    override func otherMouseUp(with event: NSEvent) {
//        Mouse.SetMouseButtonPressed(button: event.buttonNumber, isOn: false)
//        SceneManager.currentScene.otherMouseUp()
//    }
//}
//
//// --- Mouse Movement ---
//extension GameView {
//    override func mouseMoved(with event: NSEvent) {
//        setMousePositionChanged(event: event)
//        SceneManager.currentScene.mouseMoved()
//    }
//    
//    override func scrollWheel(with event: NSEvent) {
//        Mouse.ScrollMouse(deltaY: Float(event.deltaY))
//        SceneManager.currentScene.scrollWheel()
//    }
//    
//    override func mouseDragged(with event: NSEvent) {
//        setMousePositionChanged(event: event)
//        SceneManager.currentScene.mouseDragged()
//    }
//    
//    override func rightMouseDragged(with event: NSEvent) {
//        setMousePositionChanged(event: event)
//        SceneManager.currentScene.rightMouseDragged()
//    }
//    
//    override func otherMouseDragged(with event: NSEvent) {
//        setMousePositionChanged(event: event)
//        SceneManager.currentScene.otherMouseDragged()
//    }
//    
//    private func setMousePositionChanged(event: NSEvent){
//        let overallLocation = float2(Float(event.locationInWindow.x),
//                                     Float(event.locationInWindow.y))
//        let deltaChange = float2(Float(event.deltaX),
//                                 Float(event.deltaY))
//        Mouse.SetMousePositionChange(overallPosition: overallLocation,
//                                     deltaPosition: deltaChange)
//    }
//    
//    override func updateTrackingAreas() {
//        let area = NSTrackingArea(rect: self.bounds,
//                                  options: [NSTrackingArea.Options.activeAlways,
//                                            NSTrackingArea.Options.mouseMoved,
//                                            NSTrackingArea.Options.enabledDuringMouseDrag],
//                                  owner: self,
//                                  userInfo: nil)
//        self.addTrackingArea(area)
//    }
//}
//
//
