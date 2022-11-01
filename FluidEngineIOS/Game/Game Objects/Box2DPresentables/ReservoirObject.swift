import MetalKit


enum MiniMenuActions {
    case ToggleMiniMenu
    case ToggleControlPoints
    case ConstructPipe
    
    case MoveObject
    
    case None
}
// A button without a representation in the box2d world
class FloatingButton: Node {
    
    var buttonQuad: Mesh = MeshLibrary.Get(.Quad)
    var buttonTexture: TextureTypes!
    var action: MiniMenuActions!
    var modelConstants = ModelConstants()
    var parentNode: Node!
    var box2DPos: float2!
    var size: float2!
    
    var isSelected = false
    
    init(_ boxPos: float2, size: float2, action: MiniMenuActions = .None, textureType: TextureTypes = .Missing) {
        super.init()
        box2DPos = boxPos
        self.size = size
        let xScale = size.x
        let yScale = size.y
        self.action = action
        self.buttonTexture = textureType
        self.setScaleX(GameSettings.stmRatio * xScale  )
        self.setScaleY(GameSettings.stmRatio * yScale )
        self.setPositionZ(0.1)
    }
    
    func setButtonSizeFromQuad() {
        
    }
    
    func pressButton( closure: () -> Void ) {
        isSelected = true
    }
    func releaseButton( closure: () -> Void ) {
        isSelected = false
    }
}

class Arrow2D {
    
    var tailPos: float2!
    var headPos: float2!
    var length: Float!
    var pathVertices: [float2] = []
    var directionVectors: [float2] = []
        
    private var _unitDir: float2 { return normalize( headPos - tailPos ) }
    private var _newUnitDir: float2 = float2(0)
    
    private var _maxTurnAngle: Float = .pi/14
    func setMaxTurnAngle(_ to: Float) { _maxTurnAngle = to }
    func getMaxTurnAngle() -> Float { return _maxTurnAngle }
    
    init(_ origin: float2, length: Float, direction: float2 = float2(0,-1)) {
        self.tailPos = origin
        self.length = length
        let unitDir = normalize( direction )
        self.headPos = tailPos + length * unitDir
        pathVertices.append(tailPos)
        directionVectors.append( unitDir )
    }
    
    func turnAndMoveArrow(_ toDest: float2) {
        turnArrow( toDest )
        moveArrowToNewDir()
    }
    
    private func turnArrow(_ toDest: float2) {
            let vectorToDest = toDest - tailPos
            let unitToDest = normalize(vectorToDest)
            let shadow = dot(_unitDir, unitToDest  )
            
            var angleToDest = abs(acos(shadow))
            if (angleToDest > _maxTurnAngle ) {
                angleToDest = _maxTurnAngle
            }
            // determine whether left or right with cross product!
            let cross = cross(_unitDir, unitToDest)
            let sign = cross.z
            if sign < 0 {
                angleToDest *= -1
            }
            
            var rotationMat = matrix_float2x2()
            rotationMat.columns.0 = float2( cos(angleToDest), sin(angleToDest) )
            rotationMat.columns.1 = float2( -sin(angleToDest), cos(angleToDest) )
            _newUnitDir =  rotationMat * _unitDir
    }
    
    private func moveArrowToNewDir() {
 
        tailPos = headPos
        headPos = headPos + _newUnitDir * length
        pathVertices.append(headPos)
        directionVectors.append(_newUnitDir)
    }
}

class Pipe: Node {
    private var _leftVertices:  [float2] = []
    private var _rightVertices: [float2] = []
    private var _sourceVertices: [float2] = [] // path vertices
    private var _sourceTangents: [float2] = [] // perpendicular vector at each source vertex
    
    private var _textureType: TextureTypes = .PipeTexture
    private var _mesh: CustomMesh!
    
    var modelConstants = ModelConstants()
    var fluidConstants: FluidConstants!
    private var _vertexBuffer: MTLBuffer!
    private var _vertexCount: Int = 0
    private let _ninetyDegreeRotMat = matrix_float2x2( float2( cos(.pi/2), sin(.pi/2) ),
                                                        float2( -sin(.pi/2), cos(.pi/2) ) )
    
    private var _pipeWidth: Float = 0.3
    var debugging = false
    
