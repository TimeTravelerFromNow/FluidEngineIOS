import MetalKit


class MenuScene : Scene {
    
    var startingBanner: FloatingBanner!

    var testTextObject: TextObject!
    
    var buttons: [ BoxButton ] = []
    var buttonPressed: ButtonActions?
    // test tube play state
    
    var tubeGrid: [ TestTube ] = []
    var _currentState: States = .Idle
    var selectedTube: TestTube?
    
    private var _holdDelay: Float = 0.2
    private let _defaultHoldTime: Float = 0.2
    
    private var _emptyKF = 0
    
    private func addTestButtons() {
        let newGameButton   = BoxButton(.Menu, .Menu, .NewGame, center: box2DOrigin + float2(x: 0.0, y: 0.0), label: .NewGameLabel )
        let devSceneButton  = BoxButton(.Menu, .Menu, .ToDev, center: box2DOrigin + float2(x:0.0, y: 1.0), label: .DevSceneLabel)
        buttons.append(newGameButton)
        buttons.append(devSceneButton)
        addChild(newGameButton)
        addChild(devSceneButton)
    }
    
    private func addTestTube() {
        let testTube0 = TestTube(origin: box2DOrigin + float2(x:1.2, y: 3.0), gridId: 0, scale: 10.0)
        let testTube1 = TestTube(origin: box2DOrigin + float2(x:1.5, y: 3.0), gridId: 1, scale: 10.0)
        tubeGrid.append(contentsOf: [testTube0, testTube1])
        for tt in tubeGrid {
            addChild(tt)
        }
    }
    
    private func addStartingBanner() {
        startingBanner = FloatingBanner(box2DOrigin + float2(0,3), size: float2(3,1.5), textureType: .MainGameBannerTexture)
        startingBanner.setPositionZ(0.2)
        addChild( startingBanner )
    }
    
    override func buildScene() {
        addTestButtons()
        sceneSizeWillChange()
        addTestTube()
        addStartingBanner()
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
    
    // cant see much of difference from above now
    private func kineticHitTest() -> TestTube? { // tests based on current location
        for testTube in tubeGrid {
            if let testTube = testTube.getTubeAtBox2DPosition(Touches.GetBoxPos()) {
                return testTube
            }
        }
        return nil
    }
    
    override func touchesBegan() {
        if let buttonHit = boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
            buttonPressed = buttonHit
            switch buttonHit {
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
        }
        FluidEnvironment.Environment.debugParticleDraw(atPosition: Touches.GetBoxPos())
        
        switch _currentState {
        case .HoldInterval:
            print("grabbed tube, determining hold status")
            selectedTube?.select()
        case .Moving: // use hover code
            print("grabbed tube")
            selectedTube?.moveToCursor(Touches.GetTouchViewportPosition()) // MARK: Needs refactoring in both
        case .Emptying:
            var oneEmptying = false
            for tube in tubeGrid {
                oneEmptying = (tube.isEmptying || oneEmptying)
            }
            if !oneEmptying {
                _currentState = .Filling
            }
        case .Filling:
            var oneFilling = false
            for tube in tubeGrid {
                oneFilling = (tube.isEmptying || oneFilling)
            }
            if !oneFilling {
                _currentState = .Idle
            }
        case .Selected:
            guard let nodeAt = kineticHitTest() else {
                unSelect()
                return
            }
            if nodeAt.gridId == selectedTube?.gridId { // we clicked the same selected tube
                _currentState = .Moving
            } else { // pour into nodeAt
            }
        case .Idle:
            guard let nodeAt = boxHitTest(boxPos: Touches.GetBoxPos(), excludeDragging: -1) else { return }
            if nodeAt.currentState == .AtRest {
                selectedTube = nodeAt
                selectedTube?.select()
                _currentState = .HoldInterval
            }
        default:
            print("nothing to do")
        }
    }
    
    override func touchesEnded() {
        if buttonPressed != nil {
        switch buttonPressed {
        case .None:
            print("let go of a button")
        case .Clear:
            print("clear action now")
        case .NewGame:
            SceneManager.sceneSwitchingTo = .TestTubes
            print("start a new game now!")
            SceneManager.Get( .TestTubes ).unFreeze()
            LiquidFun.setGravity(float2(x:0,y:-9.8065))
        case .ToMenu:
            print("pressed to menu button in the menu?")
        case .ToDev:
            SceneManager.sceneSwitchingTo = .Dev
            print("Going to developer scene!")
            SceneManager.Get( .Dev ).unFreeze()
//            LiquidFun.setGravity(float2(x:0,y:0))
        case nil:
            print("let go of no button")
        default:
            print("Button Action WARN::need \(boxButtonHitTest(boxPos: Touches.GetBoxPos())) action.")
            break
        }
        }
        
        deselectButtons()
        
        switch _currentState {
        case .HoldInterval:
            if _holdDelay > 0.0 {
                selectedTube?.currentState = .Selected
                _currentState = .Selected
            } else {
                unSelect()
            }
        case .Moving:
            unSelect()
        default:
            print("nothing to do")
        }
    }
    
    func unSelect() {
        print("let go of tube")
//        selectedTube?.returnToOrigin( waterFall.particleSystem )
        selectedTube = nil
        _holdDelay = _defaultHoldTime
        _currentState = .Idle
    }
    
    private func boxHitTest( boxPos: float2, excludeDragging: Int ) -> TestTube? {
        for testTube in tubeGrid {
            if let testTube = testTube.getTubeAtBox2DPosition(boxPos) {
                if testTube.gridId != excludeDragging {
                return testTube
                }
            }
        }
        return nil
    }
    
    private func deselectButtons() {
        for b in buttons {
            b.deSelect()
        }
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        startingBanner.setScaleRatio( (sin( GameTime.TotalGameTime) + 7.3) / 12.3  )

        if shouldUpdateGyro {
            LiquidFun.setGravity(float2(x: gyroVector.x, y: gyroVector.y))
        }
        if (Touches.IsDragging) {
            if(buttonPressed != nil) {
                let boxPos = Touches.GetBoxPos()
                buttonPressed = boxButtonHitTest(boxPos: boxPos)
                if buttonPressed == nil {
                    deselectButtons()
                }
            }
            switch _currentState {
            case .HoldInterval:
                if _holdDelay == _defaultHoldTime {
                    selectedTube?.select()
                }
                if _holdDelay >= 0.0 {
                    _holdDelay -= deltaTime
                }
                else {
                    _currentState = .Moving
                }
            case .Moving:
                let boxPos = Touches.GetBoxPos()
                selectedTube?.moveToCursor(boxPos)
                guard let selectId = selectedTube?.gridId else { return }
//                hoverSelect(boxPos, deltaTime: deltaTime, excludeMoving: selectId)
            default:
                break
                print("current scene state: \(_currentState)")
            }
        }
    }
    
}

