import MetalKit
import CoreMotion

enum SceneTypes {
    case TestTubes
    case Menu
    case AlienScene
    case Dev
    
    case None
}

let SceneOrigins: [SceneTypes: float2] = [.TestTubes:float2(-25.0, 5.0),
                                          .Menu:float2(-5.0, 5.0),
                                          .AlienScene:float2(15.0, 0.0),
                                          .Dev:float2(0.0,0.0)]

enum SmoothingStates {
    case Leaving
    case EnRoute
    case Arriving
    case Arrived
}

class Scene: Node {
    var sceneConstants = SceneConstants()
    var cameras: [Camera] = []
    var currentCamera = Camera()
    var orthoCamera = OrthoCamera()
    var panVelocity = float2(0,0)
    let box2DOrigin: float2!
    private var _smoothInterval: Float = 1.0
    private var _smoothStage: SmoothingStates = .Leaving
    let sceneType: SceneTypes!
    
    var shouldUpdateGyro = false
    var gyroVector: float2 = float2(0)
    
    init(_ sceneType: SceneTypes) {
        box2DOrigin = SceneOrigins[sceneType]
        self.sceneType = sceneType
        super.init()
        cameras.append(currentCamera)
        cameras.append(orthoCamera)
        currentCamera = orthoCamera
        orthoCamera.rotateY(.pi)
        orthoCamera.setPositionZ(10)
        orthoCamera.setPositionY(box2DOrigin.y / 5.0)
        orthoCamera.setPositionX(box2DOrigin.x / 5.0)
        buildScene()
    }
    
    func moveOrthoCamera(deltaTime: Float) {
        orthoCamera.moveX(panVelocity.x * deltaTime)
        orthoCamera.moveY(panVelocity.y * deltaTime)
        SceneManager.SkyBackground.moveX(panVelocity.x * deltaTime)
        SceneManager.SkyBackground.moveY(panVelocity.y * deltaTime)
    }
    
    func buildScene() { }
    
    func freeze() { }
    func unFreeze() { }
    
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
        if length_squared( destination - camPos ) < 0.1 {
            _smoothStage = .Arriving
            _smoothInterval = 0.01
        }
        if length_squared( destination - camPos ) < 0.01 {
            _smoothInterval = 1.0
            _smoothStage = .Leaving
            panVelocity = float2(0)
            SceneManager.sceneSwitchingTo = .None

            SceneManager.Get( toScene ).sceneSizeWillChange()
            self.freeze()
            SceneManager.SetCurrentScene( toScene )
            
            SceneManager.Get( toScene ).orthoCamera.setPositionX( orthoCamera.getPositionX() )
             SceneManager.Get( toScene ).orthoCamera.setPositionY( orthoCamera.getPositionY() )
            SceneManager.Get( toScene ).panVelocity = float2(0)
            return
        }
        switch _smoothStage {
        case .Leaving:
            panVelocity.x *= (1.0 - _smoothInterval)
            panVelocity.y *= (1.0 - _smoothInterval)
            if _smoothInterval < 0.0 {
                _smoothStage = .Leaving
            }
            _smoothInterval -= deltaTime
        case .EnRoute:
            break
        case .Arriving:
            panVelocity.x *= (1.0 - _smoothInterval)
            panVelocity.y *= (1.0 - _smoothInterval)
            if _smoothInterval < 0.9 {
                _smoothInterval += deltaTime * 0.1
            } else {
                
            }
        case .Arrived:
            _smoothInterval = 1.0
            _smoothStage = .Leaving
        }
        
        moveOrthoCamera(deltaTime: deltaTime)
        SceneManager.Get( toScene ).orthoCamera.setPositionX( orthoCamera.getPositionX() )
         SceneManager.Get( toScene ).orthoCamera.setPositionY( orthoCamera.getPositionY() )
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
    
    public static var sceneSwitchingTo: SceneTypes!
    
    public static var SkyBackground: CloudsBackground!

    public static let MotionManager: CMMotionManager = CMMotionManager() //MARK: not sure if best place, but things are getting messy anyways
    
    public static func Initialize(_ startingScene: SceneTypes ) {
        createScenes()
        currentScene = Get(startingScene)
        sceneSwitchingTo = .None
        SkyBackground = SharedBackground.Background
        SkyBackground.setPositionX(currentScene.orthoCamera.getPositionX())
        SkyBackground.setPositionY(currentScene.orthoCamera.getPositionY())
        for scene in scenes.values {
            scene.sceneSizeWillChange()
            scene.freeze()
        }
        currentScene.unFreeze()
    }
    
    private static func createScenes() {
        scenes.updateValue(TestTubeScene(.TestTubes), forKey: .TestTubes)
        scenes.updateValue(MenuScene(.Menu), forKey: .Menu)
        scenes.updateValue(AlienScene(.AlienScene), forKey: .AlienScene)
        scenes.updateValue(DevScene(.Dev), forKey: .Dev)
    }
    
    public static func Get(_ sceneType : SceneTypes) -> Scene {
        return scenes[sceneType]!
    }
    
    public static func SetCurrentScene(_ sceneType : SceneTypes) {
        currentScene = Get(sceneType)
    }
    
    public static func update(_ deltaTime: Float) {
        currentScene!.update(deltaTime: deltaTime)
        SkyBackground.update(deltaTime: deltaTime)
        
        if( sceneSwitchingTo != .None ) {
            scenes[sceneSwitchingTo]!.update(deltaTime:deltaTime)
            currentScene.sceneSwitchStep(deltaTime: deltaTime, toScene: sceneSwitchingTo)
        }
        if( currentScene.shouldUpdateGyro ) {
            SceneManager.MotionManager.startAccelerometerUpdates(to: OperationQueue(),
                                                                 withHandler: {
                (accelerometerData, error) -> Void in
                guard let acceleration = accelerometerData?.acceleration else { print("Motion Manger WARNING:: couldnt get acceleromter data."); return}
                let gravityX = 9.806 * Float(acceleration.x)
                let gravityY = 9.806 * Float(acceleration.y)
                currentScene.gyroVector = float2(gravityX, gravityY)
            })
        }
        FluidEnvironment.Environment.update(deltaTime: deltaTime)
    }
    
    public static func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        currentScene!.render(renderCommandEncoder)
        SkyBackground.render(renderCommandEncoder)
        if( sceneSwitchingTo != .None) {
            scenes[sceneSwitchingTo]!.render(renderCommandEncoder)
        }
        FluidEnvironment.Environment.render(renderCommandEncoder) // causing GPU errors which freeze app.
    }
}

