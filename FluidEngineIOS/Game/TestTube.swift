import MetalKit


enum TestTubeStates {
    case AtRest
    case Emptying
    case Initializing
    case Filling
    case Pouring
    case Moving
    case ReturningToOrigin
    case CleanupValues
    case Selected
}
class TestTube: Node {
    var shouldUpdate = false
    private var _frozen = true
    var currentState: TestTubeStates = .Initializing
    var hasInitialized = false // whether or not the Box2D state has been initialized.
    
    var row: Int!
    var column: Int!
    var gridId: Int! // linear offset for unique identification

    var particleCount: Int = 0
    var origin : float2!
//emptying
    private var _emptyIncrement: Float = 0.8
    private let _emptyDelay: Float = 0.8
    var isEmptying = false
    var emptyKeyFrame = 0
    // initial pour animation
    var timeToSkim : Float = GameSettings.CapPlaceDelay
    private let capPlaceDelay : Float = GameSettings.CapPlaceDelay
    var particleGroupPlaced = false
    var isFilling = false
    private var _colorsFilled : [TubeColors] = []
    private var _startingDividerMap : [Bool] = []
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
    private let _pouringDelay: Float = 1.0
    private var _donePouringTime: Float = 2.0
    var donePouring: Bool = false                   // done with entire pour action (including going back to origin)?
    //moving
    var beingMoved = false // stores whether the tube has been recently touched, could be returning to origin, but this allows it to be re-grabbable if true.
    var topSquareSpeed: Float = 3.0
    private var isActive: Bool = true
    var settling :Bool = false // so the water can settle before freezing.
    
    var waterColor: float4 = float4(0.5,0.1,0.3,1.0)
    var setFrozenDelay: Float = 0.1
    private var _settleDelay: Float = 0.1

    private var ptmRatio: Float!
    private var pointSize: Float!
        
    private var _tube: UnsafeMutableRawPointer!
    var particleSystem: UnsafeMutableRawPointer!
    //contact
    var contactBody: UnsafeMutableRawPointer?
    // draw data
    private var _vertexBuffer: MTLBuffer!
    private var _fluidBuffer: MTLBuffer!
    private var _colorBuffer: MTLBuffer!
    //tube geometry
    private var tubeOBJVertices: [Vector2D] = []
    private var tubeHeight: Float = 0.0
    private var tubeWidth : Float = 0.18
    private let bottomOffset: Float = 0.17 // experimental, simulates uneven taper at bottom.
    private var bottomFromOrigin: Float  { return tubeHeight / 2 - bottomOffset }
    private var _dividerIncrement: Float { return (tubeHeight) / Float(gameSegments) }
    //game state related
    private var gameSegments: Int = 4//no. cells dont change during game., Int 8 for size reasons (its small)
    private var segmentsCount: Int = 0
    // won't need after refactor, all handled in Tube C++ class.
    private var _dividerReferences: [Int: UnsafeMutableRawPointer? ] = [:]
    private var _dividerPositions: [ Int : [ Vector2D ] ]  = [:]
    private var _dividerYs : [ Float ]  = []
    // for handling group destruction
    private var _groupReferences:   UnsafeMutableRawPointer!
    private var _colorTypes: [TubeColors] = []
    private var _newColorTypes: [TubeColors] = []
    private var _dividerMap: [Bool] = []     // (whether or not there should be divider for different colors)
    private var _colors: [float4] = []

    var tubeMesh: Mesh!
    
    var modelConstants = ModelConstants()
    
    var sceneRepresentation: TubeRep!
    
    init( origin: float2, color: float4 = float4(0,0,1,1), row: Int, col: Int, gridId: Int) {
        super.init()
        self.row = row
        self.column = col
        self.gridId = gridId
        self.waterColor = color
        self.ptmRatio = GameSettings.ptmRatio
        self.origin = origin
        self.pointSize = 1
        self.tubeMesh = MeshLibrary.Get(.TestTube)
        self.setScale(2 / (GameSettings.ptmRatio * 10) )
        currentState = .Initializing
    }