    override init() {
        super.init()
        _mesh = CustomMeshes.Get(.Quad)
        self.setScale(1 / ( GameSettings.ptmRatio * 5 ) )
        fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
    }
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if( _vertexCount > 3 ) { // we wont have indices set until we have at least 4 vertices
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.CustomBox2D))
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBytes(&fluidConstants,
                                                length: ModelConstants.stride,
                                                index: 3)
        renderCommandEncoder.setFragmentTexture(Textures.Get(_textureType), index: 0)
        _mesh.drawPrimitives( renderCommandEncoder )
        }
        if(debugging) {
            if _vertexCount > 2 {
                makeDebugVertexBuffer()
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Lines))
                renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
                renderCommandEncoder.setVertexBuffer(_vertexBuffer,
                                                     offset: 0,
                                                     index: 0)
//                renderCommandEncoder.setVertexBuffer(_fluidBuffer,
//                                                     offset: 0,
//                                                     index: 3)
//                renderCommandEncoder.setVertexBuffer(_colorBuffer,
//                                                     offset: 0,
//                                                     index: 4)
                renderCommandEncoder.drawPrimitives(type: .point,
                                                    vertexStart: 0,
                                                    vertexCount: _vertexCount * 2)
            }
        }
    }
    
   func makeDebugVertexBuffer() {
       var vertexBytes = _leftVertices
       vertexBytes.append(contentsOf: _rightVertices)
       _vertexBuffer = Engine.Device.makeBuffer(bytes: vertexBytes, length: float2.stride(_leftVertices.count + _rightVertices.count), options: [])
    }
    func setSourceVectors(pathVertices: [float2], pathVectors: [float2]) {
        _sourceVertices = pathVertices
        _sourceTangents = [float2].init(repeating: float2(0), count: pathVectors.count)
        // rotate each pathVector ninety deg. (so it is tangent), from this we can construct pipe vertices
        for i in 0..<pathVectors.count {
            _sourceTangents[i] = _ninetyDegreeRotMat * pathVectors[i]
        }
    }
    
    func newSourceVectors(pathVertex: float2, pathVector: float2) {
        _sourceVertices.append(pathVertex)
        let rotatedVector = _ninetyDegreeRotMat * pathVector
        _sourceTangents.append( rotatedVector )
    }
    
    func buildPipeVertices() {
        if( _sourceVertices.count < 2 ) { // need at least 4 vertices (from 2 source points)
            return
        }
        var newLeftVertices = _sourceVertices
        var newRightVertices = _sourceVertices // resizes both arrays
        var customVertices = [CustomVertex].init(repeating: CustomVertex(position: float3(0),
                                                                         color: float4(1.0,0.0,0.0,1.0),
                                                                         textureCoordinate: float2(0)), count: _sourceVertices.count * 2)

        var indices: [UInt32] = []
        var currIndex: UInt32 = 1
        for (i, v) in _sourceVertices.enumerated() {
            newLeftVertices[i] = v + _sourceTangents[i] * _pipeWidth / 2
            newRightVertices[i] = v - _sourceTangents[i] * _pipeWidth / 2
            customVertices[ Int(currIndex) - 1 ].position = float3(newLeftVertices[i].x, newLeftVertices[i].y, 0)
            customVertices[ Int(currIndex) - 1 ].textureCoordinate = float2(0,Float(i % 2))
            customVertices[ Int(currIndex) ].position = float3(newRightVertices[i].x, newRightVertices[i].y, 0)
            customVertices[ Int(currIndex) ].textureCoordinate =  float2(1, Float(i % 2))
            if currIndex > 2 {
                let triangle0 = [ currIndex - 3, currIndex - 2, currIndex - 1].map( { UInt32($0) } )
                let triangle1 = [ currIndex - 2, currIndex - 1, currIndex ].map( { UInt32($0) } )
                indices.append(contentsOf: triangle0)
                indices.append(contentsOf: triangle1)
            }
            currIndex += 2
        }
        _leftVertices = newLeftVertices
        _rightVertices = newRightVertices
        _vertexCount = newLeftVertices.count + newRightVertices.count
        _mesh.setIndices( indices )
        _mesh.setVertices( customVertices )
    }
    
    func createFixtures(_ onReservoir: UnsafeMutableRawPointer, bulbCenter: float2) {
        var b2LeftVertices = _leftVertices.map() { Vector2D(x:Float32($0.x - bulbCenter.x),y:Float32($0.y - bulbCenter.y))}
        var b2RightVertices = _rightVertices.map() { Vector2D(x:Float32($0.x - bulbCenter.x ),y:Float32($0.y - bulbCenter.y))}
        LiquidFun.makePipeFixture(onReservoir,
                                  leftVertices: &b2LeftVertices,
                                  rightVertices: &b2RightVertices,
                                  leftVertexCount: Int32(_leftVertices.count),
                                  rightVertexCount: Int32(_rightVertices.count))
    }
    func destroyFixtures(_ onReservoir: UnsafeMutableRawPointer) {
        LiquidFun.destroyPipeFixtures( onReservoir )
    }
}

