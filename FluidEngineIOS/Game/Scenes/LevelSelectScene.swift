import Foundation
import CoreHaptics

class LevelSelectScene : Scene {
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
        addLevelButtons()
    }
    
    
    
    func addTestButton() {
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(1.4,4.0), label: .MenuLabel, scale: 1.1)
        buttons.append(menuButton)
        addChild(menuButton)
    }
    
    func addLevelButtons() {
        var levelCount = MyGameLevels.count
        
        let buttonPositions = CustomMathMethods.positionsMatrix(box2DOrigin, withSpacing: float2(0.9,0.6), rowLength: 10, totalCount: levelCount)
        var linOff: Int = 0
        for l in MyGameLevels {
            
            guard let buttonPosition = buttonPositions[linOff]
            else {
                print("addLevelButtons WARN:: The button position for level \(linOff) was nil.")
                continue // next iteration
            }
            let newLevelButton = BoxButton(.Menu, .Menu, .ToLevel, center: buttonPosition, label: .LevelNumberLabel, scale: 0.6)
            newLevelButton.setLevelNumberLabel(levelNumber: linOff)
            buttons.append(newLevelButton)
            addChild(newLevelButton)
            linOff += 1
        }
    }
  
    
    private func boxButtonHitTest( boxPos: float2) -> (ButtonActions?, Int?) {
        var hits: [ButtonActions] = []
        var levelsHit: [Int] = []
        for b in buttons {
            if let action = b.boxHitTest( boxPos ) {
                hits.append( action )
                levelsHit.append( b.getLevel() )
            }
        }
        if hits.count != 0 {
            return (hits.first, levelsHit.first)
        }
        return (nil, nil)
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
        (buttonPressed, _) = boxButtonHitTest(boxPos: boxPos)
        
        if buttonPressed != nil {
            playHaptic()
        }
        
        FluidEnvironment.Environment.debugParticleDraw(atPosition: Touches.GetBoxPos())
    
    }
    
    
    func doButtonAction() {
        if( buttonPressed != nil ) {
            var buttonAction: ButtonActions?
            var levelNumber: Int?
            (buttonAction, levelNumber) = boxButtonHitTest(boxPos: Touches.GetBoxPos())
            switch buttonAction {
            case .ToLevel:
                if let level = levelNumber {
                    if level != -1 {
                    SceneManager.sceneSwitchingTo = .TestTubes
                    (SceneManager.Get( .TestTubes ) as! TestTubeScene).setLevel( level )
                    } else {
                        print("level button WARN::tried to switch level from button valued -1")
                    }
                } else {
                    print("level button WARN::Button action was .ToLevel, but levelNumber from hit test function levelsHit.first was nil")
                }
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
                (buttonPressed, _) = boxButtonHitTest(boxPos: Touches.GetBoxPos())
                if buttonPressed == nil {
                    for b in buttons {
                        b.deSelect()
                    }
                }
            }
        }
    }
}

