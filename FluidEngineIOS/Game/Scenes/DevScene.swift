import MetalKit
import CoreHaptics

class DevScene : Scene {    
    var tubeGrid: [ TestTube ] = []
    
    var buttons: [ BoxButton ] = []
    
    var debugQuad: GameObject!
    
    var tubeLevel: TubeLevel!
    
    var buttonPressed: ButtonActions?
    
    var testReservoir0: ReservoirObject!
    var testReservoir1: ReservoirObject!
    
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
    
    func addSnapshots() {
        let testSnapshot = SnapshotObject(box2DOrigin)
        addChild(testSnapshot)
    }
    
    func addTestButton() {
        let clearButton = BoxButton(.ClearButton, .ClearButton, .Clear, center: box2DOrigin + float2(1.0,-3.0) )
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(-1.0,-3.0), label: .MenuLabel)
        let testButton0 = BoxButton(.Menu, .Menu, .TestAction0, center: box2DOrigin + float2(-1.0,-4.0), label: .TestLabel0)
        let testButton1 = BoxButton(.Menu, .Menu, .TestAction1, center: box2DOrigin + float2(1.0,-4.0), label: .TestLabel1)
        
        let testButton2 = BoxButton(.Menu, .Menu, .TestAction2, center: box2DOrigin + float2(-1.0,-5.0), label: .TestLabel2)
        let testButton3 = BoxButton(.Menu, .Menu, .TestAction3, center: box2DOrigin + float2(1.0,-5.0), label: .TestLabel3)

        buttons.append(clearButton)
        buttons.append(menuButton)
        buttons.append(testButton0)
        buttons.append(testButton1)
        buttons.append(testButton2)
        buttons.append(testButton3)
        addChild(clearButton)
        addChild(menuButton)
        addChild(testButton0)
        addChild(testButton1)
        addChild(testButton2)
        addChild(testButton3)
    }
    
    func addReservoirs() {
        testReservoir0 = ReservoirObject(origin: box2DOrigin + float2(-1,5))
        testReservoir0.fill(color: .Red)
        testReservoir1 =  ReservoirObject(origin: box2DOrigin + float2(1,5))
        testReservoir1.fill(color: .Blue)
        addChild(testReservoir0)
        addChild(testReservoir1)
    }
    
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

        tubeLevel = TubeLevel()
        
        addTestButton()
        addReservoirs()
        
        InitializeGrid()
