import MetalKit
import CoreHaptics

class AlienScene : Scene {
    
    var buttons: [ BoxButton ] = []
    
    private func addTestButtons() {
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(0.0, 3.0), label: .MenuLabel, staticButton: false)
        let testButton = BoxButton(.Menu,.Menu, .TestAction1, center: box2DOrigin + float2(1.0, 3.0), label: .TestLabel1, staticButton: false)

        buttons.append(menuButton)
        addChild(menuButton)
        
        buttons.append(testButton)
        addChild(testButton)
    }
    
    private func addEnemies() {
        let testEnemy = AlienEnemy(position: box2DOrigin + float2(0.0, 1.0), meshType: .Alien, textureType: .AlienTexture, scale: 2.0)
        addChild(testEnemy)
    }
    
    override func buildScene(){
        
        
        addTestButtons()
                
        freeze()
     
        SharedBackground.Background.skyBG.cmesh.updateVertexColor(float4(0,0,0.1,1.0), atIndex: 0)
        SharedBackground.Background.skyBG.cmesh.updateVertexColor(float4(0,0.1,0.0,1.0), atIndex: 1)
        SharedBackground.Background.skyBG.cmesh.updateVertexColor(float4(0,0.1,0.0,1.0), atIndex: 2)
        SharedBackground.Background.skyBG.cmesh.updateVertexColor(float4(0,0.0,0.1,1.0), atIndex: 3)
        addEnemies()
    }
    
    override func freeze() {
        for button in buttons {
            button.freeze()
        }
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
        case .TestAction1:
            print("test something")
            addEnemies()
            shouldUpdateGyro = true
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

