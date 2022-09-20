import MetalKit

enum ButtonActions {
    case Clear
    case NewGame
    case ToMenu
    case ToBeach
    
    case None
}

enum SceneSwitchStates {
    case Idle
    case ToTestTubeScene
    case ToBeachScene
    case ToMenuScene
}

class MenuScene : Scene {
        
    var backGroundObject: CloudsBackground!
    var fluidObject: DebugEnvironment!
    var waterFall: WaterFallObject!
    
    var buttons: [ BoxButton ] = []
        
    private var _holdDelay: Float = 0.2
    private let _defaultHoldTime: Float = 0.2
    
    private var _emptyKF = 0
    
    private func addTestButtons() {
        let newGameButton = BoxButton(.TestButton, .TestButton, .NewGame, center: box2DOrigin + float2(x: -3.0, y: 1.0))
        let beachButton = BoxButton(.BeachButton, .BeachButton, .ToBeach, center: box2DOrigin + float2(x: -3.0, y: -1.0))

        buttons.append(newGameButton)
        addChild(newGameButton)
        
        buttons.append(beachButton)
        addChild(beachButton)
    }
    
    override func buildScene(){        
        fluidObject = FluidEnvironment.Environment
        backGroundObject = SharedBackground.Background
        
        fluidObject.setScale(2 / (GameSettings.ptmRatio * 10) )
        fluidObject.setPositionZ(0.1)
        
        addTestButtons()
        
        waterFall = WaterFallObject(center: float2(x:-6.15, y: -1.0) + box2DOrigin)
        
        fluidObject = FluidEnvironment.Environment
        fluidObject.isDebugging = false
        addChild(fluidObject)
        addChild(backGroundObject)
        addChild(waterFall)
        addChild(waterFall.getCliff())
        
        for pine in waterFall.getPines() {
            addChild(pine)
        }
    }
    
    override func sceneSizeWillChange() {
        super.sceneSizeWillChange()
    }
    
    override func freeze() {
        for button in buttons {
            button.freeze()
        }
        waterFall.clearParticles()
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
    
    
   

}

