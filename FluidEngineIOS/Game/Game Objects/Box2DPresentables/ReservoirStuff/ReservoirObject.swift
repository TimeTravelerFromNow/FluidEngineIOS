import MetalKit

class ReservoirObject: Node {
    
    var buttons: [FloatingButton] = []
    var valves: [Int:FloatingButton] = [:]
    var topValve: FloatingButton!
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
    // bulb variables
    var hemisphereSegments = 8
    var bulbRadius: Float = 0.4

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
    private var _valveAngles: [Float] = []
    
    // pipe filling arrays
    var targets: [float2] = []
    private var _arrows: [Arrow2D] = []
    
    var _pipes: [Pipe] = []
    var isBuildingPipes = false
    var arrowLength: Float = 0.2
    
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
        attachTopValve()
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
    
    func attachTopValve() {
        let index = getSegmentIndex( .pi / 2)
        let position = getSegmentCenter( .pi / 2)
        let topValveButton = FloatingButton(position, size: float2(0.25,0.25), textureType: .BigValveTexture)
        topValve = topValveButton
    }
    
    
    func fill(color: TubeColors) {
        waterColor = WaterColors[color]!
        spawnParticleBox(origin,
                         float2(1.0,2.2),
                         color: &waterColor)
    }
    
    func createBulb() {
        LiquidFun.createBulb(onReservoir: _reservoir, hemisphereSegments: hemisphereSegments, radius: bulbRadius)
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
        let boxPos = getBulbPos()
        let angle = Float.pi * Float(getSegmentIndex(atAngle)) / Float(hemisphereSegments  )
            let x = cos(angle) * bulbRadius
        let y  = sin(angle) * bulbRadius
        return float2(boxPos.x + x, boxPos.y + y)
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
        
        let tvX = topValve.box2DPos.x
        let tvY = topValve.box2DPos.y
        
        topValve.setPositionX( tvX * GameSettings.stmRatio )
        topValve.setPositionY( tvY * GameSettings.stmRatio )
        topValve.modelConstants.modelMatrix = topValve.modelMatrix
        topValve.setRotationZ( LiquidFun.getBulbWallAngle(_reservoir, at: getSegmentIndex(.pi / 2)))
        for i in valves.keys {
            if let valve = valves[i] {
                let x = valve.box2DPos.x
                let y = valve.box2DPos.y
                
                valve.setPositionX( x * GameSettings.stmRatio )
                valve.setPositionY( y * GameSettings.stmRatio )
                valve.setRotationZ( LiquidFun.getBulbWallAngle(_reservoir, at: i))
                valve.modelConstants.modelMatrix = valve.modelMatrix
        
            }
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
            buildPipesStep( deltaTime )
        }
        if( isRotatingSegment ) {
            rotateSegmentStep( deltaTime )
        }
    }
    
