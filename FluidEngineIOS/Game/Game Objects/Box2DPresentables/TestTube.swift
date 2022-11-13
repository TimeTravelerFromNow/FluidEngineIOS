import MetalKit

enum TubeSelectColors {
    case NoSelection
    case SelectHighlight
    case Reject
    case Finished
    case FillingEffect
}

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
    var testing = true
    var dividerWay = true
    var currentState: TestTubeStates = .AtRest
    var gridId: Int!
    
    var particleCount: Int = 0
    var origin : float2!
        
    var scale: Float!
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
    var candidateTube: TestTube?
    private var _pourKF:Int = 0
    private var _guidePositions:  [Vector2D]?

    var donePouring: Bool = false                   // done with entire pour action (including going back to origin)?
    //moving
    var beingMoved = false // stores whether the tube has been recently touched, could be returning to origin, but this allows it to be re-grabbable if true.
    var topSquareSpeed: Float = 3.0
    private var isActive: Bool = true
    
    var waterColor: float4 = float4(0.5,0.1,0.3,1.0)
    
    private var ptmRatio: Float!

    private var _tube: UnsafeMutableRawPointer!
    var particleSystem: UnsafeMutableRawPointer!
  
    // draw data
    private var _vertexBuffer: MTLBuffer!
    private var _fluidBuffer: MTLBuffer!
    private var _colorBuffer: MTLBuffer!
    private var _controlPtsBuffer: MTLBuffer!
    private var _controlPtsColorBuffer: MTLBuffer!
    private var _interpolatedPtsBuffer: MTLBuffer!
    private var _interpolatedPtsColorBuffer: MTLBuffer!
    
    private var _colors: [float4] = []
    private var _cPtsColors: [float4] = []
    private var _interpPtsColors: [float4] = []
    private var animationControlPoints: [float2] = []
    private var _tParams: [Float] = [] { didSet { _cPtsColors = _tParams.map { float4( $0, 0, 0, 1 ) } } }

    private var _b2AnimationControlPts: [Vector2D] = []
    private var _animationControlPtsY: [Float] = []
    private var _controlPointsCount: Int { return animationControlPoints.count }
    private var interpolatedPoints: [float2] = []
    private var _interpolatedPtsX: [Float] = []
    private var _interpolatedPtsY: [Float] = []
    private var _sourceTPoints: [Float] = [] { didSet { _interpPtsColors = _sourceTPoints.map { float4( 0, 0, $0, 1) } } }
    private var _sourceTPointCount: Int = 0
    private var _interpolatedPtsCount: Int { return interpolatedPoints.count }
    private var _interpolatedTangents: [Vector2D] = []
    
    //tube geometry
    private var tubeOBJVertices: [Vector2D] = []
    private var tubeHeight: Float!
    private var tubeWidth : Float!
    var dividerOffset: Float!
    private var bottomOffset: Float = 0.0 // determine how to offset the first cell a little to match the sizes of the other cells.
    private var _dividerIncrement: Float { return (tubeHeight) / Float(totalColors) }
    private var _dividerScale: Float = 1.5
    //game state related
    private var totalColors: Int { return currentColors.count }//no. cells dont change during a level.
    private var _initialFillProgress: Int = 0
    // determine if still needed after C++ refactor
    private var _dividerReferences: [UnsafeMutableRawPointer?] = []
    private var _dividerPositions: [ [Vector2D] ]!
    private var _dividerYs : [ Float ]!
    // for handling group destruction
    private var _groupReferences:   UnsafeMutableRawPointer!
    
    var currentColors: [TubeColors] = [] {
        didSet { refreshDividers() }
    } // what we will see, what dividers are computed on
    var newColors: [TubeColors] = [] // state we are trying to achieve with animation
    private var _currentTopIndex: Int { // zero is completely empty
        return (currentColors.firstIndex(where: {$0 == .Empty} ) ?? totalColors) - 1
    }
    
    // more variables
    private var _previousState: TestTubeStates = .AtRest
    private var selectPos: Float { return origin.y + 0.3 }
    // initial filling
    var fullNum: Int = 0
    private var _fillKeyFrame = 0
    // more important accessible variables
    var mesh: Mesh!
    
    var modelConstants = ModelConstants()
    var fluidModelConstants = ModelConstants()
    
    // filling animation variables
    var updatePipe = false
    var pipes: [TubeColors: Pipe] = [:] // the pipes the tube will use for filling
    var currentFillNum = 0
    let quota = 30
    let safetyTime: Float = 1.9
    var timeTillSafety: Float = 0.0 // dont get stuck
    
    //visual states
    var isSelected = false
    var selectEffect: TubeSelectColors = .NoSelection
    private var _timeTicked: Float = 0.0
    private var _selectColors : [TubeSelectColors:float3] = [ .SelectHighlight: float3(1.0,1.0,1.0),
                                                             .Reject  : float3(1.0,0.0,0.0),
                                                             .Finished: float3(1.0,1.0,0.0) ]
                                                            
    var material = CustomMaterial()
    
    var previousSelectState: TubeSelectColors = .NoSelection
    
    private var _selectCountdown: Float = 1.0
    let defaultSelectCountdown: Float =  1.0
    
    private var _texture: MTLTexture!
    
    private let pourAngle: Float = 3 * .pi/5
    
    // rotation variables
    private var _rotControlAngles: [Float] = []
    private var _rotTControlPoints: [Float] = []
    private var _interpRotTs: [Float] = []
    private var _interpolatedAngles: [Float] = []
    private var _interpSlopes: [Float] = [] // we use slopes (will directly set angular velocity)
    private let _defaultRotationTime: Float = 0.6
    private var _rotStepTime: Float = 0.0
    private var _rotateDelay: Float = 0.0
    private var _rotInd = 0
    private var _rotSpline: UnsafeMutableRawPointer?
    
    //pouring animation
    private var travelingToPourPos = false
    private var isTipping = false
    private var finishingTubePour = false
    private var _currentTravelTime: Float = 0.0
    private var _paramTravelInd: Int = 0
    private var _speed: Float = 2.0
    // translation step data
    private var isReleasing = false
    private var _defaultReleaseDelay: Float = 1.5
    private var _releaseTime: Float = 0.0
    private var _recieveTime: Float = 0.0
