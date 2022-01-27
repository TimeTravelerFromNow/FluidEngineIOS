import MetalKit



class TestTubeScene : Scene {
        
    var backGroundObject = CloudsBackground()
    var fluidObject: DebugEnvironment!

    //var tubeGrid: [ TestTube ] = []
    var tubes: TestTubeMatrix!
    
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
        
    override func buildScene(){
        self.removeChildren()
        tubeLevel = TubeLevel()
        cameras.append( OrthoCamera())
        cameras[0].setPositionZ(1.78)
        
        sceneSizeWillChange()
        self.currentCamera = cameras[1]

        fluidObject = DebugEnvironment()
        fluidObject.setScale(2 / (GameSettings.ptmRatio * 10) )
        fluidObject.setPositionZ(2)
        
        InitializeGrid()
        for y in 0..<tubes.rows {
            for x in 0..<tubes.columns {
            addChild(tubes[y,x])
        }
        }
        addChild(fluidObject)
        addChild(backGroundObject)
        backGroundObject.setPosition(float3(0.5 * GameSettings.pxPtsR,0.5 * GameSettings.pxPtsR,2))
        backGroundObject.setScale(GameSettings.pxPtsR)
    }
    override func sceneSizeWillChange() {
        for camera in cameras {
            camera.aspect = GameSettings.AspectRatio
            if let cam = camera as? OrthoCamera {
                cam.setFrameSize(0.5)
                } else {
                
                }
            }
        cameras[1].setPosition(float3((Renderer.ScreenSize.x * 0.25) / (1080.0  ),(Renderer.ScreenSize.y * 0.25 ) / 1080.0,0.0) )
    }
    let leftStart: Float = 0.5
    private let _ySep : Float = 2.0
    private let _xSep : Float = 0.8

    private var _gridHeight : Float = 3.5
    private var _gridWidth  : Float = 2.5
    private func InitializeGrid() {
        let colNum = tubeLevel.startingLevel.columns
        let rowNum = tubeLevel.startingLevel.rows
        tubes = TestTubeMatrix(rows: rowNum,
                               columns: colNum,
                               defaultValue: TestTube(origin: float2(0,0), row: -1, col: -1, gridId: -1))
        var linOff = 0
        for y in 0..<rowNum {
            for x in 0..<colNum {
                if( tubeLevel.startingLevel[y,x].count > 0) {
                    tubes[y,x] = TestTube(origin: float2(x:_xSep * Float(x) + leftStart,y:_ySep * Float(y + 1)),
                                          row: y, col: x,
                                          gridId: linOff)
                    tubes[y,x].setupTube()
                    self.addChild(tubes[y,x].sceneRepresentation)
                    self.tubeHeight = tubes[y,x].getTubeHeight()
                }
                linOff += 1
            }
        }
        refillTubesToCurrentState()
    }
    //fill from bottom to top
    private var levelFilling: Int = 0
    private func refillTubesToCurrentState() {
        tubesFilled = []
        levelFilling = 0
        _currentState = .Filling
    }
    var rowScanned: Int = 0
    var tubesFilled: [long2] = []
    private func refillStep(_ deltaTime: Float){
        // fill each row until done
        var oneFilling = false
            for col in 0..<tubes.columns {
                let fillPos = long2(levelFilling, col)
                if !(tubesFilled.contains(fillPos)) {
                    tubesFilled.append(fillPos)
                    if tubes[fillPos.x, fillPos.y].hasInitialized {
                        tubes[fillPos.x,fillPos.y].startFill(colors: tubeLevel.colorStates[fillPos.x,fillPos.y] )
                }
                }
                oneFilling = oneFilling || tubes[fillPos.x,fillPos.y].isFilling
            }
            if !oneFilling {
                if levelFilling < tubes.rows - 1 {
                levelFilling += 1
                } else {
                    _currentState = .Idle
                }
            }
        
    }
    
    private func beginEmpty() {
        tubeIsActive = false
        _emptyDuration = defaultEmptyTime
        emptyingTubes = true
    }
    
