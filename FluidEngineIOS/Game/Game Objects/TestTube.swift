import MetalKit

enum TestTubeStates {
    case AtRest
    case Emptying
    case Initializing
    case Pouring
    case Moving
    case ReturningToOrigin
    case CleanupValues
    case Selected
    case Reject
}

class TestTube: Node {
    var currentState: TestTubeStates = .AtRest
    var gridId: Int!
    
    var particleCount: Int = 0
    var origin : float2!
    //emptying
    private var _emptyIncrement: Float = 0.8
    private let _emptyDelay: Float = 0.8
    var isEmptying = false
    var emptyKeyFrame = 0
    // initial pour animation
    var isInitialFilling = true
    var timeToSkim : Float = GameSettings.CapPlaceDelay
    private let capPlaceDelay : Float = GameSettings.CapPlaceDelay
    var particleGroupPlaced = false
    private var _colorsFilled : [TubeColors] = []
    private let _groupScaleY: Float = GameSettings.GroupScaleY // factors to multiply fluid box dimensions by
    private let _groupScaleX: Float = GameSettings.GroupScaleX
    //pouring mechanics variables, consider refactoring into keyframing
    private var _pourDirection: Float = -1
    private var _pourSpeed: Float =  GameSettings.PourSpeed
    private let pourSpeedDefault: Float = GameSettings.PourSpeed
    var isPouring: Bool = false                     // is the one pouring
    var systemPouringInto: UnsafeMutableRawPointer!
    var isPourCandidate: Bool = false               // is being poured into?
    var candidateTube: TestTube!
    private var _pourKF:Int = 0
    private var _guidePositions:  [Vector2D] = []
    private var _guideReferences: [Int:UnsafeMutableRawPointer?] = [0:nil,1:nil]

    var donePouring: Bool = false                   // done with entire pour action (including going back to origin)?
    //moving
    var beingMoved = false // stores whether the tube has been recently touched, could be returning to origin, but this allows it to be re-grabbable if true.
    var topSquareSpeed: Float = 3.0
    private var isActive: Bool = true
    var settling: Bool = false // so the water can settle before freezing.
    
    var waterColor: float4 = float4(0.5,0.1,0.3,1.0)
    var setFrozenDelay: Float = 0.1
    private var _settleDelay: Float = 0.1
    
    private var ptmRatio: Float!

    private var _tube: UnsafeMutableRawPointer!
    var particleSystem: UnsafeMutableRawPointer!
  
    // draw data
    private var _vertexBuffer: MTLBuffer!
    private var _fluidBuffer: MTLBuffer!
    private var _colorBuffer: MTLBuffer!
    //tube geometry
    private var tubeOBJVertices: [Vector2D] = []
    private var tubeHeight: Float32 = 0.4
    private var tubeWidth : Float32 = 0.18
    private let bottomOffset: Float = 0.17 // experimental, simulates uneven taper at bottom.
    private var bottomFromOrigin: Float  { return tubeHeight / 2 - bottomOffset }
    private var _dividerIncrement: Float { return (tubeHeight) / Float(totalColors) }
    //game state related
    private var totalColors: Int = 4//no. cells dont change during game.
    private var _initialFillProgress: Int = 0
    // determine if still needed after C++ refactor
    private var _dividerReferences: [UnsafeMutableRawPointer?]!
    private var _dividerPositions: [ [Vector2D] ]!
    private var _dividerYs : [ Float ]!
    // for handling group destruction
    private var _groupReferences:   UnsafeMutableRawPointer!
    private var _currentColorTypes: [TubeColors] = []
    private var _newColorTypes: [TubeColors] = []
    private var _colors: [float4] = []
    
    //pouring animation constants
    private let _pourAngles: [Float] = [ Float.pi / 1.7,Float.pi/1.8,Float.pi/1.9,Float.pi/2.0]
    private var _pourPositions: [float2] { return [ float2(_pourDirection * tubeWidth * 7, tubeHeight * 1.5), float2(_pourDirection * 0.1, tubeHeight * 1.5) ,float2(_pourDirection * 0.6,tubeHeight * 1.5) , float2(_pourDirection * 0.7,tubeHeight * 1.5)  ] }

    private var _amountToPour: Int = 0
    private var _pourDelay: Float = 0.7
    private let _defaultPourDelay: Float = 0.2
    
