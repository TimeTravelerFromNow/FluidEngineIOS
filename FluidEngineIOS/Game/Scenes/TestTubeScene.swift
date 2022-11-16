import MetalKit
import CoreHaptics

enum States {
    case Moving
    case Emptying
    case Filling
    case Selected
    case Idle
    case HoldInterval
    case CleanupValues
    case AnimatingPour
}

class TestTubeScene : Scene {
    var measureTube: TestTube?
    var tubeGrid: [ TestTube ] = []
    var reservoirs: [ ReservoirObject ] = []
    var buttons: [ BoxButton ] = []
    
    var debugQuad: GameObject!
    
    var tubeLevel: TubeLevel!
    
    var buttonPressed: ButtonActions?

    // message text
    let defaultMessageDelay: Float = 1.1
    private var _messageDelay: Float = 0.0
    private var isMessageShowing = false
    var messageText: TextObject?
    var currentMessageLabel: TextLabelTypes? {
        didSet {
            if( messageText == nil ){
                if currentMessageLabel != nil {
                _messageDelay = defaultMessageDelay
                messageText = TextLabels.Get( currentMessageLabel! )
                    messageText?.setBoxPos( box2DOrigin )
                addChild(messageText!)
                isMessageShowing = true
                }
            }  else {
                removeChild(messageText!)
                messageText = nil
            }
        }
    }
    
    // MARK: top level states
    var isPlaying = false
    var isWaitingToFill = false {
        didSet { _askForLiquidDelay = defaultAskForLiquidDelay }
    }
    var isGridFilling: Bool = false
    var isZooming = false { didSet { _currentZoom = (currentCamera as? OrthoCamera)?.getFrameSize() ?? 1.0 } }
    var isGridEmptying = false
    var fillQueued = false // for refilling automatically
    
    // tube emptying
    private var _emptyDuration: Float = 1.0
    private let defaultEmptyTime: Float = 1.0
    
    //collision thresholding and geometries
    private var collisionThresh: Float = 0.3
    private var tubeHeight: Float = 0.0 // can determine at run time
    private var tubeWidth : Float = 0.18
    // tube filling
    
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
    
    // pipe fill animation constants
    let defaultAskForLiquidDelay: Float = 1.5
    private var _askForLiquidDelay: Float = 0.0
    
    // zoom when done initializing
    let defaultZoom: Float = 1.0
    let largeZoom: Float = 1.5
    private var _currentZoom: Float = 2.0
    
    //geometry
    let tubeDimensions: float2 = float2(0.4,1)
    
    private var touchStatus: States = .Filling
    
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
    
    var timeCounter: TextObject!
    var scoreCounter: TextObject!
    var levelTime: Int = 0 {
        didSet {
            let seconds = levelTime % 60
            let minutes = Int(floor( Float(levelTime) / 60 ))
            if minutes > 0 {
                timeCounter?.setText("time: \(minutes)m \(seconds)s")
            } else {
                timeCounter?.setText("time: \(seconds)s")
            }
        }
    }
    var levelScore: Int = 0 {
        didSet {
            scoreCounter?.setText("score: \(levelScore)")
        }
    }
    
    var isShowingCleanDescription = false {
        didSet {
            guard let label = cleanBugLabel else { return }
            if( isShowingCleanDescription ) {
                addChild(label)
            } else {
               removeChild(label) //MARK: maybe unsafe
            }
        }
    }
    var cleanBugLabel: TextObject!
    
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
       
        (currentCamera as? OrthoCamera)?.setFrameSize( largeZoom )
        addTestButton()
        InitializeGrid()
        addCounters()
        