//        addSnapshots()
    }
    
    func buildPipesToTubes() {
        var colorVariety: [TubeColors] = []
        var tubesToFillIndices: [Int] = []
        for (i, tube) in tubeGrid.enumerated() {
            for color in tube.currentColors {
                if( !colorVariety.contains(color)) {
                    colorVariety.append(color)
                }
            }
            if( tube.currentColors.first != .Empty ){ // non-empty tube
                tubesToFillIndices.append(i)
            }
        } // unused colorVariety (use this to figure out how many color reservoirs are needed programatically
        // MARK: hardcoded for testing
        colorVariety = [ .Red, .Blue ]
        var reservoirs: [ReservoirObject] = [ testReservoir0, testReservoir1 ]
        
        var targetsArray: [ [float2] ] = []
        for color in colorVariety {
            var currTargets: [float2] = []
            for ind in tubesToFillIndices {
                let colors = tubeGrid[ind].currentColors
                if colors.contains(color) { // this tube is a target for this color reservoir
                    currTargets.append(tubeGrid[ind].getBoxPosition() + tubeGrid[ind].getTubeHeight() / 2)
                }
            }
            targetsArray.append( currTargets )
        }
        for (i, reservoir) in reservoirs.enumerated() {
            reservoir.targets = targetsArray[i]
            reservoir.buildPipes()
        }
        
    }
    
    private func InitializeGrid() {
        let height : Float = 2.0
        let width  : Float = 5.0
        let xSep : Float = 1.0
        let ySep : Float = 2.0
        var y : Float = box2DOrigin.y
        var x : Float = box2DOrigin.x
        let rowNum = Int(width / xSep)
        let maxColNum = Int(height / ySep)
        
        let tubesCount = tubeLevel.startingLevel.count
        
        if tubesCount > (rowNum * maxColNum ){
            print("warning we will probably be out of bounds with this many tubes.")
        }
        
        if( tubesCount <= rowNum ) {
            if( tubesCount % 2 == 0) { // center it
                x -= xSep * Float(tubesCount) / 2
            }
            else { // center it on the center tube
                x -= xSep * floor( Float(tubesCount) / 2)
            }
        } else { // center it on the center tube
            x -= xSep * floor( Float(tubesCount) / 2)
        }
        
        for (i, tubeColors) in tubeLevel.startingLevel.enumerated() {
            if(x < width) {
                let currentTube = TestTube(origin: float2(x:x,y:y), gridId: i)
                if tubeHeight == 0.0  {// unitialized, then initialize
                    self.tubeHeight = currentTube.getTubeHeight()
                    print("initializing real tube height for collision testing")
                }
                currentTube.currentColors = tubeColors
                addChild(currentTube.sceneRepresentation)
                addChild(currentTube)
                tubeGrid.append(currentTube)
                x += xSep
            } else {
                x = 0.5
                y -= ySep
                let currentTube = TestTube(origin: float2(x:x,y:y), gridId: i)
                currentTube.currentColors = tubeColors
                addChild(currentTube.sceneRepresentation)
                addChild(currentTube)
                tubeGrid.append(currentTube)
                x += xSep
            }
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
            print("execute refill")
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
        _currentState = .AnimatingPour
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
        let boxPos = Touches.GetBoxPos()
        buttonPressed = boxButtonHitTest(boxPos: boxPos)
        
        for node in children {
            if let testableNode = node as? Testable {
                testableNode.touchesBegan(boxPos)
            }
        }
        
        if buttonPressed != nil {
            // Stop the engine after it completes the playback.
            engine.notifyWhenPlayersFinished { error in
                return .stopEngine
            }
            do {
            try engine.start()
            try player?.start(atTime: 0)
            } catch { print("haptics not working")}
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
    
    func doButtonAction() {
        if( buttonPressed != nil ) {
        switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
          
        case .None:
            print("let go of a button")
        case .Clear:
            testReservoir0.fill(color: .Red)
            print("clear action now ? no testing filling")
        case .ToMenu:
            SceneManager.sceneSwitchingTo = .Menu
            SceneManager.Get( .Menu ).unFreeze()
        case .TestAction0:
            buildPipesToTubes()
        case .TestAction1:
            testReservoir0.toggleTop()
            testReservoir1.toggleTop()
        case .TestAction2:
            tubesAskForLiquid()
        case .TestAction3:
            break
        case nil:
            print("let go of no button")
        default:
            print("Button Action WARN::need \(boxButtonHitTest(boxPos: Touches.GetBoxPos())) action.")
            break
        }
        }
    }
    
    func tubesAskForLiquid() {
        for tube in tubeGrid {
            var tubeColors = tube.currentColors
            var visualColors = tube.visualColors
            if( tubeColors.first != .Empty ) {
                for i in 0..<visualColors.count {
                    if( tubeColors[i] != visualColors[i] ) {
                        
                        testReservoir0.rotateBulbSegment(segmentAngle: <#T##Float#>, toAngle: <#T##Float#>)
                    }
                }
            }
        }
    }
    
    override func touchesEnded() {
        
        doButtonAction()
        
        buttonPressed = nil
        
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
        for n in children {
            if let testableNode = n as? Testable {
                testableNode.touchEnded()
            }
        }
    }
    
    override func update(deltaTime : Float) {
        super.update(deltaTime: deltaTime)
        
        shouldUpdateGyro = false
        if _currentState ==  .Emptying {
            EmptyTubesStep(deltaTime)
        }
        
        if shouldUpdateGyro {
            LiquidFun.setGravity(Vector2D(x: gyroVector.x, y: gyroVector.y))
        }
        
        if (Touches.IsDragging) {
            if buttonPressed != nil {
                buttonPressed = boxButtonHitTest(boxPos: Touches.GetBoxPos())
                if buttonPressed == nil {
                    for b in buttons {
                        b.deSelect()
                    }
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
                hoverSelect(boxPos, deltaTime: deltaTime, excludeMoving: selectId)
            default:
                break
                print("current scene state: \(_currentState)")
            }
            
            for n in children {
                if let testableNode = n as? Testable {
                    testableNode.touchDragged(Touches.GetBoxPos())
                }
            }
        }

    }
}

