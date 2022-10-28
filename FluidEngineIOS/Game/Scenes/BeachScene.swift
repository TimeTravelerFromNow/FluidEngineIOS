import MetalKit

class BeachScene : Scene {
    
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
        surfObject = SurfObject(center: box2DOrigin)
        addChild(surfObject)
        addChild(surfObject.getBeach())
        
        addTestButtons()
                
        freeze()

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
    
    private func switchToTestTubeScene() {
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
        FluidEnvironment.Environment.debugParticleDraw(atPosition: Touches.GetBoxPos())
    
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

