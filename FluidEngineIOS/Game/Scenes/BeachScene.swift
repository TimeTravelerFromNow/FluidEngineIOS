import MetalKit

class BeachScene : Scene {
    
    var currentState: SceneSwitchStates!
    var backGroundObject: CloudsBackground!
    var fluidObject: DebugEnvironment!
    var surfObject: SurfObject!
    
    var buttons: [ BoxButton ] = []
        
    var sharedNodes: [Node] = []
    var isSharingNodes: Bool = false
    
    private var _holdDelay: Float = 0.2
    private let _defaultHoldTime: Float = 0.2
    
    private var _emptyKF = 0
    
    private func addTestButtons() {
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(0.0, 3.0), label: .MenuLabel)
        
        buttons.append(menuButton)
        addChild(menuButton)
    }
    
    override func buildScene(){
    
        currentState = .Idle

        surfObject = SurfObject(center: box2DOrigin)
        addChild(surfObject)
        addChild(surfObject.getBeach())
        
        fluidObject = FluidEnvironment.Environment
        fluidObject.setScale(2 / (GameSettings.ptmRatio * 10) )
        fluidObject.setPositionZ(0.1)
        
        backGroundObject = SharedBackground.Background
        
        addTestButtons()
                
        fluidObject = FluidEnvironment.Environment
        addChild(fluidObject)
        addChild(backGroundObject)
        freeze()
    }
    
    override func sceneSizeWillChange() {
        super.sceneSizeWillChange()
//        fluidObject.makeBoundingBox(center: box2DOrigin - float2(6,2), size: Size2D(width: 12, height: 4))
        GameSettings.particleRadius = 20.0
    }
    
    override func freeze() {
        for button in buttons {
            button.freeze()
        }
        surfObject.removeParticles()
    }
    override func unFreeze() {
        for button in buttons {
            button.unFreeze()
        }
    }
    
    private func boxButtonHitTest( boxPos: float2) -> ButtonActions? {
        var hits: [ButtonActions] = []
        for b in buttons {
            if let action = b.boxHitTest( boxPos ) {
                hits.append( action )
            }
        }
        if hits.count != 0 {
            return hits.first
        }
        return nil
    }

    
    private func shareNodesWithTestTubeScene() {
        if isSharingNodes {
            for node in sharedNodes {
                self.removeChild(node)
            }
            self.sharedNodes = []
            isSharingNodes = false
        } else {
            for node in SceneManager.Get(.TestTubes).children {
                if node is Camera {
                    
                }
                else if node is DebugEnvironment {
                    print("dont add teh shared fluid env again")
                }
                else {
                    self.addChild(node)
                    self.sharedNodes.append(node)
                }
            }
            isSharingNodes = true
        }
    }
    
    private func switchToTestTubeScene() {
        shareNodesWithTestTubeScene()
        SceneManager.SetCurrentScene(.TestTubes)
        SceneManager.currentScene.sceneSizeWillChange()

    }

    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        if panVelocity != float2(0.0,0.0) {
            moveOrthoCamera(deltaTime: deltaTime)
        }
    }
    
    override func touchesBegan() {
        switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
        case .None:
            print("hit a test button")
        case .Clear:
            print("hit the clear button")
        case .NewGame:
            print("hit the new game button")
        case nil:
            print("clicked no button")
        default:
            print("clicked a button")
        }
        fluidObject.debugParticleDraw(atPosition: Touches.GetBoxPos())
    
    }
    
    override func touchesEnded() {
        switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
        case .None:
            print("let go of a button")
        case .ToMenu:
            SceneManager.sceneSwitchingTo = .Menu
        case nil:
            print("let go of no button")
        default:
            print("button action not defined in beach scene")
            break
        }
        for b in buttons {
            b.deSelect()
        }
    }
}