class ReservoirObject: Node {
    
    var buttons: [FloatingButton] = []
    var buttonPressed: FloatingButton?
    
    var isTesting: Bool = true
    var isShowingMiniMenu: Bool = false
    var isPlacingControlPoints = false
    
    var moveButtonOffset = float2(1.0, 1.0)
    
    var boxVertices: [Vector2D] = []
    
    var reservoirMesh: Mesh!
    var bulbMesh: Mesh!
    var bulbNode: Node!
    
    var scale: Float!
    
    private var _reservoir: UnsafeMutableRawPointer!
    
    var particleSystem: UnsafeMutableRawPointer!
    
    var origin: float2!
    
    var waterColor: float4 = float4(1.0,0.0,0.0,1.0)
    
    var particleCount: Int = 0
    var ptmRatio: Float = GameSettings.ptmRatio
    
    // draw data
    private var _vertexBuffer: MTLBuffer!
    private var _fluidBuffer: MTLBuffer!
    private var _colorBuffer: MTLBuffer!
    
    var modelConstants = ModelConstants()
    var bulbModelConstants = ModelConstants()
    var material = CustomMaterial()
    var fluidModelConstants = ModelConstants()

    var texture: MTLTexture!
    
    // pipes draw data
    private var _pipeVertexBuffer: MTLBuffer!
    
    private var _pipeVertices: [float2] = []
    private var _pipeVertexCount: Int = 0
    
    var selectTime: Float = 0.0
    
    // object state stuff
    var isBuildingPipes = false
    var isMoving = false
    
    // animation
    private let _defaultPipeBuildDelay: Float = 0.3
    private var _pipeBuildDelay: Float = 0.05
    private var _controlPointIndex: Int = 0
    private var _targetRange: Float = 0.3 // how close the arrow needs to be to consider at target.
    private var _testArrow: Arrow2D!
    //control points
    var controlPoints: [float2] = []
    private var _controlPointsCount: Int = 0
    private var _controlPointsVertexBuffer: MTLBuffer!
    
    var hemisphereSegments = 8
    
    // pipes objects
    var _testPipe = Pipe()
    var _pipes: [Pipe] = []
    
    init( origin: float2, scale: Float = 4.0 ) {
        super.init()
        reservoirMesh = MeshLibrary.Get(.Reservoir)
        bulbMesh = MeshLibrary.Get(.BulbMesh)
        self.scale = scale
        self.origin = origin
        setScale(1 / (GameSettings.ptmRatio * 5) )
        fluidModelConstants.modelMatrix = modelMatrix
        setPositionZ(0.1)
        setScale(GameSettings.stmRatio / scale)
        bulbNode = Node()
        bulbNode.setScale(GameSettings.stmRatio / scale)
        buildContainer()
        updateModelConstants()
        refreshFluidMCBuffer()
        _testPipe.modelConstants = fluidModelConstants
        self.texture = Textures.Get(.Reservoir)
        self.material.useTexture = true
        _pipes.append(_testPipe)
    }
    