    deinit {
        if hasInitialized {
            LiquidFun.destroyTube(_tube)
        }
    }
    func yieldToFill() {
        LiquidFun.yield(toFill: _tube)
    }
    func unYieldToFill() {
        LiquidFun.unYield(toFill: _tube)
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
    
    func emptyAnimationStep(_ deltaTime: Float) {
        switch emptyKeyFrame {
        case 0:
            PopCap()
            if ( self.getRotationZ() < 2.09 ) {
                self.rotateZ(_pourSpeed)
            } else {
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
            if ( self.getRotationZ() > 0.0) {
            self.rotateZ(-_pourSpeed)
            }
            else {
                nextEmptyKF()
            }
        case 3:
            beingMoved = false
            LiquidFun.emptyParticleSystem(particleSystem,minTime: 3.0,maxTime: 3.4)
            CapTop()
            self.returnToOrigin()
        default:
            print("not supposed to get here (empty animation step \(emptyKeyFrame) not defined).")
        }
    }
    func nextEmptyKF() {
        emptyKeyFrame += 1
        _pourSpeed = pourSpeedDefault
        _emptyIncrement = _emptyDelay
        self.rotateZ(0.0)
    }
    
    func toForeground() {
        self.setPositionZ(0.8)
        self.sceneRepresentation.setPositionZ(0.9)
    }
    func toBackground() {
        self.setPositionZ(1)
        self.sceneRepresentation.setPositionZ(1.1)
    }
    
    override func update(deltaTime: Float) {
        super.update()
        updateModelConstants()
        if shouldUpdateRep {
            sceneRepresentation.update(deltaTime: deltaTime)
            shouldUpdateRep = sceneRepresentation.shouldUpdate 
        }
        if shouldUpdate {
            _frozen = LiquidFun.isColliding(_tube)
        if !_frozen {
        switch currentState {
        case .Emptying:
            emptyAnimationStep(deltaTime)
        case .Initializing:
            shouldUpdate = false
        case .Filling:
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
                    returnToOriginStep()
                    if self.settling {
                        setFrozenDelay -= deltaTime
                    }
                } else {
                    toBackground()
                    currentState = .CleanupValues
                    setFrozenDelay = _settleDelay
                    boxMove() //bring to stop
                    print("Tube row: \(row) col: \(column) Returned To Origin.")
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
            self.isEmptying = false
            self.donePouring = true
            self.beingMoved = false
            self.currentState = .AtRest
        case .AtRest:
            unYieldToFill()
        LiquidFun.restTube(_tube) // it's done returning to origin,
        LiquidFun.drop(_tube) // it's done returning to origin,
         shouldUpdate  = false
        }
        }}
    }
    var shouldUpdateRep = false
    func select() {
        print("has init \(hasInitialized), \n ")
        self.sceneRepresentation.selectEffect(.Selected)
        shouldUpdateRep = true
        shouldUpdate = true
        currentState = .Selected
    }
    
    func conflict() { // purely visual
        shouldUpdateRep = true
        sceneRepresentation.shouldUpdate = true
        self.sceneRepresentation.conflict()
    }
    
    private var selectPos: Float { return origin.y + 0.3 }
    func selectStep(_ deltaTime: Float) {
        if (self.getBoxPositionY() < selectPos ) {
            updateYs(0.0)
            boxMove(float2(x:0,y:3))
        } else {
            boxMove()
            currentState = .AtRest
        }
    }

    func setCandidateTube(_ candidateTube:TestTube ){
        self.candidateTube = candidateTube
    }
    
    func startPouring(newPourTubeColors: [TubeColors], newCandidateTubeColors: [TubeColors]) {
        shouldUpdate = true
        self.candidateTube.toForeground()
        self._newColorTypes = newPourTubeColors
        self.candidateTube._newColorTypes = newCandidateTubeColors
        if( candidateTube.origin.x < self.origin.x) {
            _pourDirection = 1
            candidateTube._pourDirection = 1
        } else { _pourDirection = -1
            candidateTube._pourDirection = -1
        }
        resetPouringParameters()
        self._amountToPour = 0
        candidateTube.resetCandidateParameters()
        self._pourKF = 0
    }
    
    func resetPouringParameters() {
        LiquidFun.pourTube(_tube)
        LiquidFun.restTube(_tube)
        LiquidFun.drop(_tube)
        self.currentState  = .Pouring
            self.isPourCandidate = false
        self.donePouring = false
        self.isPouring = true
        self._donePouringTime = _pouringDelay
        self.beingMoved = false
    }
    func resetCandidateParameters() {
        LiquidFun.drop(_tube)
        LiquidFun.restTube(_tube)
        self.currentState = .Pouring
        self.beingMoved = false
        self.isPourCandidate = true
    }
    
    private func addGuidesToCandidate(_ guideAngle: Float) {
        let littleGuideMag: Float = 0.1
        let little = float2(abs(cos(guideAngle - 0.3) * littleGuideMag), abs(sin(guideAngle - 0.3) * littleGuideMag) )
        let bigAng = Float.pi/3 + 0.1
        let bigMag: Float = 1.0
        let big = float2( cos(bigAng) * bigMag, sin(bigAng) * bigMag)
        _guidePositions = [
                Vector2D(x: _pourDirection * (_dividerPositions[gameSegments - 1]![0].x), y: _dividerPositions[gameSegments - 1]![0].y) ,
              
                Vector2D(x: _pourDirection * (_dividerPositions[gameSegments - 1]![0].x - big.x) , y:_dividerPositions[gameSegments - 1]![0].y + big.y),
                Vector2D(x: _pourDirection * (_dividerPositions[gameSegments - 1]![1].x),
                                             y: _dividerPositions[gameSegments - 1]![1].y) ,
                Vector2D(x: _pourDirection * (_dividerPositions[gameSegments - 1]![1].x + little.x ), y:_dividerPositions[gameSegments - 1]![1].y + little.y )
            ]
        LiquidFun.addGuides(_tube, vertices: &_guidePositions)
    }
    private func removeGuidesFromCandidate() {
            LiquidFun.removeGuides(_tube)
    }
    
    //pouring animation constants
    private let _pourAngles: [Float] = [ Float.pi / 1.7,Float.pi/2.3,Float.pi/2.5,Float.pi/3]
    private var _pourPositions: [float2] { return [ float2(_pourDirection * 0.1,1.6), float2(_pourDirection * 0.1,1.4) ,float2(_pourDirection * 0.6,1.2) , float2(_pourDirection * 0.7,1.0)  ] }
    private let _maxTransfer: [Int32] = [ 45, 90, 135, 180] // amount of particles to transfer max for each amount (pour is stopped if reached)
    private var _transferredParticleCount: Int32 = 0
    private var _amountToPour: Int = 0
    private var _pourDuration: Float = 0.7
    private let _defPourDuration:Float = 1.0
    //pouring animation
    func pourStep(_ deltaTime: Float) {
        if _amountToPour == 0 {
            _amountToPour = newColorMap()
        }
        let newTop = getTopMostNonEmptyIndex() + 1 // determines the tilt required to remove the layers
        
        self.isPouring = true
        let candidatePosition = float2(x:self.candidateTube.getBoxPositionX(),y:self.candidateTube.getBoxPositionY())
        let currPos = float2(x:self.getBoxPositionX(), y:self.getBoxPositionY())
        switch _pourKF {
        case 0:
            let pos0 =  candidatePosition + float2(_pourDirection * 0.8,0.8)
            if( distance(currPos, pos0) > 1.0) {
                boxMove( vector(pos0 - currPos, mag: _pourSpeed) )
            } else {
             nextKF()
            }
        case 1:
            let pos0 =  candidatePosition + float2(_pourDirection * 0.8,0.8)
            if( distance(currPos, pos0) > 0.1) {
                boxMove(vector(pos0 - currPos, mag: _pourSpeed) )
                _pourSpeed *= 0.98
            } else {
             nextKF()
            }
        case 2:
            candidateTube.addGuidesToCandidate(_pourAngles[newTop]) // make sure only to do 1 time
            nextKF()
        case 3:
            let pos1 = candidatePosition + _pourPositions[newTop]
            if( _pourDirection * self.getRotationZ() < _pourAngles[ newTop ] ) {//< 0.0 ){ //
                _pourSpeed *= 0.99
                self.rotateZ(_pourDirection * _pourSpeed * deltaTime * 20 * Float.pi)
                if( distance(currPos, pos1) > 0.01 ) {
                    boxMove( vector(pos1 - currPos, mag: _pourSpeed/14) )
                } else  {}
            } else {
                    candidateTube.newColorMap()// comment out to see transferred guys as grey
                    candidateTube.setNewColors()
                nextKF()
            }
        case 4:
            LiquidFun.pourTube(candidateTube._tube)
            PopCap()
            candidateTube.PopCap()
            nextKF()
        case 5:
            if( _transferredParticleCount < _maxTransfer[_amountToPour - 1]) {
                _transferredParticleCount += LiquidFun.leavingTube(particleSystem,
                                                                   newSystem: candidateTube.particleSystem,
                                                                   width: tubeWidth,
                                                                   height: tubeHeight * 0.5,
                                                                   rotation: self.getRotationZ(),
                                                                   position: Vector2D(x:self.getOffsetPosition().x,y:self.getOffsetPosition().y))
                _transferredParticleCount -= LiquidFun.backwashingTube(candidateTube.particleSystem,
                                                                   backSystem: particleSystem,
                                                                   width: tubeWidth,
                                                                   height: tubeHeight * 0.4,
                                                                   rotation: self.getRotationZ(),
                                                                   position: Vector2D(x:self.getOffsetPosition().x,y:self.getOffsetPosition().y),
                                                                   color: &_colors[newTop])
                self.rotateZ(_pourDirection * _pourSpeed * deltaTime * Float.pi)
            } else {
                print("finished pouring \(_amountToPour), capping and returning")
                setNewColors()
                nextKF()
            }
        case 6:
            CapTop()
            nextKF()
        case 7:
        if( _pourDuration > 0.0 ) {
            _pourDuration -= deltaTime
        } else {
            nextKF()
        }
        case 8:
            candidateTube.CapTop()
            LiquidFun.startReturnTube(_tube) // give it priority returning.
            nextKF()
        case 9:
            if( _pourDirection * self.getRotationZ() > 0 ) {
               let numcleanedup = LiquidFun.backwashingTube(candidateTube.particleSystem,
                                                                   backSystem: particleSystem,
                                                                   width: tubeWidth,
                                                                   height: tubeHeight * 0.5,
                                                                   rotation: self.getRotationZ(),
                                                                   position: Vector2D(x:self.getOffsetPosition().x,y:self.getOffsetPosition().y),
                                                                   color: &_colors[newTop])
                _pourSpeed *= 0.99
                print("reaccepting particles \(numcleanedup)")
                self.rotateZ(-_pourDirection * _pourSpeed * deltaTime * 40 * Float.pi)
            } else {
                nextKF()
            }
        case 10:
            candidateTube.removeGuidesFromCandidate()
            candidateTube.returnToOrigin()
            self.returnToOrigin()
        default:
            print("default _pourKF: \(_pourKF)")
        }
    }
    func nextKF() {
        _pourDuration = _defPourDuration
        _transferredParticleCount = 0
        _pourSpeed = pourSpeedDefault
        self.rotateZ(0)
        boxMove()
        _pourKF += 1
    }
    
    func getOffsetPosition() -> float2 {
        let o = self.getBoxPosition()
        let ang = -self.getRotationZ()
        return float2(x: -bottomOffset*sin(ang) + o.x, y: -bottomOffset*cos(ang) + o.y)
    }
    
    func getTopMostNonEmptyIndex() ->Int {
        var topIndex : Int = -1
        for (i,c) in _colorTypes.enumerated() {
            if( c != .Empty) {
                topIndex = i
            }
        }
        return topIndex
    }
    
    public func getTopMostTrueBool(_ ofBoolArr: [Bool] ) -> Int {
        var topIndex : Int = -1
        for (i,c) in ofBoolArr.enumerated() {
            if( c ) {
                topIndex = i
            }
        }
        return topIndex
    }
        
    func returnToOrigin(_ customDelay: Float = 1.0) {
        shouldUpdate = true
        LiquidFun.startReturnTube(_tube)
        LiquidFun.endPourTube(_tube)
        LiquidFun.drop(_tube)     // it's not being picked up anymore.
        self.sceneRepresentation.clearEffect()
        self.setFrozenDelay = customDelay
        self.isPouring = false
        self.isPourCandidate = false
        self.currentState = .ReturningToOrigin
    }
    
    func moveToCursor(_ windowPos: float2) {
        if !isPouring{
            shouldUpdate = true
        LiquidFun.pickUp(_tube) // automatic camel casing lmfao
        self.currentState = .Moving
        let boxPos = windowPos / GameSettings.ptmRatio
        let currPos = getBoxPosition()
        let moveDirection = float2(x:(boxPos.x - currPos.x) * 3,y: (boxPos.y - currPos.y) * 3)
        boxMove(moveDirection)
        }
    }
    
    func returnToOriginStep() {
        let currPos = getBoxPosition()
        var moveDirection = float2(x:(origin.x - currPos.x)*2,y: (origin.y - currPos.y)*2)
        if( self.withinRange(origin, threshold: 0.05) ) {
            if( (-0.01 > self.getRotationZ()) || (self.getRotationZ() > 0.01)) {
                let rotDirection = -self.getRotationZ() / abs(self.getRotationZ())
                self.rotateZ( rotDirection )
            } else {
                self.boxMove()
                self.rotateZ(0)
                settling = true }
        } else {
            
                if (distance(currPos, origin) > 0.3) {
                    moveDirection = vector(moveDirection, mag: 5.7)
                } else if (distance(currPos, origin) > 0.1) {
                        moveDirection = vector(moveDirection, mag: 2.1)
                    } else {
                        moveDirection = vector(moveDirection, mag: 0.3)
            }
            settling = false
            boxMove(moveDirection)
        }
    }
    
    func updateModelConstants() {
        modelConstants.modelMatrix = modelMatrix
        if hasInitialized {
        sceneRepresentation.setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        sceneRepresentation.setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        sceneRepresentation.setRotationZ(getRotationZ())
        }
    }
   
    func refreshVertexBuffer() {
        if hasInitialized {
            if currentState != .Initializing && currentState != .Emptying && currentState != .Moving && currentState != .ReturningToOrigin {
            LiquidFun.updateColors(particleSystem,
                                   colors: &_colors,
                                   yLevels: &_dividerYs,
                                   numLevels: 4)
            }
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
    
    private func makeContainer() {
        (self.tubeOBJVertices, self.tubeHeight) = (tubeMesh as! Mesh).getFlatVertices(modelName: "testtube", scale: 30.0)
        self.tubeHeight = self.tubeHeight - bottomOffset
        let jugVerticesPointer = LiquidFun.getVec2(&tubeOBJVertices, vertexCount: UInt32(tubeOBJVertices.count))
        var sensorVertices : [Vector2D] = [
            Vector2D(x: -tubeWidth * 1.7, y:  tubeHeight*0.6),
            Vector2D(x: -tubeWidth * 1.7, y: -tubeHeight*0.9),
            Vector2D(x: tubeWidth  * 1.7, y: -tubeHeight*0.9),
            Vector2D(x: tubeWidth  * 1.7, y:  tubeHeight*0.6)
        ]
        let hBE: Float = 0.2 // hit box extent
        let hBD: Float = 0 // how far the hitbox is from body
        var hitBoxVertices : [Vector2D] = [
            Vector2D(x: tubeWidth + hBD + hBE, y: tubeHeight * 0.5),
            Vector2D(x: tubeWidth + hBD + hBE, y: -tubeHeight * 0.5),
            Vector2D(x: tubeWidth + hBD, y: -tubeHeight * 0.5),
            Vector2D(x: tubeWidth + hBD, y: tubeHeight * 0.5 ),
            
                Vector2D(x: -(tubeWidth + hBD + hBE), y: tubeHeight * 0.5),
                Vector2D(x: -(tubeWidth + hBD + hBE), y: -tubeHeight * 0.5),
                Vector2D(x: -(tubeWidth  + hBD) , y: -tubeHeight * 0.5),
                Vector2D(x: -(tubeWidth  + hBD) , y: tubeHeight * 0.5 ),
            
                Vector2D(x: tubeWidth  + hBD ,      y: -tubeHeight * 0.8 + hBE),
                Vector2D(x: -(tubeWidth + hBD),    y: -tubeHeight * 0.8 + hBE),
                Vector2D(x: -(tubeWidth + hBD) ,     y: -tubeHeight * 0.8),
                Vector2D(x: tubeWidth  + hBD ,      y: -tubeHeight * 0.8 )
        ]
        particleSystem = LiquidFun.createParticleSystem(
            withRadius: GameSettings.particleRadius / ptmRatio, dampingStrength: GameSettings.DampingStrength, gravityScale: 1, density: GameSettings.Density)
        _tube = LiquidFun.makeTube(particleSystem,
                                   location: Vector2D(x:origin.x,y:origin.y),
                                   vertices: jugVerticesPointer, vertexCount: UInt32(tubeOBJVertices.count),
                                   hitBoxVertices: &hitBoxVertices, hitBoxCount: UInt32(hitBoxVertices.count),
                                   sensorVertices: &sensorVertices, sensorCount: 4,
                                   row: Int32(row),
                                   col: Int32(column),
                                   gridId: Int32(gridId!))
  
        LiquidFun.setParticleLimitForSystem(particleSystem, maxParticles: GameSettings.MaxParticles)
        hasInitialized = true
     }
    
    func removeDivider(_ atIndex: Int = -1) { // -1 will simply remove the topmost
        if(atIndex == -1) {
           let topInd = getTopMostTrueBool(_dividerMap)
            if topInd > -1 {
                print("removing divider")
            _dividerMap[topInd] = false
                print(_dividerMap)
            }
        } else {
            _dividerMap[atIndex] = false
        }
    }
    
    func initializeColorsAndDividerMap(_ colors: [TubeColors]) {
        self.gameSegments = 0
        self._colorTypes = []
        let colorsCount = colors.count
        self._colors = [float4].init(repeating: WaterColors[.Empty]!, count: colorsCount)
        self._dividerMap = [Bool].init(repeating: (false), count: colorsCount)
        for (i,c) in colors.enumerated() {
            if i < colorsCount - 1{
                if colors[i] == colors[i + 1] {
                    _dividerMap[i] = false
                } else {
                    _dividerMap[i] = true
                }
            } else
            {
                _dividerMap[i] = (c != TubeColors.Empty)
            }
            _colorTypes.append(c)
            self.gameSegments += 1
        }
        _startingDividerMap = _dividerMap
        self._newColorTypes = _colorTypes
        setNewColors()
    }

    func setNewColors() { // commits visually the divider map change after the pour.
        for (i,c) in self._colorTypes.enumerated() {
            if c == .Empty {
                let topInd = getTopMostNonEmptyIndex()
                if topInd != -1 {
                _colors[i] = WaterColors[ _colorTypes[topInd]  ]!
                }
            }
            else {
                _colors[i] = (WaterColors[c] ?? WaterColors[.Empty]!)
            }
        }
    }
    
    func newColorMap() -> Int  { // only for setting a new divider map,returns how many it needs to pour
        let initialHeight = getTopMostNonEmptyIndex()
        print("old \(_colorTypes)")
        _colorTypes = _newColorTypes
        let finalHeight = getTopMostNonEmptyIndex()
        print("new \(_colorTypes), amount : \(initialHeight - finalHeight)")
        var lastColor = TubeColors.Empty
        var hasReachedEmpty = false
        if _colorTypes.first != .Empty {
            print("nonempty tube")
        for (i,c) in _colorTypes.enumerated() {
            if c == .Empty {
                hasReachedEmpty = true
            }
            if i > 0{
                if c == lastColor {
                    _dividerMap[i - 1] = false
                } else {
                    _dividerMap[i - 1] = true}
            }
            lastColor = c
        }
            if !hasReachedEmpty {
                _dividerMap[_dividerMap.count - 1] = true // cap the top if no empty slots.
            } else { _dividerMap[_dividerMap.count - 1] = false} // uncap top if there was an empty.
        } else { // empty bottle
            for cInd in 0..<_dividerMap.count
            {
                _dividerMap[cInd] = false
            }
        }
        print("new divider map : \(_dividerMap).")
        return initialHeight - finalHeight
    }
    
    func overrideDividerMapDuringInitialFill(_ filledSoFar: Int) {
        _dividerMap = _startingDividerMap
        for index in 0..<_dividerMap.count {
            if index >= filledSoFar { // 0, draw none.  1, retain only value at 0...
                _dividerMap[index] = false
            }
        }
    }
    func resetDividerMap() {
        _dividerMap = _startingDividerMap
    }

    func setupTube() {
        makeContainer()
        self.sceneRepresentation = TubeRep(tubeHeight + bottomOffset)
        self.toBackground()
    }
    
    func startFill(colors: [TubeColors] ) {
        unYieldToFill()
        isFilling = true
        shouldUpdate = true
        currentState = .Filling
        _fillKeyFrame = 0
        timeToSkim = capPlaceDelay
        segmentsCount = 0
        gameSegments = colors.count
        initializeDividerPositions()
        initializeColorsAndDividerMap(colors)
    }
    // need to determine fullNumber before continuing
    var fullNum: Int = 0
    private var _fillKeyFrame = 0
    private func initialFillStep(_ deltaTime: Float) {
        switch _fillKeyFrame {
        case 0:
            if segmentsCount < gameSegments {
                var groupSize = 1
                let currentColor = _colorTypes[segmentsCount]
            if timeToSkim > 0.0 {
                if currentColor != .Empty {

                if !particleGroupPlaced {
                        var color = _colors[segmentsCount]
                        for index in (segmentsCount + 1)..<gameSegments {
                            if _colorTypes[index] == currentColor {
                                groupSize += 1
                            } else { break }
                        }
                        if groupSize > 1 {
                            print("groupsize : \(groupSize)")
                        }
                        timeToSkim = capPlaceDelay * Float(groupSize)

                    let yPos = (_dividerIncrement * 1.4 * Float(segmentsCount + groupSize - 1) - tubeHeight / 2) + bottomOffset + GameSettings.DropHeight
                        LiquidFun.createParticleBox(forSystem: particleSystem, position: Vector2D(x: self.getBoxPositionX(), y: self.getBoxPositionY() + yPos - _dividerIncrement/2), size: Size2D(width: tubeWidth * _groupScaleX, height: Float(groupSize) * _groupScaleY * _dividerIncrement), color: &color)
                        particleGroupPlaced = true
                        segmentsCount += groupSize
                        if(groupSize > 1){
                            timeToSkim = capPlaceDelay * Float(groupSize) * 0.8
                        } else {
                        timeToSkim = capPlaceDelay
                        }
                        print("Filling current Cell color: \(_colorTypes[segmentsCount - 1])")
                    }
                }
                else {
                    segmentsCount += groupSize
                }
                timeToSkim -= deltaTime
            } else {
                timeToSkim = capPlaceDelay
               // skimTopParticles(getTopMostTrueBool(_dividerMap))                     //delete overflows
                overrideDividerMapDuringInitialFill(segmentsCount)

                particleGroupPlaced = false
            }
            }  else { nextFillKF() }
        case 1:
            if timeToSkim > 0.0 {
                timeToSkim -= deltaTime
            } else { nextFillKF() }
        case 2:
            resetDividerMap()
            skimTopParticles(getTopMostTrueBool(_dividerMap) - 1)
            CapTop()
            let outsidesDelet = LiquidFun.deleteParticlesOutside(particleSystem,
                                             width: tubeWidth,
                                             height: tubeHeight,
                                             rotation: 0.0,
                                             position: Vector2D(x:self.getBoxPositionX(),y:getBoxPositionY()))
            self.returnToOrigin()
            isFilling = false
            if getTopMostNonEmptyIndex() == 3 {
            fullNum = Int(LiquidFun.particleCount(forSystem: particleSystem))
                print("fullNumber = \(fullNum)")
            }
        default:
            print("unknown fill key frame \(_fillKeyFrame)")
        }
    }
    
    func nextFillKF() {
        _fillKeyFrame += 1
        timeToSkim = capPlaceDelay
    }
    
    func PopCap() {
        LiquidFun.popCap(_tube)
    }
    func CapTop() {
        LiquidFun.capTop(_tube, vertices: &_dividerPositions[3]!) // warning, fix later.
    }
    
    func skimTopParticles(_ aboveSegment: Int) {
        let amountDeletedAbove = LiquidFun.deleteParticles(inParticleSystem: particleSystem, aboveYPosition: self.getBoxPositionY() - bottomFromOrigin + Float(aboveSegment + 1)*_dividerIncrement )
        print("deleted overflow amt: \(amountDeletedAbove).")

    }
    
    func initializeDividerPositions() {
        for incr in 0..<gameSegments {
            let yPos = (_dividerIncrement * Float(incr)) - bottomFromOrigin
            _dividerPositions[incr] =  [Vector2D(x: -tubeWidth,y:yPos ),
                                            Vector2D(x:  tubeWidth,y:yPos ) ]
            _dividerYs.append(yPos)
        }
    }
    // updates the yValues to update colors at levels, really cool effect
    func updateYs(_ angle: Float) {
        for index in 0..<_dividerPositions.count {
            let originalVectors = _dividerPositions[index]
            _dividerYs[index] = getOffsetPosition().y + (originalVectors![0].y ) * abs(cos(angle / 2)  ) - 0.1
            
        }
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
    
    override func moveX(_ delta: Float ) {
        sceneRepresentation.moveX(delta)
    }
    override func moveY(_ delta: Float) {
        sceneRepresentation.moveY(delta)
    }
    override func rotateZ(_ value: Float) {
        LiquidFun.rotateTube(_tube, amount: value)
        self.updateYs(self.getRotationZ())
        self.sceneRepresentation.setRotationZ(self.getRotationZ())
    }
    func  dampRotation( _ value: Float){
        LiquidFun.dampRotation(ofBody: _tube, amount: value)
    }
    func boxMove(_ velocity: float2 = float2()) {
        LiquidFun.moveTube(_tube, pushDirection: Vector2D(x: Float32(velocity.x), y: Float32(velocity.y)))
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
   
    public func transferTopGroup(_ fromSystem: UnsafeMutableRawPointer!, toSystem: UnsafeMutableRawPointer!, color: UnsafeMutableRawPointer!,
                                 particlesAboveYPosition: Float) {
        assert(fromSystem != toSystem)
        LiquidFun.transferTopMostGroup(inParticleSystem: fromSystem,
                                       newSystem: toSystem,
                                       color: color,
                                       aboveYPosition: particlesAboveYPosition)
    }
    
    func clearTube() {
        LiquidFun.destroyParticles(inSystem: particleSystem)
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
