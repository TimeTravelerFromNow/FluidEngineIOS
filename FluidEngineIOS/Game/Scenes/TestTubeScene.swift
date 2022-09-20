import MetalKit

enum States {
    case Moving
    case Emptying
    case Filling
    case Selected
    case Idle
    case HoldInterval
    case CleanupValues
}

class TestTubeScene : Scene {
    
    var backGroundObject: CloudsBackground!
    var fluidObject: DebugEnvironment!
    
    var tubeGrid: [ TestTube ] = []
    
    var buttons: [ BoxButton ] = []
    
    var debugQuad: GameObject!
    
    var tubeLevel: TubeLevel!
    
    // tube emptying
    var emptyingTubes: Bool = false
    private var _emptyDuration: Float = 1.0
    private let defaultEmptyTime: Float = 1.0
    
    //collision thresholding and geometries
    private var collisionThresh: Float = 0.3
    private var tubeHeight: Float = 0.0 // can determine at run time
    private var tubeWidth : Float = 0.18
    // tube filling
    var tubesFilling: Bool = true
    
    // tube moving
    var tubeIsActive: Bool = false
    var tubeReleased: Bool = true
    var selectedTube: TestTube?
    // tube pour selection
    var pourCandidate: TestTube?
    private var _selectorTime: Float = 0.6
    var startedHovering: Bool = false
    let hoverSelectTime: Float = 0.6 // when we reach 0.0, pourCandidate becomes the tube we are hovering over.
    var hasCommittedtoPour: Bool = false
    //geometry
    let tubeDimensions: float2 = float2(0.4,1)
    
    private var _currentState: States = .Filling
    
    private var _holdDelay: Float = 0.2
    private let _defaultHoldTime: Float = 0.2
    
    private var _emptyKF = 0
    
    func addTestButton() {
        let testButton = BoxButton(.ClearButton,.ClearButton, .Clear, center: box2DOrigin)
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(-3.0,0.0))