    //initialization
    func buildContainer() {
        guard let reservoirMesh = reservoirMesh else { fatalError("Reservoir OBject ERROR::NO Mesh!") }
        boxVertices = reservoirMesh.getBoxVertices(scale)
        let tubeVerticesPtr = LiquidFun.getVec2(&boxVertices, vertexCount: UInt32(boxVertices.count))
        
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / GameSettings.ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1,
                                                        density: GameSettings.Density)
        _reservoir = LiquidFun.makeReservoir(particleSystem,
                                             location: Vector2D(x:origin.x,y:origin.y),
                                             vertices: tubeVerticesPtr,
                                             vertexCount: UInt32(boxVertices.count))
        createBulb()
        LiquidFun.setParticleLimitForSystem(particleSystem, maxParticles: GameSettings.MaxParticles)
        buildMiniMenu()
    }
    
    func buildMiniMenu() {
        let toggleMiniMenuButton = FloatingButton(float2(-1.0,1.0),
                                                  size: float2(0.25,0.25),
                                                  action: .ToggleMiniMenu,
                                                  textureType: .EditTexture)
        let toggleMakeControlPointsButton = FloatingButton(float2(-1.0,0.5),
                                                           size: float2(0.25,0.25),
                                                           action: .ToggleControlPoints,
                                                           textureType: .ControlPointsTexture)
        let constructPipesButton = FloatingButton(float2(-1.0,0.0),
                                                  size: float2(0.25,0.25),
                                                  action: .ConstructPipe,
                                                  textureType: .ConstructPipesTexture)
        let moveReservoirButton = FloatingButton(moveButtonOffset,
                                                 size: float2(0.25,0.25),
                                                 action: .MoveObject,
                                                 textureType: .MoveObjectTexture)
        buttons.append(toggleMiniMenuButton)
        buttons.append(toggleMakeControlPointsButton)
        buttons.append(constructPipesButton)
        buttons.append(moveReservoirButton)
    }
    
    func fill(color: TubeColors) {
        waterColor = WaterColors[color]!
        spawnParticleBox(origin,
                         float2(2.0,4.2),
                         color: &waterColor)
    }
    
    func createBulb() {
        LiquidFun.createBulb(onReservoir: _reservoir, hemisphereSegments: hemisphereSegments, radius: 0.5)
    }
    
    func removeWallPiece(_ atIndex: Int) {
        LiquidFun.removeWallPiece(onReservoir: _reservoir, at: atIndex)
    }
    
    private func getBulbPos() -> float2 {
        let boxPos = LiquidFun.getBulbPos(_reservoir)
        return float2( boxPos.x, boxPos.y )
    }
    
    func getSegmentIndex(_ atAngle : Float) -> Int {
        return Int( atAngle * Float(hemisphereSegments) / Float.pi )
    }
    
    func getSegmentCenter(_ atAngle: Float) -> float2 {
        let boxPos = LiquidFun.getSegmentPos(_reservoir, at: getSegmentIndex(atAngle))
        return float2(boxPos.x, boxPos.y)
    }

    //buffer updates
    func updateModelConstants() {
        setPositionX( self.getBoxPositionX() * GameSettings.stmRatio )
        setPositionY( self.getBoxPositionY() * GameSettings.stmRatio )
        setRotationZ( getRotationZ() )
        modelConstants.modelMatrix = modelMatrix
        let bulbPos = getBulbPos()
        bulbNode.setPositionX( bulbPos.x * GameSettings.stmRatio )
        bulbNode.setPositionY( bulbPos.y * GameSettings.stmRatio )
        bulbModelConstants.modelMatrix = bulbNode.modelMatrix
        
        for i in 0..<buttons.count {
            let x = buttons[i].box2DPos.x + getBoxPositionX()
            let y = buttons[i].box2DPos.y + getBoxPositionY()
            if(buttons[i].action == .ToggleControlPoints) {
                if buttons[i].isSelected {
                    buttons[i].rotateZ(GameTime.DeltaTime)
                }
                else {
                    buttons[i].setRotationZ(0)
                }
            }
            buttons[i].setPositionX( x * GameSettings.stmRatio )
            buttons[i].setPositionY( y * GameSettings.stmRatio )
            buttons[i].modelConstants.modelMatrix = buttons[i].modelMatrix
        }
    }
    
    func refreshBuffers() {
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
        _pipeVertexCount = _pipeVertices.count
        if _pipeVertexCount > 0 {
        let pipeVertexSize = float2.stride( _pipeVertexCount )
        _pipeVertexBuffer =  Engine.Device.makeBuffer(bytes: _pipeVertices, length: pipeVertexSize, options: [])
        }
        _controlPointsCount = controlPoints.count
        if _controlPointsCount > 0 {
            let controlPointsSize = float2.stride( _controlPointsCount )
            _controlPointsVertexBuffer = Engine.Device.makeBuffer(bytes: controlPoints, length: controlPointsSize, options: [])
        }
    }
    
    func refreshFluidMCBuffer () {
        var fluidConstants = FluidConstants(ptmRatio: ptmRatio, pointSize: GameSettings.particleRadius)
        _fluidBuffer = Engine.Device.makeBuffer(bytes: &fluidConstants, length: FluidConstants.size, options: [])
    }
    
    func spawnParticleBox(_ position: float2,_ groupSize: float2, color: UnsafeMutableRawPointer) {
        LiquidFun.createParticleBox(forSystem: particleSystem,
                                    position: Vector2D(x:position.x,y: position.y),
                                    size: Size2D(width:groupSize.x, height: groupSize.y),
                                    color: color)
    }

    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        selectTime += deltaTime
        updateModelConstants()
        
        if( isBuildingPipes ) {
            pipeBuildStep( deltaTime )
        }
    }
    // initiatiators
    func buildPipe() {
        self._pipeBuildDelay = _defaultPipeBuildDelay
        self._controlPointIndex = 0
        let startingPos = getBulbPos() + getSegmentCenter(3 * Float.pi / 2)
        self._testArrow = Arrow2D(startingPos, length: 0.2)
        self.isBuildingPipes = true
    }
    
    func makeControlPoints(_ toDest: float2) {
        let start = getSegmentCenter( 3 * Float.pi / 2) + getBulbPos()
        let overDest = float2(toDest.x, toDest.y + 0.4)
        let midpoint = ( start + overDest ) / 2
        var halfPoint1 = (start + midpoint) / 2 // midpoint of midpoint
        var halfPoint2 = ( overDest + midpoint ) / 2
        
        halfPoint1 = float2(halfPoint1.x, halfPoint1.y - 0.1)
        halfPoint2 = float2(halfPoint2.x, halfPoint2.y + 0.1)
        // now we want to curve our line so that it bends more naturally, do this by editing half points.
        controlPoints = [ halfPoint1, midpoint, halfPoint2, overDest, toDest ]
    }
    
    //animations
    func pipeBuildStep( _ deltaTime: Float ) {
        if( _controlPointIndex > controlPoints.count - 1 ) {
            isBuildingPipes = false
            _testPipe.createFixtures(_reservoir, bulbCenter: getBulbPos())
            print("Done building pipes with \(controlPoints.count) control points.")
            return
        }
        
        let currDest = controlPoints[_controlPointIndex]
        
        if( _pipeBuildDelay > 0.0 ) {
            _pipeBuildDelay -= deltaTime
        } else {
            _testArrow.turnAndMoveArrow( currDest )
            _pipeVertices = _testArrow.pathVertices
            
            _testPipe.setSourceVectors(pathVertices: _pipeVertices, pathVectors: _testArrow.directionVectors)
            _testPipe.buildPipeVertices()
            
            _pipeBuildDelay = _defaultPipeBuildDelay
        }
        if( abs(length( _testArrow.tailPos - currDest )) < _targetRange ) {
            print("arrow reached control point number \(_controlPointIndex + 1).")
            _controlPointIndex += 1
            _pipeBuildDelay = _defaultPipeBuildDelay
        }
    }
    
    // particle management
    func deleteParticles() {
        LiquidFun.destroyParticles(inSystem: particleSystem)
    }
    
    //positioning
    func getBoxPosition() -> float2 {
        let boxPos = LiquidFun.getReservoirPosition(_reservoir)
        return float2(x: boxPos.x, y: boxPos.y)
    }
    func getBoxPositionX() -> Float {
        return Float(LiquidFun.getReservoirPosition(_reservoir).x)
    }
    func getBoxPositionY() -> Float {
        return Float(LiquidFun.getReservoirPosition(_reservoir).y)
    }
    
    override func getRotationZ() -> Float {
        return Float(LiquidFun.getReservoirRotation(_reservoir))
    }
    
    func getButtonAtPos(_ atPos: float2 ) -> FloatingButton? {
        let boxPos = self.getBoxPosition()
        for b in buttons {
            let boxCenter = b.box2DPos + boxPos
            if ( ( ( (boxCenter.x - b.size.x) < atPos.x) && (atPos.x < (boxCenter.x + b.size.x) ) ) &&
                 ( ( (boxCenter.y - b.size.y) < atPos.y) && (atPos.y < (boxCenter.y + b.size.y) ) )  ){
                return b
            }
        }
        return nil
    }
}