    private var _emptyKF = 0
    private func EmptyTubesStep(_ deltaTime: Float) {
        switch _emptyKF{
        case 0: // empty evens
            for  (i,tube) in tubes.grid.enumerated() {
                if (i % 2 == 0 ) {
                tube.BeginEmpty()
                }
            }
            nextEmptyKF()
        case 1:   // wait to finish pouring
            if _emptyDuration > 0.0 {
                _emptyDuration -= deltaTime
            } else {
                nextEmptyKF()
            }
        case 2:  // empty odds
            for  (i,tube) in tubes.grid.enumerated() {
                if (i % 1 == 0 ) && i != 0 {
                    
                tube.BeginEmpty()
                }
            }
            nextEmptyKF()
        case 3:  // wait again
            if _emptyDuration > 0.0 {
                _emptyDuration -= deltaTime
            } else {
                nextEmptyKF()
            }
        case 4:  // done
            emptyingTubes = false
        default :
            print("unknown scene empty keyframe \(_emptyKF) ")
        }
    }
    
    private func nextEmptyKF() {
        _emptyDuration = defaultEmptyTime
        _emptyKF += 1
    }
    
    private func gridHitTest( windowPosition: float2, excludeDragging: long2 ) -> TestTube? {
        let boxPosition = windowPosition / GameSettings.ptmRatio
        for tube in tubes.grid {
            if !( long2(tube.row, tube.column) == excludeDragging) {
                let tPos = tube.getBoxPosition()
                if( ( (-tubeDimensions.x + tPos.x)  < boxPosition.x && boxPosition.x < (tubeDimensions.x + tPos.x) ) &&
                        ( (-tubeDimensions.y + tPos.y)  < boxPosition.y && boxPosition.y < (tubeDimensions.y + tPos.y) ) ) {
                        return tube
                    }
            }
        }
        return nil
    }
    
    private func kineticHitTest( windowPosition: float2 ) -> TestTube? { // tests based on current location
        let boxPosition = windowPosition / GameSettings.ptmRatio
        print(boxPosition)
        for tube in tubes.grid {
            if( ( ((-tubeDimensions.x + tube.getBoxPositionX())  < boxPosition.x) && (boxPosition.x < (tubeDimensions.x + tube.getBoxPositionX()) )) &&
                    ( ((-tubeDimensions.y + tube.getBoxPositionY())  < boxPosition.y) && (boxPosition.y < (tubeDimensions.y + tube.getBoxPositionY()) )) ) {
                        return tube
                    }
        }
        return nil
    }
    
    func pourTubes() {
        self.selectedTube!.setCandidateTube( self.pourCandidate! )
        var newPouringTubeColors = [TubeColors].init(repeating: .Empty, count: 4)
        var newCandidateTubeColors = [TubeColors].init(repeating: .Empty, count: 4)

        (newPouringTubeColors, newCandidateTubeColors) = tubeLevel.pourTube(
            pourPos: long2(selectedTube!.row, selectedTube!.column),
            candPos: long2(pourCandidate!.row, pourCandidate!.column)
        )
        self.selectedTube!.startPouring( newPourTubeColors: newPouringTubeColors,
                                         newCandidateTubeColors: newCandidateTubeColors)
    }
    
