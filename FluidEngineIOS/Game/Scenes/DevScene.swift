import Foundation
import CoreHaptics

class DevScene : Scene {
    // MARK: level select screen in progress
    var buttons: [ BoxButton ] = []
    
    var buttonPressed: ButtonActions?
    
    let hapticDict = [
        CHHapticPattern.Key.pattern: [
            [CHHapticPattern.Key.event: [
                CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                CHHapticPattern.Key.time: CHHapticTimeImmediate,
                CHHapticPattern.Key.eventDuration: 1.0]
            ]
        ]
    ]
    
    var pattern: CHHapticPattern?
    var engine: CHHapticEngine!
    var player: CHHapticPatternPlayer?
    
    override func buildScene(){
        do {
            pattern = try CHHapticPattern(dictionary: hapticDict)
        } catch { print("WARN:: no haptics")}

        // Create and configure a haptic engine.
        do {
            engine = try CHHapticEngine()
        } catch let error {
            print("Engine Creation Error: \(error)")
        }
        if let pattern = pattern {
            do {
                player = try engine?.makePlayer(with: pattern)
            } catch {
                print("warn haptic not working")
            }
        }
        addTestButton()
    }
    
    
    
    func addTestButton() {
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(1.4,4.0), label: .MenuLabel, scale: 1.1)
        let startButton = BoxButton(.Menu, .Menu, .StartGameAction, center: box2DOrigin + float2(-1,4.0), label: .StartGameLabel, scale: 1.1)
        let cleanButton = BoxButton(.Menu, .Menu, .Clear, center: box2DOrigin + float2(-1,3), label: .TestLabel2, scale: 1.2 )
        buttons.append(menuButton)
        buttons.append(startButton)
        buttons.append(cleanButton)
        addChild(menuButton)
        addChild(startButton)
        addChild(cleanButton)
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
    
    
    private func playHaptic() {
        // Stop the engine after it completes the playback.
        if engine != nil {
            engine.notifyWhenPlayersFinished { error in
                return .stopEngine
            }
            do {
                try engine.start()
                try player?.start(atTime: 0)
            } catch { print("haptics not working")}
        } else { print("haptic WARN::No haptic engine!")}
    }
    
    override func touchesBegan() {
        let boxPos = Touches.GetBoxPos()
        buttonPressed = boxButtonHitTest(boxPos: boxPos)
        
        if buttonPressed != nil {
            playHaptic()
        }
        
        FluidEnvironment.Environment.debugParticleDraw(atPosition: Touches.GetBoxPos())
    
    }
    
    
    func doButtonAction() {
        if( buttonPressed != nil ) {
            switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
            case .None:
                break
            case .ToMenu:
                SceneManager.sceneSwitchingTo = .Menu
                SceneManager.Get( .Menu ).unFreeze()
            case .TestAction2:
                break
            case nil:
                break
            default:
                print("Button Action ADVISE::need \(boxButtonHitTest(boxPos: Touches.GetBoxPos())) action.")
                break
            }
        }
    }
    
    override func touchesEnded() {
        
        doButtonAction()
        
        buttonPressed = nil
        
        for b in buttons {
            b.deSelect()
        }
    }
   
    
    override func update(deltaTime : Float) {
        super.update(deltaTime: deltaTime)
        
        if (Touches.IsDragging) {
            if buttonPressed != nil {
                buttonPressed = boxButtonHitTest(boxPos: Touches.GetBoxPos())
                if buttonPressed == nil {
                    for b in buttons {
                        b.deSelect()
                    }
                }
            }
        }
    }
}