extension ReservoirObject: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        refreshBuffers()
        refreshFluidMCBuffer()
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        // Vertex
        renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
        //Fragment
        renderCommandEncoder.setFragmentBytes(&material, length : CustomMaterial.stride, index : 1)
        reservoirMesh.drawPrimitives(renderCommandEncoder)
        renderCommandEncoder.setVertexBytes(&bulbModelConstants, length : ModelConstants.stride, index: 2) // different modelConstants
        bulbMesh.drawPrimitives(renderCommandEncoder)
        fluidSystemRender(renderCommandEncoder)
        pipesRender(renderCommandEncoder)
        testingRender(renderCommandEncoder)
        
        for i in 0..<_pipes.count{
            _pipes[i].render( renderCommandEncoder )
        }
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
    
    func pipesRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if _pipeVertexCount > 0 {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Lines))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            renderCommandEncoder.setVertexBuffer(_pipeVertexBuffer,
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
            renderCommandEncoder.drawPrimitives(type: .line,
                                                vertexStart: 0,
                                                vertexCount: _pipeVertexCount)
        }
        if _controlPointsCount > 0 {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Lines))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            renderCommandEncoder.setVertexBuffer(_controlPointsVertexBuffer,
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
            renderCommandEncoder.drawPrimitives(type: .point,
                                                vertexStart: 0,
                                                vertexCount: _controlPointsCount)
        }
    }
}