    func hoverSelect(_ windowPos: float2, deltaTime: Float, excludeMoving: long2) {
        guard let tubeHovering = gridHitTest(windowPosition: windowPos, excludeDragging: excludeMoving ) else
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
            let candidatePosition = long2(pourCandidate!.row, pourCandidate!.column)
            
            if !(tubeLevel.pourConflict(pourPos: excludeMoving, candPos: candidatePosition) ){
                print("no conflict")
                startedHovering = true
                _selectorTime = hoverSelectTime
            } else { startedHovering = false }
        }
    }
    
    enum States {
        case Moving
        case Emptying
        case Filling
        case Selected
        case Idle
        case HoldInterval
        case CleanupValues
    }
    private var _currentState: States = .Filling
      
    private var _holdDelay: Float = 0.2
    private let _defaultHoldTime: Float = 0.2
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Name:\t\(UIDevice.current.name)")
          print("Size:\t\(UIScreen.main.bounds.size)")
          print("Scale:\t\(UIScreen.main.scale)")
          print("Native:\t\(UIScreen.main.nativeBounds.size)")
        let touchPosCG = touches.first?.location(in: nil)
        print(touchPosCG)
        let touchPos = float2( Float(touchPosCG!.x) * GameSettings.pxTchR * 0.5, Float(UIScreen.main.bounds.size.height - touchPosCG!.y ) * GameSettings.pxTchR * 0.5)
        print(touchPos)
        switch _currentState {
        case .HoldInterval:
        print("grabbed tube, determining hold status")
            selectedTube?.select()
        case .Moving: // use hover code
            print("grabbed tube")
            selectedTube?.moveToCursor(touchPos)
        case .Emptying:
            var oneEmptying = false
            for tube in tubes.grid {
                oneEmptying = (tube.isEmptying || oneEmptying)
            }
            if !oneEmptying {
                _currentState = .Filling
            }
        case .Filling:
            var oneFilling = false
            for tube in tubes.grid {
                oneFilling = (tube.isEmptying || oneFilling)
            }
            if !oneFilling {
                _currentState = .Idle
            }
        case .Selected:
            guard let nodeAt = kineticHitTest(windowPosition: touchPos) else {
                unSelect()
                return
            }
            if nodeAt.gridId == selectedTube?.gridId {
                _currentState = .Moving
            } else { // pour into nodeAt
                pourCandidate = nodeAt
                if !(tubeLevel.pourConflict(pourPos: long2(selectedTube?.row ?? -1, selectedTube?.column ?? -1), candPos: long2(nodeAt.row, nodeAt.column) ) ) && (nodeAt.currentState == .AtRest){
                    pourTubes()
                    _currentState = .Idle
                } else { // red highlights Flash
                    pourCandidate?.conflict()
                    unSelect()
                }
            }
        case .Idle:
            guard let nodeAt = gridHitTest(windowPosition: touchPos, excludeDragging: long2(-1,1)) else { return }
            if nodeAt.currentState == .AtRest {
            selectedTube = nodeAt
            selectedTube?.select()
            _currentState = .HoldInterval
            }
        default:
            print("nothing to do")
        }
    }
//    
//    override func keyDown() {
//        if( KeyBoard.IsKeyPressed(.m)){
//            currentCamera = cameras[0]
////            cameras[0].setRotationY(Float.pi)
//        }
//        if( KeyBoard.IsKeyPressed(.o)){
//            currentCamera = cameras[1]
//            
//        }
//        if( KeyBoard.IsKeyPressed(.upArrow)) {
//            fluidObject.movePointTest(velocity: float2(0,1.0))
//        }
//        if( KeyBoard.IsKeyPressed(.downArrow)) {
//            fluidObject.movePointTest(velocity: float2(0,-1.0))
//        }
//    }
//    
//    override func scrollWheel() {
//        currentCamera.moveZ(Mouse.GetDWheel())
//    }
//    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
//    
    func unSelect() {
        print("let go of tube")
        selectedTube?.returnToOrigin()
        selectedTube = nil
                    _holdDelay = _defaultHoldTime
            _currentState = .Idle
    }
//    
    override func update(deltaTime : Float) {
        super.update(deltaTime: deltaTime)
        if _currentState == .Filling {
            refillStep(deltaTime)
        }
//
//        if (Mouse.IsMouseButtonPressed(button: .left)) {
//        switch _currentState {
//        case .HoldInterval:
//            if _holdDelay == _defaultHoldTime {
//                selectedTube?.select()
//            }
//                    if _holdDelay >= 0.0 {
//                        _holdDelay -= deltaTime
//                    }
//                    else {
//                        _currentState = .Moving
//                    }
//        case .Moving:
//            let winPos = touchPos
//            selectedTube?.moveToCursor(winPos)
//            guard let selectId = selectedTube?.gridId else { return }
//            hoverSelect(winPos, deltaTime: deltaTime, excludeMoving: selectId)
//        default:
//            print("current scene state: \(_currentState)")
//        }
        }
//    }
//    
}