        buttons.append(testButton)
        buttons.append(menuButton)
        addChild(testButton)
        addChild(menuButton)

    }
    
    override func buildScene(){
        tubeLevel = TubeLevel()
        fluidObject = FluidEnvironment.Environment
        fluidObject.setScale(2 / (GameSettings.ptmRatio * 10) )
        fluidObject.setPositionZ(0.1)
        
        backGroundObject = SharedBackground.Background
                
        InitializeGrid()
        
        addTestButton()
        
        for tube in tubeGrid {
            addChild(tube)
        }
        addChild(fluidObject)
        addChild(backGroundObject)
        freeze()
    }
    
    private func InitializeGrid() {
        let height : Float = 2.0
        let width  : Float = 5.0
        let xSep : Float = 1.0
        let ySep : Float = 2.0
        var y : Float = height + box2DOrigin.y
        var x : Float = 0.5 + box2DOrigin.x
        let rowNum = Int(width / xSep)
        let maxColNum = Int(height / ySep)
        if tubeLevel.startingLevel.count > (rowNum * maxColNum ){
            print("warning we will probably be out of bounds with this many tubes.")
        }
        for (i, tubeColors) in tubeLevel.startingLevel.enumerated() {
            if(x < width) {
                let currentTube = TestTube(origin: float2(x:x,y:y), gridId: i)
                if tubeHeight == 0.0  {// unitialized, then initialize
                    self.tubeHeight = currentTube.getTubeHeight()
                    print("initializing real tube height for collision testing")
                }
                currentTube.initialFillContainer(colors: tubeColors)
                currentTube.setScale(2 / (GameSettings.ptmRatio * 10) )
                currentTube.setPositionZ(1)
                addChild(currentTube.sceneRepresentation)
                tubeGrid.append(currentTube)
                x += xSep
            } else {
                x = 0.5
                y -= ySep
                let currentTube = TestTube(origin: float2(x:x,y:y), gridId: i)
                currentTube.initialFillContainer(colors: tubeColors)
                currentTube.setScale(2 / (GameSettings.ptmRatio * 10) )
                currentTube.setPositionZ(1)
                addChild(currentTube.sceneRepresentation)
                tubeGrid.append(currentTube)
                x += xSep
            }
        }
    }
    
    private func refillTubesToCurrentState() {
        for (i, tubeColors) in tubeLevel.colorStates.enumerated() {
            tubeGrid[i].initialFillContainer(colors: tubeColors)
        }
    }
    
    private func beginEmpty() {
        _emptyKF = 0
        tubeIsActive = false
        _emptyDuration = defaultEmptyTime
        emptyingTubes = true
        _currentState = .Emptying
    }
    
    private func EmptyTubesStep(_ deltaTime: Float) {
        switch _emptyKF{
        case 0: // empty all
            for tube in tubeGrid {
                tube.BeginEmpty()
            }
           nextEmptyKF()
        case 1:  // wait the empty duration ( can refactor to also count all the particles as a condition for completness. )
            if _emptyDuration > 0.0 {
                _emptyDuration -= deltaTime
            } else {
                nextEmptyKF()
            }
        case 2:
            var stillEmptying = false
            for tube in tubeGrid {
                if tube.currentState == .Emptying {
                    stillEmptying = true
                }
            }
            if !stillEmptying { nextEmptyKF() }
        case 3:  // done
            emptyingTubes = false
            refillTubesToCurrentState()
            nextEmptyKF()
        default :
            break
        }
    }
    
    private func nextEmptyKF() {
        _emptyDuration = defaultEmptyTime
        _emptyKF += 1
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
    
    // cant see much of difference from above now
    private func kineticHitTest() -> TestTube? { // tests based on current location
        for testTube in tubeGrid {
            if let testTube = testTube.getTubeAtBox2DPosition(Touches.GetBoxPos()) {
                return testTube
            }
        }
        return nil
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
    
    func pourTubes() {
        self.selectedTube!.setCandidateTube( self.pourCandidate! )
        var newPouringTubeColors = [TubeColors].init(repeating: .Empty, count: 4)
        var newCandidateTubeColors = [TubeColors].init(repeating: .Empty, count: 4)
        
        (newPouringTubeColors, newCandidateTubeColors) = tubeLevel.pourTube(pouringTubeIndex: self.selectedTube!.gridId, pourCandidateIndex: self.pourCandidate!.gridId)
        self.selectedTube!.startPouring( newPourTubeColors: newPouringTubeColors,
                                         newCandidateTubeColors: newCandidateTubeColors)
    }
    
    func hoverSelect(_ boxPos: float2, deltaTime: Float, excludeMoving: Int) {
        guard let tubeHovering = boxHitTest(boxPos: boxPos, excludeDragging: excludeMoving ) else
        {
            startedHovering = false
            _selectorTime = hoverSelectTime
            return
        }
        if startedHovering {
            print("started Hovering \(_selectorTime)")
            if(tubeHovering.gridId == pourCandidate!.gridId) {
                // make sure we have the same candidate as before
            } else { startedHovering = false }
            _selectorTime -= deltaTime
            if _selectorTime < 0.0 {
                if pourCandidate?.currentState == .AtRest {
                    print("Committed to pOUR!")
                    hasCommittedtoPour = true
                    pourTubes()
                    _currentState = .Idle
                } else {
                    print("I want to commit to pour, but this candidate is not resting, instead \(pourCandidate?.currentState).")
                }
                // call level update
            }
        } else {
            //logic for if a pour is possible
            pourCandidate = tubeHovering
            let candidateIndex = pourCandidate!.gridId!
            
            if !(tubeLevel.pourConflict(pouringTubeIndex: excludeMoving, pouringCandidateIndex: candidateIndex) ){
                print("no conflict")
                startedHovering = true
                _selectorTime = hoverSelectTime
            } else { startedHovering = false }
        }
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
    func unSelect() {
        print("let go of tube")
        selectedTube?.returnToOrigin()
        selectedTube = nil
        _holdDelay = _defaultHoldTime
        _currentState = .Idle
    }
    override func touchesBegan() {
        
        switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
        case .None:
            print("hit a test button")
        case .Clear:
            print("hit the clear button")
        case nil:
            print("clicked no button")
        default:
            break
        }
        fluidObject.debugParticleDraw(atPosition: Touches.GetBoxPos())
    
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
                pourCandidate = nodeAt
                if !(tubeLevel.pourConflict(pouringTubeIndex: selectedTube?.gridId ?? -1, pouringCandidateIndex: nodeAt.gridId ) ) && (nodeAt.currentState == .AtRest){
                    pourTubes()
                    _currentState = .Idle
                } else { // red highlights Flash
                    pourCandidate?.conflict()
                    unSelect()
                }
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
        switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
        case .None:
            print("let go of a button")
        case .Clear:
            beginEmpty()
            print("clear action now")
        case .ToMenu:
            SceneManager.sceneSwitchingTo = .Menu
        case nil:
            print("let go of no button")
        default:
            break
        }
        for b in buttons {
            b.deSelect()
        }
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
    
    override func update(deltaTime : Float) {
        super.update(deltaTime: deltaTime)
        backGroundObject.update(deltaTime: GameTime.DeltaTime)
        
        if _currentState ==  .Emptying {
        EmptyTubesStep(deltaTime)
        }
        if (Touches.IsDragging) {
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
                hoverSelect(boxPos, deltaTime: deltaTime, excludeMoving: selectId)
            default:
                break
                print("current scene state: \(_currentState)")
            }
        }

    }
}

