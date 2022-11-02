import MetalKit

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
    var bulbRadius: Float = 1.0

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
    var isBuildingTestPipe = false
    var isMoving = false
    
    // animation
    private let _defaultPipeBuildDelay: Float = 0.03
    private var _pipeBuildDelay: Float = 0.05
    private var _controlPointIndex: Int = 0
    private var _targetRange: Float = 0.3 // how close the arrow needs to be to consider at target.
    private var _testArrow: Arrow2D!
    // control points
    var testControlPoints: [float2] = []
    private var _controlPointsCount: Int = 0
    private var _controlPointsVertexBuffer: MTLBuffer!
    
    var hemisphereSegments = 8
    
    // pipe filling arrays
    var targets: [float2] = []
    var controlPointArrays: [ [float2] ] = []
    private var _arrows: [Arrow2D] = []
    
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
        bulbNode.setScale( bulbRadius * 2 * GameSettings.stmRatio / scale )
        buildContainer()
        updateModelConstants()
        refreshFluidMCBuffer()
        _testPipe.modelConstants = fluidModelConstants
        self.texture = Textures.Get(.Reservoir)
        self.material.useTexture = true
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
        LiquidFun.createBulb(onReservoir: _reservoir, hemisphereSegments: hemisphereSegments, radius: 1.0)
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
        _controlPointsCount = testControlPoints.count
        if _controlPointsCount > 0 {
            let controlPointsSize = float2.stride( _controlPointsCount )
            _controlPointsVertexBuffer = Engine.Device.makeBuffer(bytes: testControlPoints, length: controlPointsSize, options: [])
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
        
        if( isBuildingTestPipe ) {
            testPipeBuildStep( deltaTime )
        }
        if( isBuildingPipes ) {
            buildPipesStep( deltaTime )
        }
    }
    // initiatiators
    func buildTestPipe() {
        self._pipeBuildDelay = _defaultPipeBuildDelay
        self._controlPointIndex = 0
        let startingPos = getBulbPos() + getSegmentCenter(3 * Float.pi / 2)
        self._testArrow = Arrow2D(startingPos, length: arrowLength)
        self.isBuildingTestPipe = true
    }
    
    var isBuildingPipes = false
    var arrowLength: Float = 0.2
    
    func buildPipes() {
        let targetCount = self.targets.count
        let centerAngle = 3 * Float.pi / 2
        let segmentAngleIncrement = Float.pi / Float(hemisphereSegments)
        
        var arrowCenters: [float2] = []
        var arrowNormals: [float2] = []
        //determine starting points (want symmetrical look)
        var numberPipeCentersOnOneSide = 1
        let oddCushion = Float.pi / 6
        if( targetCount % 2 == 0) {
            for i in 0..<targetCount {
                let mod2Result: Bool = (i % 2 == 0)
              
                var angleFromBottom = segmentAngleIncrement * Float(numberPipeCentersOnOneSide)
                if( mod2Result ) {
                    angleFromBottom *= -1
                }
                let currAngle = centerAngle + angleFromBottom
                let currCenter = getSegmentCenter( currAngle )
                let currNormal = float2(cos(currAngle), sin(currAngle))
                arrowCenters.append( currCenter )
                arrowNormals.append( currNormal )
                if i > 0 {
                    if( mod2Result ) {
                        numberPipeCentersOnOneSide += 1
                    }
                }
            }
           
        } else {
            let bottomArrowCenter = getSegmentCenter(3 * .pi / 2)
            let bottomArrowNormal = float2(0, -1)
           
            arrowCenters.append(bottomArrowCenter)
            arrowNormals.append(bottomArrowNormal)
            if targetCount > 1 {
                for i in 1..<targetCount {
                    let mod2Result: Bool = (i % 2 == 0)
                    
                    var angleFromBottom = segmentAngleIncrement * Float(numberPipeCentersOnOneSide) + oddCushion
                    if( mod2Result ) {
                        angleFromBottom *= -1
                    }
                    let currAngle = centerAngle + angleFromBottom
                    let currCenter = getSegmentCenter( currAngle )
                    let currNormal = float2(cos(currAngle), sin(currAngle))
                    arrowCenters.append( currCenter )
                    arrowNormals.append( currNormal )
                    if i > 2 {
                        if( mod2Result ) {
                            numberPipeCentersOnOneSide += 1
                        }
                    }
                }
            }
        }
        //initializeArrows
        _arrows = []
        _pipes = []
        for (i, center) in arrowCenters.enumerated() {
            let arrow = Arrow2D(center, length: arrowLength, direction: arrowNormals[i] )
            let pipe = Pipe()
            pipe.modelConstants = fluidModelConstants
            _arrows.append(arrow)
            _pipes.append(pipe)
        }
        
        controlPointArrays = []
        for (i, t) in targets.enumerated() {
            controlPointArrays.append( controlPoints(_arrows[i], destination: t) )
        }
        
        self._pipeBuildDelay = _defaultPipeBuildDelay
        self.isBuildingPipes = true
        self.mostBehindControlPointIndex = 0
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
        testControlPoints = [ halfPoint1, midpoint, halfPoint2, overDest, toDest ]
    }
    
    func controlPoints(_ fromArrow: Arrow2D, destination: float2) -> [float2] {
        let start = fromArrow.tailPos!
        let overDest = float2(destination.x, destination.y + 0.4)
        let midpoint = ( start + overDest ) / 2
        var halfPoint1 = (start + midpoint) / 2 // midpoint of midpoint
        var halfPoint2 = ( overDest + midpoint ) / 2
        
        halfPoint1 = float2(halfPoint1.x, halfPoint1.y - 0.1)
        halfPoint2 = float2(halfPoint2.x, halfPoint2.y + 0.1)
        // now we want to curve our line so that it bends more naturally, do this by editing half points.
        return  [ halfPoint1, midpoint, halfPoint2, overDest, destination ]
    }
    
    //animations
    var mostBehindControlPointIndex = 1

    func buildPipesStep(_ deltaTime: Float){
        if( _pipes.count == 0 ) {
            isBuildingPipes = false
            print("pipeBuildStep() Warning::_pipes array was size 0")
            return
        }
        
        if( _pipeBuildDelay > 0.0 ) {
            _pipeBuildDelay -= deltaTime
        } else {
            var pipesDone = 0
            for (i, p) in _pipes.enumerated() {
                let controlPoints = controlPointArrays[ i ]
                if(p.controlPointIndex < controlPoints.count) {
                    let currDest = controlPoints[p.controlPointIndex]
                    let currArrow = _arrows[i]
                    currArrow.turnAndMoveArrow( currDest )
                    p.setSourceVectors(pathVertices: currArrow.pathVertices, pathVectors: currArrow.directionVectors)
                    p.buildPipeVertices()
                  
                    if( abs(length( _arrows[i].tailPos - currDest )) < _targetRange ) {
                        p.controlPointIndex += 1
                        if( isTesting && i == 0 ) {  print("arrow 0 reached control point number \(p.controlPointIndex + 1).")}
                    }
                } else {
                    if( isTesting ) {  print("arrow \(i) reached destination.")}
                    pipesDone += 1
                }
            }
            if(pipesDone == _pipes.count) {
                isBuildingPipes = false
                for p in _pipes {
                    p.createFixtures(_reservoir, bulbCenter: getBulbPos())
                }
                if isTesting { print("Done building pipes with \(testControlPoints.count) control points.") }
                return
            }
            _pipeBuildDelay = _defaultPipeBuildDelay
        }
    }
    
    func testPipeBuildStep( _ deltaTime: Float ) {
        if( _controlPointIndex > testControlPoints.count - 1 ) {
            isBuildingTestPipe = false
            _testPipe.createFixtures(_reservoir, bulbCenter: getBulbPos())
            print("Done building pipes with \(testControlPoints.count) control points.")
            return
        }
        
        let currDest = testControlPoints[_controlPointIndex]
        
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
                if testControlPoints.count > 3 {
                    buildTestPipe()
                }
                if testControlPoints.count == 1 {
                    makeControlPoints(testControlPoints[0])
                    buildTestPipe()
                }
            case .MoveObject:
                isMoving = true
            default:
                print("unprogrammed floating button action! button at \(pressed.box2DPos + self.getBoxPosition())")
            }
        } else {
            if isPlacingControlPoints {
                if testControlPoints.count < 4 {
                testControlPoints.append(boxPos)
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