//    private var _defaultRecieveDelay
    private var _pouredColor: TubeColors = .Empty
    private var isRecieving = false
    
    private let defaultTravelSafetyTime: Float = 1.0
    private var _travelTime: Float = 0.0
    
    
    init( origin: float2 = float2(0,0), gridId: Int = -1, scale: Float = 5.0, startingColors: [TubeColors] = [.Empty] ) {
        super.init()
        if( gridId == -1 ) { print("TestTube() ADVISE::did you mean to init tube with -1? I will be test testTube.")}
        self.gridId = gridId
        self.ptmRatio = GameSettings.ptmRatio
        self.origin = origin
        self.mesh = MeshLibrary.Get(.TestTube)
        setScale(1 / (GameSettings.ptmRatio * 5) )
        self.setPositionZ(0.16)
        fluidModelConstants.modelMatrix = modelMatrix
        self.setScaleX( GameSettings.stmRatio * 1.3 / scale ) // particles appear to move a bit out of the fixtures
        self.setScaleY( GameSettings.stmRatio * 1.1 / scale )
        self.setPositionZ(0.1)
        self.scale = scale
        initializeColors(startingColors)
        self.makeContainer()
        self.toForeground()
        self._texture = Textures.Get(.TestTube)
        self.material.useTexture = true
        self.material.useMaterialColor = false
    }
    
    //initialization
    private func makeContainer() {
        self.tubeOBJVertices = mesh.getBoxVertices( scale )
        let (xVals, yVals) = ( tubeOBJVertices.map { Float($0.x) } , tubeOBJVertices.map { Float($0.y) } )
        guard let yMax = yVals.max() else { print("TestTube() ERROR:no yMax from obj vertices"); return }
        guard let yMin = yVals.min() else { print("TestTube() ERROR:no yMin from obj vertices"); return }
        guard let xMax = xVals.max() else { print("TestTube() ERROR:no xMax from obj vertices"); return }
        guard let xMin = xVals.min() else { print("TestTube() ERROR:no xMin from obj vertices"); return }
        tubeHeight = Float( yMax - yMin )
        let differenceUpFromOrigin = yMax - tubeHeight / 2
        let differenceDownFromOrigin = yMin + tubeHeight / 2
        dividerOffset = differenceUpFromOrigin
        tubeWidth = Float( xMax - xMin )
        initializeDividerArrays()
        initializeDividerPositions()
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1,
                                                        density: GameSettings.Density)
        _tube = LiquidFun.makeTube(particleSystem,
                                   location: Vector2D(x:origin.x,y:origin.y),
                                   vertices: &tubeOBJVertices,
                                   vertexCount: UInt32(tubeOBJVertices.count),
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
            let yPos = (_dividerIncrement * Float(incr + 1)) - tubeHeight / 2 + dividerOffset
            var dividerVertices = [Vector2D(x: -tubeWidth * _dividerScale / 2,y:yPos ),
                                   Vector2D(x:  tubeWidth * _dividerScale / 2,y:yPos ) ]
            _dividerPositions[incr] =  dividerVertices
            _dividerYs[incr] = yPos
        }
    }
    
    private func initializeColors(_ colors: [TubeColors]) {
        self.currentColors = [TubeColors].init(repeating: .Empty, count: colors.count)
        self.newColors = colors
    }
    
    //destruction
    deinit {
        LiquidFun.destroyBody(_tube)
    }

    override func update(deltaTime: Float) {
        if updatePipe {
            pipeRecieveStep( deltaTime )
        }
        if isSelected {
            _timeTicked += deltaTime
        }
        
        super.update()
        
        switch currentState {
        case .Emptying:
            emptyStep(deltaTime)
        case .Initializing:
            if( updatePipe ) {
            } else {
//                initialFillStep(deltaTime)
            }
        case .Pouring:
            if !isPourCandidate {
                pourStep(deltaTime)
            }
        case .Moving:
            toForeground()
        case .ReturningToOrigin:
            if !beingMoved {
                returnToOriginStep(deltaTime)
            }
            else {
                toForeground()
                self.rotateZ(0.0)
                currentState = .Moving  //allows control from outside
            }
        case .Selected: // drive it upwards fast
            selectStep(deltaTime)
        case .CleanupValues:
            self.isSelected = false
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
    func destroyPipes() {
        pipes = [:]
    }
    
    private func resetPipeFilters() {
        for pipe in pipes.values { // reset the other pipe filters so they dont block.
            pipe.resetFilter()
        }
    }
    func fillFromPipes() { // called every time we need a new color from a pipe
        skimTopParticles(_currentTopIndex)
        resetPipeFilters()
        
        if( _currentTopIndex > totalColors - 2 ) {
            updatePipe = false
            returnToOrigin()
            return
        }
        if( currentColors == newColors) { // all good
            updatePipe = false
            returnToOrigin()
            return
        }
        guard let pipeToAsk = pipes[newColors[ _currentTopIndex + 1 ]] else { updatePipe = false; returnToOrigin(); return;  }
        selectEffect = .FillingEffect
        isSelected = true
        _selectColors.updateValue( (WaterColors[ newColors[ _currentTopIndex + 1] ]?.xyz ?? _selectColors[.SelectHighlight])!, forKey: .FillingEffect)
        pipeToAsk.highlighted = true
        pipeToAsk.attachFixtures()
        print("asking for color \(_currentTopIndex + 1) which should be \(currentColors[_currentTopIndex + 1])")
        print("pipe color was \(pipeToAsk.fluidColor)")
        pipeToAsk.openValve()
        pipeToAsk.shareFilter( particleSystem )
        currentFillNum = 0
        timeTillSafety = 0.0
        updatePipe = true
    }
  
    func pipeRecieveStep( _ deltaTime: Float ) {
        let newColor = newColors[ _currentTopIndex + 1 ]
        guard let currPipe = pipes[ newColor ] else { print("no pipe for \(newColor)"); return }
        
        if( currentFillNum < quota || timeTillSafety < safetyTime)  {
            currentFillNum += currPipe.transferParticles( particleSystem )
            if currentFillNum > quota {
                currPipe.closeValve()
            }
        } else { // close pipe valve whether done or not, and stop updating the pipe when valve done rotating
            currPipe.closeValve()
            if !(currPipe.isRotatingSegment) {
                refreshDividers()
                selectEffect = .NoSelection
                currPipe.highlighted = false
                currentColors[ _currentTopIndex + 1 ] = newColor
                fillFromPipes()
            }
        }
        timeTillSafety += deltaTime
        currPipe.updatePipe( deltaTime )
    }
    
    func setFilterOfCandidate() {
        if isPourCandidate {
            LiquidFun.setPourBits(self._tube)
        } else {
            print("setFilterOfCandidate() WARN::want to set filter bits on candidate tube not marked thus.")
        }
    }
    
    //begin animations
    func startFastFill(colors: [TubeColors] ) {
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
    
    func startPipeFill( ) {
        self.currentState = .Initializing
        if particleSystem == nil { print("particle system unitialized before initial fill.")}
        LiquidFun.deleteParticles(inParticleSystem: particleSystem, aboveYPosition: getBoxPositionY() - tubeHeight)
        fillFromPipes()
    }
    
    func startPouring(newPourTubeColors: [TubeColors], newCandidateTubeColors: [TubeColors], cTube: TestTube?) {
        self.candidateTube = cTube
        candidateTube?.isPourCandidate = true
        self.candidateTube?.toForeground()
        newColors = newPourTubeColors
        candidateTube?.newColors = newCandidateTubeColors
        if( newColors == currentColors ) { print("Start Pour WARN::newColors same as old colors") }
        determinePourNavigation()
        resetPipeFilters()
        currentState = .Pouring
        selectEffect = .NoSelection
        travelingToPourPos = true
        _rotInd = 0
        _rotateDelay = 0.0
        _paramTravelInd = 0
        if( _paramTravelInd + 2 > interpolatedPoints.count ) {
            print("start pour WARN::less than 2 interpolated points")
            return
        }
        _travelTime = defaultTravelSafetyTime // to make sure we dont miss simply because things are set wrong.
        setBoxVelocity( vector( interpolatedPoints[ _paramTravelInd + 1] - getBoxPosition(), mag: _speed) )
    }
    
    func determinePourNavigation() { // determines from where to pour based on respective origins
        guard let candidateTube = self.candidateTube else { fatalError("determine Pour navigation ERROR:: no candidate tube"); return}
        if( candidateTube.origin.x < self.origin.x) {
            _pourDirection = 1
            candidateTube._pourDirection = 1
        } else { _pourDirection = -1
            candidateTube._pourDirection = -1
        }
        
        let start = getBoxPosition()
        guard let target = candidateTube.origin else { print("pourNavigation() WARN::No target candidate!"); return}
        let xOffset = _pourDirection * abs(cos( pourAngle )) * tubeHeight / 2
        let heightFirst = float2( start.x, target.y + tubeHeight )
        let destination = float2( target.x + xOffset, target.y + tubeHeight )
        animationControlPoints = [ start, heightFirst, destination ]
        _tParams = CustomMathMethods.tParameterArray(animationControlPoints)
        
        makeSpline()

        (_sourceTPointCount, _sourceTPoints) = CustomMathMethods.getSourceTVals( _tParams, density: 3 )
        interpolatedPoints = [float2].init(repeating: float2(0,0), count: _sourceTPointCount)
        _interpolatedTangents = interpolatedPoints.map { Vector2D(x:$0.x,y:$0.y) }
        _interpolatedPtsX = _sourceTPoints
        _interpolatedPtsY = _sourceTPoints
        if( _splineRef != nil ) {
            LiquidFun.setInterpolatedValues(_splineRef, tVals: &_sourceTPoints, onXVals: &_interpolatedPtsX, onYVals: &_interpolatedPtsY, onTangents: &_interpolatedTangents, valCount: _sourceTPointCount)
            for i in 0..<_sourceTPointCount {
                interpolatedPoints[i] = float2( _interpolatedPtsX[i], _interpolatedPtsY[i] )
            }
        }
    }
    private var _splineRef: UnsafeMutableRawPointer?
    func makeSpline(resetRecursion: Bool = false) {
        if( _splineRef == nil ){
            _b2AnimationControlPts = animationControlPoints.map { Vector2D(x:$0.x,y:$0.y) }
            _splineRef = LiquidFun.makeSpline(&_tParams, withControlPoints: &_b2AnimationControlPts, controlPtsCount: _controlPointsCount)
        } else if !resetRecursion {
            _splineRef = nil
            makeSpline(resetRecursion: true)
        }
    }
    
    func resetPouringParameters() {
        self.currentState  = .Pouring
        self.isPourCandidate = false
        self.donePouring = false
        self.isPouring = true
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
        LiquidFun.beginEmpty( _tube )
        self.emptyKeyFrame = 0
        self._pourSpeed = pourSpeedDefault
        self.isEmptying = true
        self._emptyIncrement = _emptyDelay
        self.currentState = .Emptying
    }
    
    func select() {
        isSelected = true
        self.selectEffect = .SelectHighlight
        currentState = .Selected
    }
    
    func returnToOrigin() {
        LiquidFun.clearPourBits(_tube)
        self.isSelected = false
        self.isPouring = false
        self.isPourCandidate = false
        self.currentState = .ReturningToOrigin
    }
    
    func freeze() {
        LiquidFun.pauseParticleSystem(particleSystem)
    }
    func unFreeze() {
        LiquidFun.resumeParticleSystem(particleSystem)
    }
    
    // dividers
    func refreshDividers() {
        if(_dividerReferences.count != totalColors ) { print("refreshDivider ADVISE::divider references not initialized right, probably still in initialization phase, returning."); return}
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

    //emptying animation
    func emptyStep(_ deltaTime: Float) {
        switch emptyKeyFrame {
        case 0:
            while _currentTopIndex > -1 {
                currentColors[_currentTopIndex] = .Empty
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
    
    private func willArrive( _ mag: Float, _ deltaTime: Float ) -> Bool {
        if !( _paramTravelInd < interpolatedPoints.count ) {// this controls the transition to tipping
            travelingToPourPos = false
            setBoxVelocity()
            return false
        }
        let pos = interpolatedPoints[ _paramTravelInd ]
        let difference =  pos - getBoxPosition()
        let distance = length( difference )
        let distanceWillJump = deltaTime * length( getBoxVelocity() )
  
        let willPass = distanceWillJump > distance
        
        return willPass // means it will pass current position if true
    }
    
    private func startTipping(resolution: Int = 30) {
        isTipping = true
        LiquidFun.setPourBits(_tube)
        candidateTube?.setFilterOfCandidate()
        _rotStepTime = _defaultRotationTime / Float(resolution)
        // initialize a sin function for interpolating angles.
        // we can to interpolate since derivatives are built into the spline function :)
        let numControlPoints = 6
        let max: Float = .pi / 2
        let sinControlAngles = Array( stride(from: 0.0, to: _pourDirection * max, by: _pourDirection * max / Float(numControlPoints) ) ) // just for initializing interpolation values
        _rotTControlPoints = Array( stride(from: 0.0, to: _defaultRotationTime, by: _defaultRotationTime / Float(numControlPoints)) ) // strictly increasing
        _rotControlAngles  = sinControlAngles.map { pourAngle * sin( $0 ) }
        _rotSpline = LiquidFun.make1DSpline(&_rotTControlPoints, yControlPoints: &_rotControlAngles, controlPtsCount: _rotControlAngles.count)
        if( _rotSpline != nil ) {
            _interpRotTs = Array( stride(from: 0.0, to: _defaultRotationTime, by: _rotStepTime ))
            _interpolatedAngles = _interpRotTs
            _interpSlopes = _interpRotTs // angular Velocities
            LiquidFun.set1DInterpolatedValues(_rotSpline, xVals: &_interpRotTs, onYVals: &_interpolatedAngles, onSlopes: &_interpSlopes, valCount: _interpRotTs.count)
            print("spline DEBUG::final interp angle: \(_interpolatedAngles.last!)")
        }
    }
    
    private func pourStep(_ deltaTime: Float) {
        if( travelingToPourPos ) {
            if( willArrive( _speed, deltaTime )) {
                _paramTravelInd += 1
                if _paramTravelInd == Int(_interpolatedPtsCount / 2) {
                    startTipping()
                }
                if _paramTravelInd < _interpolatedPtsCount {
                    setBoxVelocity( vector( interpolatedPoints[ _paramTravelInd ] - getBoxPosition(), mag: _speed) )
                    _travelTime = defaultTravelSafetyTime
                }
            }
            if( _travelTime > 0.0) {
                _travelTime -= deltaTime
            }
             else {
                 _travelTime = defaultTravelSafetyTime
                 if( _paramTravelInd < _interpolatedPtsCount - 1) {
                     _paramTravelInd += 1
                 }
            }
        }
        
        if( isTipping ) {
            if( _rotateDelay > 0.0 ) {
                _rotateDelay -= deltaTime
            } else {
                if _rotInd < _interpSlopes.count {
                    LiquidFun.setAngularVelocity(_tube, angularVelocity: _interpSlopes[ _rotInd ] / 2)
                    _rotInd += 1
                    _rotateDelay = _rotStepTime
                } else { // now open and let particles go to next tube
                    isTipping = false
                    isReleasing = !travelingToPourPos
                    _releaseTime = 0.0
                    _recieveTime = _defaultReleaseDelay
                    LiquidFun.setAngularVelocity(_tube, angularVelocity: 0)
                }
            }
        }
        
        if( isReleasing ) {
            if( _releaseTime > 0.0 ){
                _releaseTime -= deltaTime
                
            } else {
                if( currentColors == newColors && !isRecieving ){
                    isReleasing = false
                    finishingTubePour = true
                } else {
                if( _currentTopIndex < totalColors && _currentTopIndex > -1 && !isRecieving ) { //make sure not to unleash until previous recieved
                    if( currentColors[_currentTopIndex] != newColors[_currentTopIndex]) {
                        _pouredColor = currentColors[_currentTopIndex]
                        currentColors[_currentTopIndex] = newColors[_currentTopIndex]
                        isRecieving = true
                    }
                }
                }
                _releaseTime = _defaultReleaseDelay
            }
        }
        
        if( isRecieving ){
            if( _recieveTime > 0.0 ) {
                _recieveTime -= deltaTime
            } else {
                _recieveTime = _defaultReleaseDelay
                candidateTube?.recieveNewColor( _pouredColor )
                isRecieving = false
            }
        }
        
        if( finishingTubePour ) {
            candidateTube?.returnToOrigin()
            candidateTube?.engulfParticles( particleSystem )
            self.returnToOrigin()
            finishingTubePour = false
        }
    }
    
    func recieveNewColor( _ color: TubeColors ) {
        if( isPourCandidate ) {
            currentColors[_currentTopIndex + 1] = color
        } else { print("pourNewColor WARN::called on non-candidate tube.")}
    }
    
    // uprighting animation
    let rotateMaxIter = 100
    func rotateUprightStep(deltaTime: Float, angularVelocity: Float = 40.0) -> Bool { // smart righting (will determine angular change)
        var angV = angularVelocity
        let currRotation = getRotationZ()
        var angularChange = deltaTime * angV
        
        if( abs(getRotationZ()) < 0.01 ) {
            return true
        }
        var i = 0
        while( abs(currRotation) < abs(angularChange) && i < rotateMaxIter  ) {
            angV *= 0.9
            angularChange = deltaTime * angV
            i += 1
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
                toBackground()
                currentState = .CleanupValues
                setBoxVelocity() //bring to stop
                print("Tube \(gridId) Returned To Origin.")
            }
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
                let currentColor = currentColors[_initialFillProgress]
                var color = _colors[_initialFillProgress]
                
                if timeToSkim > 0.0 {
                    if currentColor != .Empty {
                        if !particleGroupPlaced {
                            let yPos = (_dividerIncrement * 1.4 - tubeHeight / 2) + GameSettings.DropHeight
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
    // selection
    func conflict() {
        isSelected = true
        _selectCountdown = defaultSelectCountdown
        if selectEffect != .Reject {
            previousSelectState = selectEffect
        }
        selectEffect = .Reject
    }
    func rejectStep(_ deltaTime: Float) {
        if _selectCountdown > 0.0 {
        _selectCountdown -= deltaTime
        } else {
            _selectCountdown = defaultSelectCountdown
            selectEffect = previousSelectState
            isSelected = false
        }
    }
    
    func selectEffect(_ selectType: TubeSelectColors) {
        previousSelectState = selectType
        selectEffect = selectType
    }
    
    func clearEffect() {
        selectEffect = .NoSelection
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
        let amountDeletedAbove = LiquidFun.deleteParticles(inParticleSystem: particleSystem, aboveYPosition: Float(aboveSegment + 1)*_dividerIncrement + self.getBoxPositionY() - tubeHeight / 2 + dividerOffset )
        print("deleted overflow amt: \(amountDeletedAbove).")
    }
    
    func deleteOutside() -> Int {
        return Int(LiquidFun.deleteParticlesOutside(particleSystem,
                                                width: tubeWidth,
                                                height: tubeHeight,
                                                rotation: getRotationZ(),
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
        self.setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        self.setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        self.setRotationZ( getRotationZ() )
        modelConstants.modelMatrix = modelMatrix

        if _controlPointsCount > 0 {
            let controlPointsSize = float2.stride( _controlPointsCount )
            let controlPtsColorsSize = float4.stride( _controlPointsCount )
            _controlPtsBuffer = Engine.Device.makeBuffer(bytes: animationControlPoints, length: controlPointsSize, options: [])
            _controlPtsColorBuffer = Engine.Device.makeBuffer(bytes: _cPtsColors, length: controlPtsColorsSize, options: [])
        }
        if _interpolatedPtsCount > 0 {
            let interpPtsSize = float2.stride( _interpolatedPtsCount )
            let interpPtsColorsSize = float4.stride( _interpolatedPtsCount )
            _interpolatedPtsBuffer = Engine.Device.makeBuffer(bytes: interpolatedPoints, length: interpPtsSize, options: [])
            _interpolatedPtsColorBuffer = Engine.Device.makeBuffer(bytes: _interpPtsColors, length: interpPtsColorsSize, options: [])
        }
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
    
    func unitDirection(_ direction: float2) -> float2 { // MARK: it's not an inverse square root?
        let norm =  (pow(direction.x,2) + pow(direction.y, 2)).invSqrt
        return float2(x: direction.x * norm, y: direction.y * norm)
    }
    
    func vector(_ direction: float2, mag: Float) -> float2 { // MARK: is this right?
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
 
    override func rotateZ(_ value: Float) {
        LiquidFun.setAngularVelocity(_tube, angularVelocity: value)
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
    func setBoxVelocity(_ velocity: Vector2D ) {
        LiquidFun.setTubeVelocity(_tube, velocity: Vector2D(x: Float32(velocity.x), y: Float32(velocity.y)))
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
    }
    func toBackground() {
        self.setPositionZ(0.1)
    }
}

extension TestTube: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        updateModelConstants()
        refreshVertexBuffer()
        refreshFluidBuffer()
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        if isSelected {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Select))
            renderCommandEncoder.setFragmentBytes(&_timeTicked, length : Float.size, index : 0)
            renderCommandEncoder.setFragmentBytes(&_selectColors[ selectEffect ], length : float3.size, index : 2)
        }
        else {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        }
        renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
        renderCommandEncoder.setFragmentBytes(&material, length : CustomMaterial.stride, index : 1)
        renderCommandEncoder.setFragmentTexture(_texture, index: 0)
        mesh.drawPrimitives(renderCommandEncoder, baseColorTextureType: .TestTube)
        
        fluidSystemRender( renderCommandEncoder )
        controlPointsRender( renderCommandEncoder )
        interpolatedPointsRender( renderCommandEncoder )
    }
    
    func fluidSystemRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if particleCount > 0{
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.ColorFluid))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            
            renderCommandEncoder.setVertexBuffer(_vertexBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&fluidModelConstants,
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
    
    func controlPointsRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if _controlPointsCount > 0 {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Points))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            renderCommandEncoder.setVertexBuffer(_controlPtsBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&fluidModelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBuffer(_fluidBuffer,
                                                 offset: 0,
                                                 index: 3)
            renderCommandEncoder.setVertexBuffer(_controlPtsColorBuffer,
                                                 offset: 0,
                                                 index: 4)
            renderCommandEncoder.drawPrimitives(type: .point,
                                                vertexStart: 0,
                                                vertexCount: _controlPointsCount)
        }
    }
    func interpolatedPointsRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if _interpolatedPtsCount > 0 {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Points))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            renderCommandEncoder.setVertexBuffer(_interpolatedPtsBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&fluidModelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBuffer(_fluidBuffer,
                                                 offset: 0,
                                                 index: 3)
            renderCommandEncoder.setVertexBuffer(_interpolatedPtsColorBuffer,
                                                 offset: 0,
                                                 index: 4)
            renderCommandEncoder.drawPrimitives(type: .point,
                                                vertexStart: 0,
                                                vertexCount: _interpolatedPtsCount)
        }
    }
}
