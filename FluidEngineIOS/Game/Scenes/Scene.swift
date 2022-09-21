import MetalKit

enum SceneTypes {
    case TestTubes
    case Menu
    case Beach
    
    case None
}

let SceneOrigins: [SceneTypes: float2] = [.TestTubes:float2(-5.0, -10.0),
                                          .Menu:float2(-5.0, 5.0),
                                          .Beach:float2(10.0, 0.0)]

class Scene: Node {
    var sceneConstants = SceneConstants()
    var cameras: [Camera] = []
    var currentCamera = Camera()
    var orthoCamera = OrthoCamera()
    var panVelocity = float2(0,0)
    let box2DOrigin: float2!
    private var sharedNodes: [Node] = []
    private var isSharingNodes: Bool = false
    let sceneType: SceneTypes!
    
    init(_ sceneType: SceneTypes) {
        box2DOrigin = SceneOrigins[sceneType]
        self.sceneType = sceneType
        super.init()
        cameras.append(currentCamera)
        cameras.append(orthoCamera)
        currentCamera = orthoCamera
        orthoCamera.rotateY(.pi)
        orthoCamera.setPositionZ(1)
        orthoCamera.setPositionY(box2DOrigin.y / 5.0)
        orthoCamera.setPositionX(box2DOrigin.x / 5.0)
        buildScene()
    }
    
    func moveOrthoCamera(deltaTime: Float) {
        orthoCamera.moveX(panVelocity.x * deltaTime)
        orthoCamera.moveY(panVelocity.y * deltaTime)
    }
    
    func buildScene() { }
    
    func freeze() { }
    func unFreeze() { }
    func addSharedNodes(_ ofScene: SceneTypes) {
        if( ofScene == .None ) { return }
        if( ofScene == self.sceneType ) { return }
        SceneManager.Get( ofScene ).unFreeze()

        if isSharingNodes {
            for node in sharedNodes {
                self.removeChild(node)
            }
            self.sharedNodes = []
            isSharingNodes = false
        } else {
            for node in SceneManager.Get( ofScene ).children {  // nodes ofScene get added
                if node is Camera {
                    // no cameras
                }
                else if node is DebugEnvironment {
                    print("dont add the shared fluid env again") // no fluid environments
                }
                else if node is CloudsBackground {
                    print("dont add shared background")
                }
                else {
                    self.addChild(node)
                    self.sharedNodes.append(node)
                }
            }
            isSharingNodes = true
        }
    }
    
    func removeSharedNodes() { for node in sharedNodes { self.removeChild(node) } }
    
    func sceneSwitchStep(deltaTime: Float, toScene: SceneTypes) {
        if( toScene == .None ) { print("why are we switch stepping to .None scene?"); return}
        let camPos = float2( orthoCamera.getPositionX(), orthoCamera.getPositionY() )
        let destination = SceneManager.Get(toScene).box2DOrigin! / 5.0
        let moveDirection = destination - camPos
        panVelocity = normalize( moveDirection ) * 4.0
        var change = panVelocity * deltaTime
        if length_squared( change - destination ) > 0.01 {
            while ( abs( change.x ) > abs( moveDirection.x ) ) {
                panVelocity.x *= 0.9
                change = panVelocity * deltaTime
            }
            while ( abs(change.y ) > abs(moveDirection.y ) ) {
                panVelocity.y *= 0.9
                change = panVelocity * deltaTime
            }
        }
        if length_squared( destination - camPos ) < 0.01 {
            panVelocity = float2(0)
            removeSharedNodes()
            SceneManager.sceneSwitchingTo = .None
            SceneManager.Get( toScene ).orthoCamera.setPositionX( camPos.x )
            SceneManager.Get( toScene ).orthoCamera.setPositionY( camPos.y )
            SceneManager.Get( toScene ).sceneSizeWillChange()
            self.freeze()
            SceneManager.SetCurrentScene( toScene )
        }
        moveOrthoCamera(deltaTime: deltaTime)
    }
    
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
    
    func touchesBegan() { }
    
    func touchesEnded() { }
}

class SceneManager: Library<SceneTypes, Scene> {
    private static var scenes : [SceneTypes : Scene] = [:]
    
    public static var currentScene: Scene!
    
    public static var sceneSwitchingTo: SceneTypes! { didSet { currentScene.addSharedNodes( sceneSwitchingTo ) } }
    
    public static func Initialize(_ startingScene: SceneTypes ) {
        createScenes()
        currentScene = Get(startingScene)
        sceneSwitchingTo = .None
    }
    
    private static func createScenes() {
        scenes.updateValue(TestTubeScene(.TestTubes), forKey: .TestTubes)
        scenes.updateValue(MenuScene(.Menu), forKey: .Menu)
        scenes.updateValue(BeachScene(.Beach), forKey: .Beach)
    }
    
    public static func Get(_ sceneType : SceneTypes) -> Scene {
        return scenes[sceneType]!
    }
    
    public static func SetCurrentScene(_ sceneType : SceneTypes) {
        currentScene = Get(sceneType)
    }
    
    public static func update(_ deltaTime: Float) {
        currentScene!.update(deltaTime: deltaTime)
        if( sceneSwitchingTo != .None ) {
            currentScene.sceneSwitchStep(deltaTime: deltaTime, toScene: sceneSwitchingTo)
        }
    }
    
    public static func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        currentScene!.render(renderCommandEncoder)
    }
}