    private var _currentTopIndex: Int = 0 // 0 is no cap gameSegments should be top most cap index
    private var _newTopIndex: Int = 0
    // more variables
    private var _previousState: TestTubeStates = .AtRest
    var shouldUpdateRep = false
    private var selectPos: Float { return origin.y + 0.3 }
    // initial filling
    var fullNum: Int = 0
    private var _fillKeyFrame = 0
    // more important accessible variables
    var tubeMesh: Mesh!
    
    var mesh: Mesh!
    
    var modelConstants = ModelConstants()
    
    var sceneRepresentation: TubeVisual!
    
    init( origin: float2, gridId: Int ) {
        super.init()
        self.gridId = gridId
        self.ptmRatio = GameSettings.ptmRatio
        self.origin = origin
        self.tubeMesh = MeshLibrary.Get(.TestTube)
        self.makeContainer()
        self.sceneRepresentation = TubeVisual(tubeHeight + bottomOffset)
    }
    
    //initialization
    private func makeContainer() {
        guard let tubeCustomMesh = tubeMesh else { fatalError("mesh of this tube was nil") }
        (self.tubeOBJVertices, self.tubeHeight) = tubeCustomMesh.getFlatVertices(modelName: "testtube", scale: 50.0)
        self.tubeHeight = self.tubeHeight - bottomOffset
        let tubeVerticesPtr = LiquidFun.getVec2(&tubeOBJVertices, vertexCount: UInt32(tubeOBJVertices.count))
        var sensorVertices : [Vector2D] = [
            Vector2D(x: -tubeWidth, y:  tubeHeight),
            Vector2D(x: -tubeWidth, y: -tubeHeight),
            Vector2D(x: tubeWidth , y: -tubeHeight),
            Vector2D(x: tubeWidth , y:  tubeHeight)
        ]
        let hBE: Float = 0.1 // hit box extent
        let hBD: Float = 0.1 // how far the hitbox is from body
        var hitBoxVertices : [Vector2D] = [
            Vector2D(x: tubeWidth + hBD + hBE, y: tubeHeight * 0.5),
            Vector2D(x: tubeWidth + hBD + hBE, y: -tubeHeight * 0.5),
            Vector2D(x: tubeWidth + hBD, y: -tubeHeight * 0.5),
            Vector2D(x: tubeWidth + hBD, y: tubeHeight * 0.5 ),
            
            Vector2D(x: -(tubeWidth + hBD + hBE), y: tubeHeight * 0.5),
            Vector2D(x: -(tubeWidth + hBD + hBE), y: -tubeHeight * 0.5),
            Vector2D(x: -(tubeWidth  + hBD) , y: -tubeHeight * 0.5),
            Vector2D(x: -(tubeWidth  + hBD) , y: tubeHeight * 0.5 ),
            
            Vector2D(x: tubeWidth  + hBD , y: -tubeHeight * 0.8 + hBE),
            Vector2D(x: -(tubeWidth + hBD), y: -tubeHeight * 0.8 + hBE),
            Vector2D(x: -(tubeWidth + hBD), y: -tubeHeight * 0.8),
            Vector2D(x: tubeWidth  + hBD, y: -tubeHeight * 0.8 )
        ]
        // MARK: I thought sensors weren't needed anymore but we could still use them later for engulfing particle code.
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1,
                                                        density: GameSettings.Density)
        _tube = LiquidFun.makeTube(particleSystem,
                                   location: Vector2D(x:origin.x,y:origin.y),
                                   vertices: tubeVerticesPtr, vertexCount: UInt32(tubeOBJVertices.count),
                                   hitBoxVertices: &hitBoxVertices, hitBoxCount: UInt32(hitBoxVertices.count),
                                   sensorVertices: &sensorVertices, sensorCount: 4,
                                   tubeWidth: tubeWidth,
                                   tubeHeight: tubeHeight,
                                   gridId: gridId)
        
