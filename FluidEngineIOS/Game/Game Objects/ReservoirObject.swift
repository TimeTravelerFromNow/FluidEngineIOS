import MetalKit

class ReservoirObject: Node {
    
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
    
    private var _pipeArrowHeadPos: float2 = float2(0)
    private var _pipeArrowTailPos: float2 = float2(0)
    private var _pipeArrowUnitDir: float2 { return normalize( _pipeArrowHeadPos - _pipeArrowTailPos ) }
    private var _newPipeArrowUnitDir: float2 = float2(0)
    private var _pipeArrowMagnitude: Float { return length(_pipeArrowHeadPos - _pipeArrowTailPos) }
    var pipeMag: Float = 0.2
    
    var tubeOrigins: [float2] = []
    var tubeColors: [TubeColors] = []
    var tubeHeight: Float = 0.0
    
    var hemisphereSegments = 8
    
    func setTubeHeight(_ height: Float) {
        
    }
    
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
    
    func determinePipeBuildingConstants(_ dest: float2) {
        let angle = 3 * Float.pi / 2
        var normalVector = float2( cos(angle), sin(angle) )
        var v0 =  getBulbPos()
        var v1 = v0 + normalVector
        var vectorToDest = dest - getSegmentCenter(3 * Float.pi / 2)
        var unitToDest = normalize(dest - v0)
        var shadow = dot(normalVector, unitToDest  )
        var angleToDest = acos(shadow)
        if (angleToDest > .pi ) {
            angleToDest = .pi
        }
        if (angleToDest < -.pi) {
            angleToDest = -.pi
        }
        
        _pipeVertices.append(v0)
        _pipeVertices.append(v1)
           _pipeArrowTailPos = v0
            _pipeArrowHeadPos =  v1
        
    }
    var hasOpened: Bool = false
    var hasReachedHalfway: Bool = false // we should aim for 3 points to turn at, first turn point, midpoint, second turn point
    // let's have a function that builds a smooth curved line to a destination
    func testFunction(_ dest: float2) {
        if !hasOpened  {
        removeWallPiece( getSegmentIndex(Float.pi/2) )
            hasOpened = true
            determinePipeBuildingConstants(dest)
        }
        if _pipeVertices.count == 0 {
        } else {
            let vectorToDest = dest - _pipeArrowHeadPos
            let unitToDest = normalize(vectorToDest)
            let shadow = dot(_pipeArrowUnitDir, unitToDest  )
            
            var angleToDest = abs(acos(shadow))
            if (angleToDest > .pi/24 ) {
                angleToDest = .pi/24
            }
            // determine whether left or right with cross product!
            let cross = cross(_pipeArrowUnitDir, unitToDest)
            let sign = cross.z
            if sign < 0 {
                angleToDest *= -1
            }
            print(_pipeArrowUnitDir)
            var rotationMat = matrix_float2x2()
            rotationMat.columns.0 = float2( cos(angleToDest), sin(angleToDest) )
            rotationMat.columns.1 = float2( -sin(angleToDest), cos(angleToDest) )
            _newPipeArrowUnitDir =  rotationMat * _pipeArrowUnitDir
            _pipeArrowTailPos = _pipeArrowHeadPos
            _pipeArrowHeadPos = _pipeArrowHeadPos + _newPipeArrowUnitDir * pipeMag
            print(_pipeArrowUnitDir)

            _pipeVertices.append(_pipeArrowHeadPos)
        }
        
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
        setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        setRotationZ( getRotationZ() )
        modelConstants.modelMatrix = modelMatrix
        let bulbPos = getBulbPos()
        bulbNode.setPositionX(bulbPos.x * GameSettings.stmRatio)
        bulbNode.setPositionY(bulbPos.y * GameSettings.stmRatio)
        bulbModelConstants.modelMatrix = bulbNode.modelMatrix
        refreshFluidMCBuffer()
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
        updateModelConstants()
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
    }
}