    func buildPipes() {
        let targetCount = self.targets.count
        let centerAngle = 3 * Float.pi / 2
        let segmentAngleIncrement = Float.pi / Float(hemisphereSegments)
        
        var arrowDictionary: [Float:Arrow2D] = [:] // Can use to sort.
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
                let evenArrow = Arrow2D(tail: getBulbPos(),
                                        head: currCenter,
                                        direction: currNormal)
                arrowDictionary.updateValue(evenArrow, forKey: currAngle)
                if i > 0 {
                    if( mod2Result ) {
                        numberPipeCentersOnOneSide += 1
                    }
                }
            }
           
        } else {
            let arrowAngle0: Float = 3 * .pi / 2 // first angle in odd situation is downwards.
            let bottomArrowCenter = getSegmentCenter( arrowAngle0 )
            let bottomArrowNormal = float2(0, -1)
           
            let centerBottomArrow = Arrow2D(tail: getBulbPos(),
                                            head: bottomArrowCenter,
                                            direction: bottomArrowNormal)
            arrowDictionary.updateValue( centerBottomArrow, forKey: arrowAngle0 )
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
 
                    let oddArrow = Arrow2D(tail: getBulbPos(),
                                           head: currCenter,
                                           direction: currNormal)
                    arrowDictionary.updateValue( oddArrow, forKey: currAngle )

                    if i > 2 {
                        if( mod2Result ) {
                            numberPipeCentersOnOneSide += 1
                        }
                    }
                }
            }
        }
        var sortedArrows: [Arrow2D] = []
        
        let sortedAngles = Array(arrowDictionary.keys).sorted(by: <)
        for angle in sortedAngles {
            sortedArrows.append( arrowDictionary[angle]! )
        }
        _pipes = []
        for (i, t) in targets.enumerated() {
            if ( i > sortedArrows.count - 1 ) { print("Pipe build WARN::more targets than arrows for pipes."); return}
            sortedArrows[i].target = t
            let p = Pipe(parentReservoir: _reservoir)
            p.modelConstants = fluidModelConstants
            let currentControlPoints = controlPoints(sortedArrows[i])
            (p.tControlPoints, p.controlPoints) = currentControlPoints
            _pipes.append(p)
        }
        
        self._pipeBuildDelay = _defaultPipeBuildDelay
        self.isBuildingPipes = true
    }
    
    func attachValves() {
        for angle in _valveAngles {
            let pos = getSegmentCenter( angle )
            let index = getSegmentIndex( angle )
            if( !valves.keys.contains( index ) ) {
                let valveButton = FloatingButton(pos, size: float2(0.2, 0.2), textureType: .SmallValveTexture)
                valveButton.setRotationZ( angle )
                valves.updateValue(valveButton, forKey: index)
            }
        }
    }
    
    var topStateOpen = false
    func toggleTop() {
        if( topStateOpen ) {
            rotateBulbSegment(segmentAngle: .pi/2, toAngle: 0.0)
            topStateOpen = false
        } else {
            rotateBulbSegment(segmentAngle: .pi/2, toAngle: .pi/2)
            topStateOpen = true
        }
    }
    
    var isRotatingSegment = false
    var segmentsToRotate: [Int: Float] = [:]
    func rotateBulbSegment(segmentAngle: Float, toAngle:Float) {
        let segmentIndex = getSegmentIndex( segmentAngle )
        segmentsToRotate.updateValue( toAngle, forKey: segmentIndex )
        isRotatingSegment = true
    }
    
    
    var tubeToPipeDictionary: [Int:Int] = [:]
    func indexPipes(sourceGridIds: [Int] ) {
        guard let maxSourceGridId = sourceGridIds.max() else { print(" index Pipes WARN:: sourceGridIds Empty"); return }
        var angleIndex = 0
        for i in 0..<maxSourceGridId {
            if sourceGridIds.contains( i ) {
                for j in 0..<( 2 * hemisphereSegments ) {
                    if( valves.keys.contains( j ) ) {
                        if(angleIndex != j) {
                            angleIndex = j
                            tubeToPipeDictionary.updateValue(angleIndex, forKey: i)
                        break // break first loop
                        } else { // this pipe angle index is already taken by another tube
                            print("already taken")
                        }
                    }
                }
            }
        }
    }
    
    func rotateSegmentStep(_ deltaTime: Float) {
        var angV: Float = 4.0
        for (segmentInd, destAngle) in segmentsToRotate {
            let currAngle = LiquidFun.getBulbWallAngle(_reservoir, at: segmentInd)
            let angleToClose = destAngle - currAngle
            if( angleToClose < 0.0 ) {
                angV *= -1.0
            }
            var change = angV * deltaTime
            while(abs( change ) > abs( angleToClose )) {
                angV *= 0.99
                change = angV * deltaTime
            }
            LiquidFun.setBulbWallAngV(_reservoir, at: segmentInd, angV: angV)
            if( abs(angleToClose) < 0.01 ){
                segmentsToRotate.removeValue(forKey: segmentInd)
            }
        }
        if segmentsToRotate.count == 0 {
            isRotatingSegment = false
        }
    }
    
    // MARK: refactor so that we somehow are close to pointing downwards by the time we are over the tube.
    func controlPoints( _ arrow: Arrow2D) -> ([Float], [float2]) {
        var destination = arrow.target
        var start       = arrow.tail
        var actualStart = arrow.head
        var overDest = float2(destination.x, destination.y + 0.4)
        var underDest = float2(destination.x, destination.y - 0.8)
        let midpoint = ( actualStart + overDest ) / 2
        let bulbNormal = actualStart + normalize( arrow.head - arrow.tail ) * 0.3
        let outArray = [ start, actualStart, bulbNormal, midpoint, overDest,  destination, underDest]
        
        var totalL: Float = 0.0
        var tParams: [Float] = [ totalL ]
        // assign tParams to calculated lengths
        for i in 1..<outArray.count {
            totalL += length( outArray[i] - outArray[i - 1] )
            tParams.append( totalL)
        }
        // normalize tParams
        // MARK: tParams must be strictly increasing
        tParams = tParams.map { $0 / totalL }
        
        return (tParams, outArray)
    }
    
    //animations
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
            for p in _pipes {
                if( p.doneBuilding ) {
                    pipesDone += 1
                } else {
                    p.buildPipeSegment()
                    p.toggleFixtures()
                }
            }
            if(pipesDone == _pipes.count) {
                isBuildingPipes = false
              
                if isTesting { print("Done building  \(_pipes.count) pipes with.") }
                return
            }
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
        
        for i in 0..<_pipes.count{
            _pipes[i].render( renderCommandEncoder )
        }
        valvesRender( renderCommandEncoder )
        testingRender( renderCommandEncoder )
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
    
    func valvesRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        if( topValve.isSelected  ) {
            var selectColor = float4(0.3,0.4,0.1,1.0)
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Select))
            renderCommandEncoder.setFragmentBytes(&selectColor, length: float4.size, index: 2)
            renderCommandEncoder.setFragmentBytes(&selectTime, length : Float.size, index : 0)
        }
        
        renderCommandEncoder.setVertexBytes(&topValve.modelConstants, length : ModelConstants.stride, index: 2)
        topValve.buttonQuad.drawPrimitives(renderCommandEncoder, baseColorTextureType: topValve.buttonTexture)
        for i in valves.keys {
            // Vertex
            if( valves[i]!.isSelected ) {
                var selectColor = float4(0.3,0.4,0.1,1.0)
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Select))
                renderCommandEncoder.setFragmentBytes(&selectColor, length: float4.size, index: 2)
                renderCommandEncoder.setFragmentBytes(&selectTime, length : Float.size, index : 0)
            }
            
            renderCommandEncoder.setVertexBytes(&valves[i]!.modelConstants, length : ModelConstants.stride, index: 2)
            valves[i]!.buttonQuad.drawPrimitives(renderCommandEncoder, baseColorTextureType: valves[i]!.buttonTexture)
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
               
            case .MoveObject:
                isMoving = true
            default:
                print("unprogrammed floating button action! button at \(pressed.box2DPos + self.getBoxPosition())")
            }
        } else {
            if isPlacingControlPoints {
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