        cleanBugLabel = TextLabels.Get(.CleanDescription)
        cleanBugLabel.setBoxPos( box2DOrigin )
    }
    
    
    
    func addTestButton() {
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(1.5,4.0), label: .MenuLabel, scale: 1.1)
        let startButton = BoxButton(.Menu, .Menu, .StartGameAction, center: box2DOrigin + float2(-1.5,4.0), label: .StartGameLabel, scale: 1.1)
        let cleanButton = BoxButton(.Menu, .Menu, .Clear, center: box2DOrigin + float2(-1.5,3), label: .TestLabel2, scale: 1.2 )
        buttons.append(menuButton)
        buttons.append(startButton)
        buttons.append(cleanButton)
        
        addChild(menuButton)
        addChild(startButton)
        addChild(cleanButton)
    }
    
    func addCounters() {
        timeCounter = TextLabels.Get(.LevelTimeLabel)
        scoreCounter = TextLabels.Get(.LevelScoreLabel)
        let timeCenter =  box2DOrigin + float2(0,4.0)
        let scoreCenter =  box2DOrigin + float2(0,3.5)
        timeCounter.setBoxPos(timeCenter)
        scoreCounter.setBoxPos(scoreCenter)
        self.addChild(timeCounter)
        self.addChild(scoreCounter)
    }
    
    func destroyReservoirs() {
        for t in tubeGrid {
            t.destroyPipes()
        }
        for i in 0..<reservoirs.count {
            removeChild(reservoirs[i])
        }
        reservoirs = []
    }
    
    func reservoirAction() {
        destroyReservoirs()
        var colorVariety: [TubeColors] = []
        var colorsToTubeIndices: [TubeColors:[Int] ] = [:]
        var  reservoirForColor: [TubeColors:ReservoirObject] = [:]
        for tube in tubeGrid { // figure out how many different colors we need based on curr colors
            for color in tube.newColors {
                if( !colorVariety.contains(color) && (color != .Empty) ) { // get every color
                    colorVariety.append(color)
                }
            }
        }
        // now update the dictionary using each color value to see which test tubes needs a pipe.
        for color in colorVariety {
            // (there won't be .Empty color in colorVariety)
            var tubeIndicesForThisColor: [Int] = []
            for tube in tubeGrid {
                for tubeColor in tube.newColors {
                    if color == tubeColor {
                        if !( tubeIndicesForThisColor.contains( tube.gridId) ) { // no repeats!
                        tubeIndicesForThisColor.append( tube.gridId )
                        }
                    }
                }
            }
            colorsToTubeIndices.updateValue( tubeIndicesForThisColor, forKey: color)
        }
    
        let reservoirSpacing = float2(2.0, 4.0)
        let reservoirOffset = float2(0, 4.0) + box2DOrigin
        let reservoirCount = colorVariety.count // need a reservoir for each color.
        let reservoirPositions = CustomMathMethods.positionsMatrix( reservoirOffset, withSpacing: reservoirSpacing, rowLength: 4, totalCount: reservoirCount)
        var colorIndex = 0
        for pos in reservoirPositions.grid {
            if let goodPos = pos {
                if colorIndex > colorVariety.count - 1 { print("reservoir placing WARN::index greater than num colors."); break}
                let color = colorVariety[colorIndex]
                let newReservoir = ReservoirObject(origin: goodPos, colorType: color )
                newReservoir.fill()
                reservoirs.append( newReservoir )
                addChild( newReservoir )
                reservoirForColor.updateValue(newReservoir, forKey: color)
                colorIndex += 1
            }
        }
        if( colorIndex != colorVariety.count) { print("reservoir placing WARN::num colors not matching reservoirs made."); }
//        var targetsDict: [ TubeColors: [float2] ] = [:]
        for color in colorVariety {
            var currTargets: [float2] = []
            guard let indicesForThisColor = colorsToTubeIndices[ color ]
            else {
                print("reservoir action WARN::there was supposed to be indices for this color")
                break
            }
            for ind in indicesForThisColor {
                currTargets.append(tubeGrid[ind].getBoxPosition() + float2(0,0))
            }
//            targetsDict.updateValue(currTargets, forKey: color)
            reservoirForColor[ color ]!.targets = currTargets
        }
        for (color, indices) in colorsToTubeIndices {
            let currReservoir = reservoirForColor[ color ]
            var currTubes: [TestTube] = []
            for i in 0..<indices.count {
                currTubes.append(tubeGrid[ colorsToTubeIndices[color]![i] ])
            }
            currReservoir?.buildPipes( currTubes )
            currReservoir?.fill()
        }
        for r in reservoirs {
            r.toggleTop()
        }
    }
    
    private func InitializeGrid() {
        if( measureTube == nil ) {
            measureTube = TestTube()
        }
        let xSep : Float = measureTube!.getTubeWidth() * 1.4
        let ySep : Float = measureTube!.getTubeHeight() * 1.1
        if( measureTube != nil ) {
            measureTube = nil
        }
        var tGid = 0
        let startLvl = tubeLevel.startingLevel
        let tubesCenter = float2(0,-2)
        let tubePositionsMatrix = CustomMathMethods.positionsMatrix(box2DOrigin + tubesCenter, withSpacing: float2(xSep, ySep), rowLength: 6, totalCount: startLvl.count)
        for position in tubePositionsMatrix.grid {
            if let goodPos = position {
                if tGid > startLvl.count - 1 { print("init tubegrid WARN::matrix index greater than starting lvl count."); break}
                let currentTube = TestTube(origin: goodPos, gridId: tGid, startingColors: startLvl[tGid])
                addChild(currentTube)
                tubeGrid.append(currentTube)
                tGid += 1
            }
        }
        if( tGid != startLvl.count) { print("init tubegrid WARN::tube num not matching starting lvl count."); }
    }
    
    private func beginEmpty() {
        _emptyKF = 0
        tubeIsActive = false
        _emptyDuration = defaultEmptyTime
        isGridEmptying = true
        touchStatus = .Emptying
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
            isGridEmptying = false
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
        touchStatus = .AnimatingPour
        var newPouringTubeColors = [TubeColors].init(repeating: .Empty, count: 4)
        var newCandidateTubeColors = [TubeColors].init(repeating: .Empty, count: 4)
        
        (newPouringTubeColors, newCandidateTubeColors) = tubeLevel.pourTube(pouringTubeIndex: self.selectedTube!.gridId, pourCandidateIndex: self.pourCandidate!.gridId)
        self.selectedTube!.startPouring( newPourTubeColors: newPouringTubeColors,
                                         newCandidateTubeColors: newCandidateTubeColors,
                                         cTube: self.pourCandidate)
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
                    touchStatus = .Idle
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
        selectedTube?.reCaptured = false
        selectedTube?.returnToOrigin()
        selectedTube = nil
        _holdDelay = _defaultHoldTime
        touchStatus = .Idle
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
        
        for node in children {
            if let testableNode = node as? Testable {
                testableNode.touchesBegan(boxPos)
            }
        }
        
        if buttonPressed != nil {
            playHaptic()
            if buttonPressed == .Clear {
                isShowingCleanDescription = true
            }
        }
        
        FluidEnvironment.Environment.debugParticleDraw(atPosition: Touches.GetBoxPos())
    
        switch touchStatus {
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
                touchStatus = .Filling
            }
        case .Filling:
            var oneFilling = false
            for tube in tubeGrid {
                oneFilling = (tube.isEmptying || oneFilling)
            }
            if !oneFilling {
                touchStatus = .Idle
            }
        case .Selected:
            guard let nodeAt = kineticHitTest() else {
                unSelect()
                return
            }
            if nodeAt.gridId == selectedTube?.gridId { // we clicked the same selected tube
                unSelect()
            } else { // pour into nodeAt
                pourCandidate = nodeAt
                if !(tubeLevel.pourConflict(pouringTubeIndex: selectedTube?.gridId ?? -1, pouringCandidateIndex: nodeAt.gridId ) ) && (nodeAt.currentState == .AtRest){
                    pourTubes()
                    touchStatus = .Idle
                } else { // red highlights Flash
                    currentMessageLabel = .TubeRejectLabel
                    pourCandidate?.conflict()
                    unSelect()
                }
            }
        case .Idle: // here's where grabbing during returning can take place.
            guard let nodeAt = boxHitTest(boxPos: Touches.GetBoxPos(), excludeDragging: -1) else {
                unSelect();
                return
            }
            if nodeAt.currentState == .AtRest {
                selectedTube = nodeAt
                selectedTube?.select()
                touchStatus = .HoldInterval
                _holdDelay = _defaultHoldTime
            } else if nodeAt.currentState == .ReturningToOrigin {
                selectedTube = nodeAt
                selectedTube?.select()
                selectedTube?.reCaptured = true  // hard interrupts origin return
                touchStatus = .HoldInterval
                _holdDelay = _defaultHoldTime
            }
        default:
            print("nothing to do")
        }
    }
    
    func startGame() {
        reservoirAction()
        isWaitingToFill = true
    }
    
    func emptyTubes() {
        for tube in tubeGrid {
            tube.BeginEmpty()
        }
        touchStatus = .Emptying
    }
    
    func rePourTubes() {
        isGridEmptying = true
        fillQueued = true
        emptyTubes()
    }
    
    
    func doButtonAction() {
        if( buttonPressed != nil ) {
            switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
            case .None:
                print("let go of a button")
            case .Clear:
               rePourTubes()
            case .ToMenu:
                SceneManager.sceneSwitchingTo = .Menu
                SceneManager.Get( .Menu ).unFreeze()
            case .StartGameAction:
                startGame()
            case .TestAction1:
                emptyTubes()
            case .TestAction2:
                break
            case .TestAction3:
                destroyReservoirs()
            case nil:
                print("let go of no button")
            default:
                print("Button Action ADVISE::need \(boxButtonHitTest(boxPos: Touches.GetBoxPos())) action.")
                break
            }
        }
    }
    
    func StartGridPipeFill() {
        for tube in tubeGrid {
            tube.startPipeFill()
        }
    }
    
    func StartGridFastFill() {
        for tube in tubeGrid {
            tube.startFastFill()
        }
    }
    
    override func touchesEnded() {
        
        doButtonAction()
        
        if buttonPressed == .Clear {
            isShowingCleanDescription = false
        }
        buttonPressed = nil
        
        for b in buttons {
            b.deSelect()
        }
        switch touchStatus {
        case .HoldInterval:
            if _holdDelay > 0.0 {
                selectedTube?.currentState = .Selected
                touchStatus = .Selected
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
   
    var _miliSeconds: Float = 1.0
    override func update(deltaTime : Float) {
        super.update(deltaTime: deltaTime)
        
        if isMessageShowing {
            if( _messageDelay > 0.0 ) {
            _messageDelay -= deltaTime
            } else {
                isMessageShowing = false
                currentMessageLabel = nil
            }
        }
       
        if isWaitingToFill {
            if( _askForLiquidDelay > 0.0 ){
                _askForLiquidDelay -= deltaTime
            } else {
                isWaitingToFill = false
                isGridFilling = true
                if( isPlaying ) { // in progress, dont repeat animation, just fill them.
                    StartGridFastFill()
                } else {
                    StartGridPipeFill()
                }
            }
        }
        
        if isGridFilling {
            var stillFilling = false
            for t in tubeGrid {
                stillFilling = stillFilling || t.isInitialFilling
            }
            if !stillFilling {
                isGridFilling = false
                isZooming = true
            }
        }
        
        if isGridEmptying {
            var stillEmptying = false
            for t in tubeGrid {
                stillEmptying = stillEmptying || t.isEmptying
            }
            if !stillEmptying {
                isGridEmptying = false
                isZooming = true && !fillQueued
                isWaitingToFill = fillQueued
                fillQueued = false
            }
        }
        
        if isZooming  {
            if( _currentZoom > defaultZoom ) {
                _currentZoom -= deltaTime
                (currentCamera as? OrthoCamera)?.setFrameSize( _currentZoom )
            } else {
                isZooming = false
                isPlaying = true
                _miliSeconds = 1.0
                destroyReservoirs()
            }
        }
        
        if isPlaying {
            if(_miliSeconds > 0.0 ) {
                _miliSeconds -= deltaTime
            } else {
                levelTime += 1
                _miliSeconds = 1.0
            }
        }
        
        if (Touches.IsDragging) {
            if buttonPressed != nil {
                buttonPressed = boxButtonHitTest(boxPos: Touches.GetBoxPos())
                if buttonPressed == nil {
                    for b in buttons {
                        b.deSelect()
                        isShowingCleanDescription = false
                    }
                }
            }
            switch touchStatus {
            case .HoldInterval:
                if _holdDelay == _defaultHoldTime {
                    selectedTube?.select()
                }
                if _holdDelay >= 0.0 {
                    _holdDelay -= deltaTime
                }
                else {
                    touchStatus = .Moving
                }
            case .Moving:
                let boxPos = Touches.GetBoxPos()
                selectedTube?.moveToCursor(boxPos)
                guard let selectId = selectedTube?.gridId else { return }
                hoverSelect(boxPos, deltaTime: deltaTime, excludeMoving: selectId)
            default:
                break
                print("current scene state: \(touchStatus)")
            }
            
            for n in children {
                if let testableNode = n as? Testable {
                    testableNode.touchDragged(Touches.GetBoxPos())
                }
            }
        }
    }
}