        LiquidFun.setParticleLimitForSystem(particleSystem, maxParticles: GameSettings.MaxParticles)
    }
    
    private func initializeDividerArrays() {
        _dividerPositions = [ [Vector2D] ].init(repeating: [Vector2D(x:0,y:0), Vector2D(x:0,y:0)], count: totalColors)
        _dividerReferences = [UnsafeMutableRawPointer?].init(repeating: nil, count: totalColors)
        _dividerYs = [Float].init(repeating: 0.0, count: totalColors)
    }
    
    private func initializeDividerPositions() {
        for incr in 0..<totalColors {
            let yPos = (_dividerIncrement * Float(incr)) - bottomFromOrigin
            print("before: \(_dividerPositions[incr]) ")
            var dividerVertices = [Vector2D(x: -tubeWidth * 1.3,y:yPos ),
                                   Vector2D(x:  tubeWidth * 1.3,y:yPos ) ]
            _dividerPositions[incr] =  dividerVertices
            print("after: \(_dividerPositions[incr])")
            _dividerYs[incr] = yPos
        }
    }
    
    private func initializeColors(_ colors: [TubeColors]) {
        self.totalColors = colors.count
        self._colors = [float4].init(repeating: WaterColors[.Empty]!, count: totalColors)
        self._currentColorTypes = [TubeColors].init(repeating: .Empty, count: totalColors)

        _currentTopIndex = -1
        for (i,c) in colors.enumerated() {
            if c != .Empty {
                self._currentTopIndex = i // keep setting the top Cap index until we are at an empty color.
            }
            _currentColorTypes[i] = c
        }
        refreshColorBuffer()
    }
    
    //destruction
    deinit {
              LiquidFun.destroyBody(_tube)
    }
    
    override func update(deltaTime: Float) {
        super.update()
        updateModelConstants()
        if shouldUpdateRep {
            sceneRepresentation.update(deltaTime: deltaTime)
            shouldUpdateRep = sceneRepresentation.shouldUpdate
        }
        switch currentState {
        case .Emptying:
            emptyStep(deltaTime)
        case .Initializing:
            initialFillStep(deltaTime)
        case .Pouring:
            if !isPourCandidate {
                pourStep(deltaTime)
            }
        case .Moving:
            setFrozenDelay = _settleDelay
            toForeground()
        case .ReturningToOrigin:
            if !beingMoved {
                if (setFrozenDelay > 0.0) {
                    returnToOriginStep(deltaTime)
                    if self.settling {
                        setFrozenDelay -= deltaTime
                    }
                } else {
                    LiquidFun.updateColors(particleSystem,
                                           colors: &_colors,
                                           yLevels: &_dividerYs,
                                           numLevels: 4)
                    toBackground()
                    currentState = .CleanupValues
                    setFrozenDelay = _settleDelay
                    setBoxVelocity() //bring to stop
                    print("Tube \(gridId) Returned To Origin.")
                }
            }
            else {
                toForeground()
                self.rotateZ(0.0)
                currentState = .Moving  //allows control from outside
            }
        case .Selected:
            selectStep(deltaTime)
        case .CleanupValues:
            self.sceneRepresentation.clearEffect()
            self.rotateZ(0.0)
            self.isInitialFilling = false
            self.isEmptying = false
            self.donePouring = true
            self.beingMoved = false
            self.currentState = .AtRest
        case .AtRest:
            break
        default:
            print("Tube \(gridId) atRest")
        }
    }
    
    // funnel management
    private func addGuidesToCandidate(_ guideAngle: Float) {
        let littleGuideMag: Float = 0.1
        let little = float2(abs(cos(guideAngle - 0.3) * littleGuideMag), abs(sin(guideAngle - 0.3) * littleGuideMag) )
        let bigAng = Float.pi/3 + 0.1
        let bigMag: Float = 1.0
        let big = float2( cos(bigAng) * bigMag, sin(bigAng) * bigMag)
        _guidePositions = [
            Vector2D(x: _pourDirection * (_dividerPositions[totalColors - 1][0].x),
                     y: _dividerPositions[totalColors - 1][0].y) ,

            Vector2D(x: _pourDirection * (_dividerPositions[totalColors - 1][0].x - big.x) ,
                     y:_dividerPositions[totalColors - 1][0].y + big.y),

            Vector2D(x: _pourDirection * (_dividerPositions[totalColors - 1][1].x),
                     y: _dividerPositions[totalColors - 1][1].y) ,

            Vector2D(x: _pourDirection * (_dividerPositions[totalColors - 1][1].x + little.x ),
                     y:_dividerPositions[totalColors - 1][1].y + little.y )
        ]
        LiquidFun.addGuides(_tube, vertices: &_guidePositions)
    }
    private func removeGuidesFromCandidate() {
        LiquidFun.removeGuides(_tube)
    }
    
    // candidate tube functions
    func setCandidateTube(_ candidateTube:TestTube ){
        self.candidateTube = candidateTube
    }
    
    func setFilterOfCandidate() {
        if isPourCandidate {
            LiquidFun.setPourBits(self._tube)
        } else {
            print("you wanted to set pour filter bits on a candidate tube that was not marked as such.")
        }
    }
    
    //begin animations
    func initialFillContainer(colors: [TubeColors] ) {
        self.currentState = .Initializing
        _fillKeyFrame = 0
        timeToSkim = capPlaceDelay
        _initialFillProgress = 0
        initializeColors(colors)
        
        initializeDividerArrays()
        initializeDividerPositions()
        
        self.isInitialFilling = true
        self.currentState = .Initializing
        if particleSystem == nil { print("particle system unitialized before initial fill.")}
    }
    
    func startPouring(newPourTubeColors: [TubeColors], newCandidateTubeColors: [TubeColors]) {
        self.candidateTube.toForeground()
        self._newColorTypes = newPourTubeColors
        self.candidateTube._newColorTypes = newCandidateTubeColors
        
        determinePourDirection()
        
        resetPouringParameters()
        
        calcNewTopIndex()
        self._amountToPour = _currentTopIndex - _newTopIndex
        
        candidateTube.resetCandidateParameters()
        self._pourKF = 0
    }
    
    func determinePourDirection() { // determines from where to pour based on respective origins
        if( candidateTube.origin.x < self.origin.x) {
            _pourDirection = 1
            candidateTube._pourDirection = 1
        } else { _pourDirection = -1
            candidateTube._pourDirection = -1
        }
    }
    
    func resetPouringParameters() {
        self.currentState  = .Pouring
        self.isPourCandidate = false
        self.donePouring = false
        self.isPouring = true
        self._pourDelay = _defaultPourDelay
        self.beingMoved = false
    }
    func resetCandidateParameters() {
        self.currentState = .Pouring
        self.beingMoved = false
        self.isPourCandidate = true
    }
    
    func BeginEmpty() {
        self.rotateZ(0.0)
        print("rotation before empty: \(self.getRotationZ())")
        self.emptyKeyFrame = 0
        self._pourSpeed = pourSpeedDefault
        self.isEmptying = true
        self._emptyIncrement = _emptyDelay
        self.currentState = .Emptying
    }
    
    func select() {
        self.sceneRepresentation.selectEffect(.Selected)
        currentState = .Selected
    }
    
    func conflict() {
        shouldUpdateRep = true
        sceneRepresentation.shouldUpdate = true
        self.sceneRepresentation.conflict()
    }
    
    func returnToOrigin(_ customDelay: Float = 1.0) {
        LiquidFun.clearPourBits(_tube)
        self.sceneRepresentation.clearEffect()
        self.setFrozenDelay = customDelay
        self.isPouring = false
        self.isPourCandidate = false
        self.currentState = .ReturningToOrigin
    }
    
    // dividers
    func refreshDividers() {
        for i in 0..<totalColors {
            if i <= _currentTopIndex {
                if _dividerReferences[i] == nil {
                    print("\(_dividerPositions[i])")
                    var dividerVertices = _dividerPositions[i]
                    _dividerReferences[i] = LiquidFun.addDivider( self._tube, vertices: &dividerVertices )
                }
            } else { // i is larger than the current top index, so remove any dividers here.
                if _currentTopIndex < 0 {
                    print("empty")
                }
                if let dividerRef = _dividerReferences[i] {
                    LiquidFun.removeDivider(self._tube, divider: dividerRef)
                    _dividerReferences[i] = nil
                }
            }
        }
    }
    
    func addDivider() {
            if _currentTopIndex < totalColors + 1{
                _currentTopIndex += 1
            } else {
                print("refreshing Dividers but you tried to add a divider above the max number of gameSegments: \(totalColors).")
            }
        refreshDividers()
    }
    
    func removeDivider() {
        if _currentTopIndex > -1 {
            _currentTopIndex -= 1
        } else {
            print("refreshing Dividers but you tried to remove the divider below index -1 _topCapIndex is at: \(_currentTopIndex).")
        }
        refreshDividers()
    }
    
    func refreshTopIndex() {
        for (i,c) in _currentColorTypes.enumerated() {
            if c != .Empty {
                self._currentTopIndex = i // keep setting the top Cap index until we are at an empty color.
            }
            _currentColorTypes[i] = c
        }
        refreshDividers()
    }
    
    func calcNewTopIndex() {
        _newTopIndex = -1
        for (i,c) in _newColorTypes.enumerated() {
            if c != .Empty {
                self._newTopIndex = i // keep setting the top Cap index until we are at an empty color.
            }
        }
    }
  
    //color management
    func setNewColors() {
        assert(_currentColorTypes.count == _newColorTypes.count)
        _currentColorTypes = _newColorTypes
        refreshColorBuffer()
    }
    
    func refreshColorBuffer() { // sets the _color buffer after pouring or initialization
        for (i,c) in self._currentColorTypes.enumerated() {
            if c == .Empty {
                if _newTopIndex < totalColors - 1 { // ensures stray particles are not gray
                    if _newTopIndex < 0 { return }
                    _colors[i] = WaterColors[ _currentColorTypes[ _newTopIndex ]  ]!
                }
            }
            else {
                _colors[i] = (WaterColors[c] ?? WaterColors[.Empty]!)
            }
        }
    }
    
    // updates the yValues to update colors at levels, really cool effect
    func updateYs(_ angle: Float) {
        for index in 0..<_dividerPositions.count {
            let originalVectors = _dividerPositions[index]
            _dividerYs[index] = getOffsetPosition().y + (originalVectors[0].y ) * abs(cos(angle / 2)  ) - 0.1
            
        }
    }
    
    //emptying animation
    func emptyStep(_ deltaTime: Float) {
        switch emptyKeyFrame {
        case 0:
            while _currentTopIndex > -1 {
                removeDivider()
            }
            if (self.getRotationZ() > -Float.pi / 2 - 0.3) {
                self.rotateZ(-4)
            }
             else {
                self.rotateZ(0.0)
                print("rotation before flowing out: \(self.getRotationZ())")
                nextEmptyKF()
            }
        case 1:
            if(_emptyIncrement > 0.0) {
                _emptyIncrement -= deltaTime
            } else {
                nextEmptyKF()
            }
        case 2:
            if rotateUprightStep(deltaTime: deltaTime, angularVelocity: 10.0) {
            nextEmptyKF()
            }
        case 3:
            beingMoved = false
            LiquidFun.emptyParticleSystem(particleSystem,minTime: 3.0,maxTime: 3.4) // destroy particles
            self.returnToOrigin()
        default:
            print("not supposed to get here (empty animation step \(emptyKeyFrame) not defined).")
        }
    }
    
    // uprighting animation
    func rotateUprightStep(deltaTime: Float, angularVelocity: Float = 40.0) -> Bool { // smart righting (will determine angular change)
        var angV = angularVelocity
        let currRotation = getRotationZ()
        var angularChange = deltaTime * angV
        
        if( abs(getRotationZ()) < 0.01 ) {
            return true
        }
        while( abs(currRotation) < abs(angularChange) ) {
            angV *= 0.9
            angularChange = deltaTime * angV
        }
        if currRotation > 0.0 {
            rotateZ(-angV)
        } else {
            rotateZ(angV)
        }
        
        if( abs(getRotationZ()) < 0.01 ) {
            return true
        }
        
        return false
    }
    
    //pouring animation
    func pourStep(_ deltaTime: Float) {
        self.isPouring = true
        let candidatePosition = float2(x:self.candidateTube.getBoxPositionX(),y:self.candidateTube.getBoxPositionY())
        let currPos = float2(x:self.getBoxPositionX(), y:self.getBoxPositionY())
        switch _pourKF {
        case 0:
            let pos0 =  candidatePosition + float2(_pourDirection * 0.8,0.8)
            if( distance(currPos, pos0) > 1.0) {
                setBoxVelocity( vector(pos0 - currPos, mag: _pourSpeed) )
            } else {
                nextPourKF()
            }
        case 1:
            let pos0 =  candidatePosition + float2(_pourPositions[0].x, _pourPositions[0].y)
            var needsToSlow = false
            let velX = self.getVelocityX()
            let velY = self.getVelocityY()
            if( abs( velX * deltaTime) > abs(pos0.x - currPos.x) )
            {
                self.setBoxVelocityX(velX * 0.98)
                needsToSlow = true
            }
            if( abs(velY * deltaTime) > abs(pos0.y - currPos.y) )
            {
                self.setBoxVelocityY(velY * 0.98)
                needsToSlow = true
            }
            if( !needsToSlow ) {
                self.setBoxVelocity(vector(pos0 - currPos, mag: _pourSpeed) )
            }
            if( distance(currPos, pos0) < 0.1) {
                nextPourKF()
            }
        case 2:
            candidateTube.addGuidesToCandidate(_pourAngles[ _newTopIndex + 1 ]) // MARK: got to fix hardcoding these angles it's not clean code
          
            nextPourKF()
        case 3:
            if( _pourDirection * self.getRotationZ() < _pourAngles[ _newTopIndex + 1 ] ) {
                self.rotateZ(_pourDirection * _pourSpeed * deltaTime * 62)
            } else {
                candidateTube.refreshColorBuffer()
                LiquidFun.setPourBits(_tube)
                candidateTube.setFilterOfCandidate()
                nextPourKF()
            }
        case 4:
            // code out the logic here.  MARK: Refactor idea: (see notes 9/13 5:30pm)
            if _pourDelay > 0.0 {
                _pourDelay -= deltaTime
            } else {
                candidateTube.refreshColorBuffer()
                if _amountToPour > 0 {
                    removeDivider()
                    _amountToPour -= 1
                    _pourDelay = _defaultPourDelay
                } else {
                    nextPourKF() // done with all amounts
                }
            }
        case 5:
            nextPourKF()
        case 6:
            nextPourKF()
        case 7:
            nextPourKF()
        case 8:
            nextPourKF()
        case 9:
            if( _pourDirection * self.getRotationZ() > 0 ) {
                _pourSpeed *= 0.99
                self.rotateZ(-_pourDirection * _pourSpeed * deltaTime * 40 * Float.pi)
            } else {
                nextPourKF()
            }
        case 10:
            candidateTube.removeGuidesFromCandidate()
            candidateTube.returnToOrigin()
            candidateTube.setNewColors()
            candidateTube.engulfParticles( particleSystem )
            self.returnToOrigin()
        default:
            print("default _pourKF: \(_pourKF)")
        }
    }
    
    func returnToOriginStep(_ deltaTime: Float) { // MARK: Maybe refactor
        let currPos = getBoxPosition()
        var moveDirection = float2(x:(origin.x - currPos.x)*2,y: (origin.y - currPos.y)*2)
        
        rotateUprightStep(deltaTime: deltaTime, angularVelocity: 10.0 )
        if( self.withinRange(origin, threshold: 0.05) ) {
            if( (-0.01 > self.getRotationZ()) || (self.getRotationZ() > 0.01)) {
                let rotDirection = -self.getRotationZ() / abs(self.getRotationZ())
                self.rotateZ( rotDirection )
            } else {
                self.setBoxVelocity()
                self.rotateZ(0)
                settling = true }
        } else {
            if self.withinRange(origin, threshold: 0.1) {
                moveDirection = vector(moveDirection, mag: 1.0)
            } else { if self.withinRange(origin, threshold: 1.4) {
                moveDirection = vector(moveDirection, mag: 3.7)
            }}
            if (distance(currPos, origin) > 0.3) {
                moveDirection = vector(moveDirection, mag: 5.7)
            }
            else if (distance(currPos, origin) > 0.1) {
                moveDirection = vector(moveDirection, mag: 2.1)
            }
            else {
                moveDirection = vector(moveDirection, mag: 0.3)
            }
            settling = false
            setBoxVelocity(moveDirection)
        }
    }
    
    func selectStep(_ deltaTime: Float) {
        if (self.getBoxPositionY() < selectPos ) {
            setBoxVelocity(float2(x:0,y:3))
        } else {
            setBoxVelocity()
            currentState = .AtRest
        }
    }
    
    func initialFillStep(_ deltaTime: Float) {
        switch _fillKeyFrame {
        case 0:
            if _initialFillProgress < totalColors {
                let currentColor = _currentColorTypes[_initialFillProgress]
                var color = _colors[_initialFillProgress]
                
                if timeToSkim > 0.0 {
                    if currentColor != .Empty {
                        if !particleGroupPlaced {
                            let yPos = (_dividerIncrement * 1.4 - tubeHeight / 2) + bottomOffset + GameSettings.DropHeight
                            let groupSpawnPosition = Vector2D(x: self.getBoxPositionX(),
                                                              y: self.getBoxPositionY() + yPos - _dividerIncrement/2)
                            let groupSize = Size2D(width: tubeWidth * _groupScaleX,
                                                   height: _groupScaleY * _dividerIncrement)
                            spawnParticleBox(groupSpawnPosition,
                                             groupSize,
                                             color: &color)
                            particleGroupPlaced = true
                            _initialFillProgress += 1
                            
                            timeToSkim = capPlaceDelay
                        }
                    }
                    else {
                        _initialFillProgress += 1
                    }
                    timeToSkim -= deltaTime
                } else {
                    timeToSkim = capPlaceDelay
                    skimTopParticles(_currentTopIndex)                     //delete overflows
                    particleGroupPlaced = false
                }
            }
            else {
                toBackground()
                nextFillKF()
            }
        case 1:
            if timeToSkim > 0.0 {
                timeToSkim -= deltaTime
            }
            else { nextFillKF() }
        case 2:
            skimTopParticles(_currentTopIndex - 1)
            let outsidesDelet = deleteOutside()
            print("deleted \(outsidesDelet) particles outside.")
            self.returnToOrigin()
            updateYs(getRotationZ())
            refreshDividers()
        default:
            print("unknown fill key frame \(_fillKeyFrame)")
        }
    }
    
    // keyframe advances
    func nextFillKF() {
        _fillKeyFrame += 1
        timeToSkim = capPlaceDelay
    }
    
    func nextEmptyKF() {
        emptyKeyFrame += 1
        _pourSpeed = pourSpeedDefault
        _emptyIncrement = _emptyDelay
        self.rotateZ(0.0)
    }
    
    func nextPourKF() {
        _pourDelay = _defaultPourDelay
        _pourSpeed = pourSpeedDefault
        self.rotateZ(0)
        setBoxVelocity()
        _pourKF += 1
    }
    
    // particle management
    func clearTube() {
        LiquidFun.destroyParticles(inSystem: particleSystem)
    }
    
    func engulfParticles(_ originalSystem: UnsafeMutableRawPointer ) {
        LiquidFun.engulfParticles( self._tube, originalParticleSystem: originalSystem )
    }
    func updateColors() {
        LiquidFun.updateColors(particleSystem,
                               colors: &_colors,
                               yLevels: &_dividerYs,
                               numLevels: 4)
    }
    
    func skimTopParticles(_ aboveSegment: Int) {
        let amountDeletedAbove = LiquidFun.deleteParticles(inParticleSystem: particleSystem, aboveYPosition: self.getBoxPositionY() - bottomFromOrigin + Float(aboveSegment + 1)*_dividerIncrement )
        print("deleted overflow amt: \(amountDeletedAbove).")
    }
    
    func deleteOutside() -> Int {
        return Int(LiquidFun.deleteParticlesOutside(particleSystem,
                                                width: tubeWidth,
                                                height: tubeHeight,
                                                rotation: 0.0,
                                                position: Vector2D(x:self.getBoxPositionX(),y:getBoxPositionY())))
    }
    
    func spawnParticleBox(_ position: Vector2D,_ groupSize: Size2D, color: UnsafeMutableRawPointer) {
        LiquidFun.createParticleBox(forSystem: particleSystem,
                                    position: position,
                                    size: groupSize,
                                    color: color)
    }
    
    //buffer updates
    func updateModelConstants() {
        modelConstants.modelMatrix = modelMatrix
        sceneRepresentation.setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        sceneRepresentation.setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        sceneRepresentation.setRotationZ( getRotationZ() )
    }
    
    func refreshVertexBuffer() {
        if particleSystem != nil {
            particleCount = Int(LiquidFun.particleCount(forSystem: particleSystem))
            if particleCount > 0 {
                let positions = LiquidFun.particlePositions(forSystem: particleSystem)
                let bufferSize = float2.stride(particleCount)
                
                let colors = LiquidFun.colorBuffer(forSystem: particleSystem)
                let colorBufferSize = UInt8.Stride(particleCount * 4)
                
                _colorBuffer = Engine.Device.makeBuffer(bytes: colors!, length: colorBufferSize, options: [])
                _vertexBuffer = Engine.Device.makeBuffer(bytes: positions!, length: bufferSize, options: [])
            }
        }
    }
    
    func refreshFluidBuffer () {
        var fluidConstants = FluidConstants(ptmRatio: ptmRatio, pointSize: GameSettings.particleRadius)
        _fluidBuffer = Engine.Device.makeBuffer(bytes: &fluidConstants, length: FluidConstants.size, options: [])
    }
    
    // getters and helpers for position and rotation
    func getTubeAtBox2DPosition(_ position: float2) -> TestTube? {
        if self._tube == LiquidFun.getTubeAtPosition( Vector2D(x: position.x, y:position.y) ){
        return self
        }
        return nil
    }
    
    func getOffsetPosition() -> float2 {
        let o = self.getBoxPosition()
        let ang = -self.getRotationZ()
        return float2(x: -bottomOffset*sin(ang) + o.x, y: -bottomOffset*cos(ang) + o.y)
    }
    
    func unitDirection(_ direction: float2) -> float2 {
        let norm =  (pow(direction.x,2) + pow(direction.y, 2)).invSqrt
        return float2(x: direction.x * norm, y: direction.y * norm)
    }
    
    func vector(_ direction: float2, mag: Float) -> float2 {
        let norm =  (pow(direction.x,2) + pow(direction.y, 2)).invSqrt
        return float2(x: direction.x * mag * norm, y: direction.y * mag * norm)
    }
    
    func distance(_ from: float2, _ to: float2) -> Float{
        let dif = to - from
        return sqrt( pow( (dif).x , 2) + pow( (dif).y, 2) )
    }
    
    func withinRange(_ ofPos: float2, threshold: Float) -> Bool {
        return ((abs(self.getBoxPositionX() - ofPos.x) <= threshold) && (abs(self.getBoxPositionY() - ofPos.y) <= threshold))
    }
    
    override func getRotationZ() -> Float {
        return LiquidFun.getTubeRotation(_tube)
    }
    
    //Movement and rotation
    func moveToCursor(_ boxPos: float2) {
        if !isPouring{
            self.currentState = .Moving
            let currPos = getBoxPosition()
            let moveDirection = float2(x:(boxPos.x - currPos.x) * 3,y: (boxPos.y - currPos.y) * 3)
            setBoxVelocity(moveDirection)
        }
    }
    
    override func moveX(_ delta: Float ) {
        sceneRepresentation.moveX(delta)
    }
    override func moveY(_ delta: Float) {
        sceneRepresentation.moveY(delta)
    }
    override func rotateZ(_ value: Float) {
        LiquidFun.setAngularVelocity(_tube, angularVelocity: value)
        self.sceneRepresentation.setRotationZ(self.getRotationZ())
    }
    func dampRotation( _ value: Float){
        LiquidFun.dampRotation(ofBody: _tube, amount: value)
    }
    func setBoxVelocity(_ velocity: float2 = float2()) {
        LiquidFun.setTubeVelocity(_tube, velocity: Vector2D(x: Float32(velocity.x), y: Float32(velocity.y)))
    }
    func setBoxVelocityX(_ to: Float) {
        let currV = LiquidFun.getTubeVelocity(_tube)
        LiquidFun.setTubeVelocity(_tube, velocity: Vector2D(x: Float32(to), y: Float32(currV.y)))
    }
    func setBoxVelocityY(_ to: Float) {
        let currV = LiquidFun.getTubeVelocity(_tube)
        LiquidFun.setTubeVelocity(_tube, velocity: Vector2D(x: Float32(currV.x), y: Float32(to)))
    }
    
    func getBoxVelocity() -> float2 {
        float2(x: LiquidFun.getTubeVelocity(_tube).x, y: LiquidFun.getTubeVelocity(_tube).y)
    }
    
    func getVelocityX() -> Float {
        return getBoxVelocity().x
    }
    
    func getVelocityY() -> Float {
        return getBoxVelocity().y
    }
    
    func getBoxPosition() -> float2 {
        let boxPos = LiquidFun.getTubePosition(_tube)
        return float2(x: boxPos.x, y: boxPos.y)
    }
    func getBoxPositionX() -> Float {
        return Float(LiquidFun.getTubePosition(_tube).x)
    }
    func getBoxPositionY() -> Float {
        return Float(LiquidFun.getTubePosition(_tube).y)
    }
    func getTubeWidth() -> Float {
        return tubeWidth
    }
    func getTubeHeight() -> Float {
        return tubeHeight
    }

    // zpos for visual effect
    func toForeground() {
        self.setPositionZ(0.15)
        self.sceneRepresentation.setPositionZ(0.15)
    }
    func toBackground() {
        self.setPositionZ(0.1)
        self.sceneRepresentation.setPositionZ(0.1)
    }
}

extension TestTube: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        refreshVertexBuffer()
        refreshFluidBuffer()
        fluidSystemRender(renderCommandEncoder)
    }
    
    func fluidSystemRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if particleCount > 0{
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.ColorFluid))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            
            renderCommandEncoder.setVertexBuffer(_vertexBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBuffer(_fluidBuffer,
                                                 offset: 0,
                                                 index: 3)
            renderCommandEncoder.setVertexBuffer(_colorBuffer,
                                                 offset: 0,
                                                 index: 4)
            
            renderCommandEncoder.setFragmentBytes(&waterColor, length: float4.stride, index: 0)
            renderCommandEncoder.drawPrimitives(type: .point,
                                                vertexStart: 0,
                                                vertexCount: particleCount)
        }
    }
}