extension ReservoirObject: Testable {
    func touchesBegan(_ boxPos: float2) {
        buttonPressed = getButtonAtPos( boxPos )
        if let pressed = buttonPressed {
            switch pressed.action {
            case .ToggleMiniMenu:
                isShowingMiniMenu.toggle()
                pressed.isSelected.toggle()
                if(!pressed.isSelected) { closeAllButtons() }
            case .ToggleControlPoints:
                pressed.isSelected.toggle()
                isPlacingControlPoints.toggle()
            case .ConstructPipe:
                pressed.isSelected.toggle()
                if controlPoints.count > 3 {
                    buildPipe()
                }
                if controlPoints.count == 1 {
                    makeControlPoints(controlPoints[0])
                    buildPipe()
                }
            case .MoveObject:
                isMoving = true
            default:
                print("unprogrammed floating button action! button at \(pressed.box2DPos + self.getBoxPosition())")
            }
        } else {
            if isPlacingControlPoints {
                if controlPoints.count < 4 {
                controlPoints.append(boxPos)
                }
            }
        }
    }
    
    func closeAllButtons() {
        for b in buttons {
            b.isSelected = false
        }
    }
    
    func touchDragged(_ boxPos: float2) {
        if buttonPressed != nil {
        print(buttonPressed?.id)
        }
        if( isMoving ) {
            let newV = boxPos - getBoxPosition() - moveButtonOffset
            LiquidFun.setVelocity(_reservoir, velocity: Vector2D(x:newV.x,y:newV.y))
        }
    }
    
    func touchEnded() {
        if(isMoving) {
        isMoving = false
            LiquidFun.setVelocity(_reservoir, velocity: Vector2D(x:0,y:0))
        }
        for i in 0..<buttons.count {
            switch buttons[i].action {
            case .ConstructPipe:
                buttons[i].isSelected = false
            default:
                print("touches ended on floating buttons with nothing to do")
            }
            
        }
    }
    
    func testingRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if isTesting {
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
                renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            for i in 0..<buttons.count {
                if (i > 0) && !isShowingMiniMenu { break }
                // Vertex
                if( buttons[i].isSelected ) {
                    var selectColor = float4(0.3,0.4,0.1,1.0)
                    renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Select))
                    renderCommandEncoder.setFragmentBytes(&selectColor, length: float4.size, index: 2)
                    renderCommandEncoder.setFragmentBytes(&selectTime, length : Float.size, index : 0)
                }
                
                renderCommandEncoder.setVertexBytes(&buttons[i].modelConstants, length : ModelConstants.stride, index: 2)
                buttons[i].buttonQuad.drawPrimitives(renderCommandEncoder, baseColorTextureType: buttons[i].buttonTexture)
            }
        }
    }
}
