import MetalKit

class ReservoirObject: Node {
    
    var boxVertices: [Vector2D] = []
    
    var mesh: Mesh!
    
    var scale: Float!
    
    private var _reservoir: UnsafeMutableRawPointer!
    
    var particleSystem: UnsafeMutableRawPointer!
    
    var origin: float2!
    
    var waterColor: float4 = float4(1.0,0.0,0.0,1.0)
    
    var particleCount: Int = 0
    var ptmRatio: Float = GameSettings.ptmRatio
    
    // draw data
    private var _vertexBuffer: MTLBuffer!
    private var _fluidConstants: MTLBuffer!
    private var _colorBuffer: MTLBuffer!
    
    let pipeLinesCount = 2 // how many pipes are there
    
    private var _pipeVerticesBuffers: [MTLBuffer] = []
    private var _pipeVertexCounts: [Int] = []
    private var _pipeColorsBuffers: [MTLBuffer] = []
    
    var modelConstants = ModelConstants()
    var material = CustomMaterial()
    var fluidModelConstants = ModelConstants()

    var texture: MTLTexture!
    
    var tubeOrigins: [float2] = []
    var tubeColors: [TubeColors] = []
    var tubeHeight: Float = 0.0
    
    var bulbVertices: [Vector2D] = []
    
    func setTubeHeight(_ height: Float) {
        
    }
    
    init( origin: float2, scale: Float = 4.0 ) {
        super.init()
        mesh = MeshLibrary.Get(.Reservoir)
        self.scale = scale
       
        self.origin = origin
        
        setScale(1 / (GameSettings.ptmRatio * 5) )
        fluidModelConstants.modelMatrix = modelMatrix
        setPositionZ(0.1)
        setScale(GameSettings.stmRatio / scale)
        buildContainer()
        updateModelConstants()
        self.texture = Textures.Get(.Reservoir)
        self.material.useTexture = true
        createBulb()
        refreshFluidConstants()
    }
    
    //initialization
    func buildContainer() {
        guard let reservoirMesh = mesh else { fatalError("Reservoir OBject ERROR::NO Mesh!") }
        boxVertices = reservoirMesh.getBoxVertices(scale)
        let tubeVerticesPtr = LiquidFun.getVec2(&boxVertices, vertexCount: UInt32(boxVertices.count))
        
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / GameSettings.ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1,
                                                        density: GameSettings.Density)
        _reservoir = LiquidFun.makeReservoir(particleSystem,
                                             location: Vector2D(x:origin.x,y: origin.y),
                                             vertices: tubeVerticesPtr,
                                             vertexCount: UInt32(boxVertices.count))
        LiquidFun.setParticleLimitForSystem(particleSystem, maxParticles: GameSettings.MaxParticles)
    }
    
    func fill(color: TubeColors) {
        waterColor = WaterColors[color]!
        spawnParticleBox(origin,
                         float2(1.0,3.2),
                         color: &waterColor)
    }
    
    func createBulb() {
        var verticesPtr = LiquidFun.createBulb(onReservoir: _reservoir)
        bulbVertices = []
    }
    
    func buildPipe(_ towardsPoint: float2) {
        LiquidFun.buildPipe(_reservoir, towardsPoint: Vector2D(x:towardsPoint.x, y:towardsPoint.y))
    }
    
    func removeWallPiece(_ atIndex: Int) {
        LiquidFun.removeWallPiece(onReservoir: _reservoir, at: atIndex)
    }

    //buffer updates
    func updateModelConstants() {
        modelConstants.modelMatrix = modelMatrix
        setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        setRotationZ( getRotationZ() )
    }
    
    func updatePipeVertexBuffers() {
        var pipeVerticesPtr = LiquidFun.getAllPipeVertices(_reservoir)
        var pipeVertexCounts = LiquidFun.getPipeLineVertexCounts(_reservoir)
        
        for i in 0..<pipeLinesCount { // hardcoded 2 pipe lines
            guard let currVertexCount32 = pipeVertexCounts?.pointee else { break }
            let currVertexCount = Int(currVertexCount32)
            guard var currVertices = pipeVerticesPtr?.pointee else { break }
            
            let newBufferSize = float2.stride(currVertexCount)
            var verticesBytes = [float2].init(repeating: float2(x:0,y:0), count: currVertexCount)
            let colorBufferSize = float3.stride(currVertexCount)
            var colors = [float3].init(repeating: float3(1.0,0,0), count: currVertexCount)
            
            for j in 0..<currVertexCount {
                verticesBytes[j] = float2(currVertices.pointee.x, currVertices.pointee.y)
                currVertices = currVertices.advanced(by: 1)
            }
            guard var newColorBuffer = Engine.Device.makeBuffer(bytes: colors, length: colorBufferSize, options: []) else { break }
            guard var newBuffer = Engine.Device.makeBuffer(bytes: verticesBytes, length: newBufferSize, options: []) else { break }
            if( i > _pipeVerticesBuffers.count - 1 ) {
                _pipeVerticesBuffers.append( newBuffer )
                _pipeVertexCounts.append(currVertexCount)
                _pipeColorsBuffers.append( newColorBuffer)
            }
            _pipeVerticesBuffers[i] = newBuffer
            _pipeVertexCounts[i] = currVertexCount
            _pipeColorsBuffers[i] = newColorBuffer
            pipeVerticesPtr = pipeVerticesPtr?.advanced(by: 1)
            pipeVertexCounts = pipeVertexCounts?.advanced(by: 1)
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
    
    func refreshFluidConstants () {
      var fluidConstants = FluidConstants(ptmRatio: ptmRatio, pointSize: GameSettings.particleRadius)
      _fluidConstants = Engine.Device.makeBuffer(bytes: &fluidConstants, length: FluidConstants.size, options: [])
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
        refreshVertexBuffer()
        refreshFluidConstants()
        updatePipeVertexBuffers()

        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        // Vertex
        renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
        //Fragment
        renderCommandEncoder.setFragmentBytes(&material, length : CustomMaterial.stride, index : 1)
        mesh.drawPrimitives(renderCommandEncoder)
        pipeVerticesRender(renderCommandEncoder)
//        fluidSystemRender(renderCommandEncoder)
    }
    
    func fluidSystemRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if particleCount > 0{
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Lines))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            
            renderCommandEncoder.setVertexBuffer(_vertexBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&fluidModelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBuffer(_fluidConstants,
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
    
    func pipeVerticesRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if pipeLinesCount > 0 {
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Lines))
                renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            for p in 0..<pipeLinesCount {
                renderCommandEncoder.setVertexBuffer(_pipeVerticesBuffers[p],
                                                     offset: 0,
                                                     index: 0)
                renderCommandEncoder.setVertexBytes(&fluidModelConstants,
                                                    length: ModelConstants.stride,
                                                    index: 2)
                renderCommandEncoder.setVertexBuffer(_fluidConstants,
                                                           offset: 0,
                                                           index: 3)
                renderCommandEncoder.setVertexBuffer(_pipeColorsBuffers[p],
                                                     offset: 0,
                                                     index: 4)

                renderCommandEncoder.drawPrimitives(type: .point,
                                                    vertexStart: 0,
                                                    vertexCount: _pipeVertexCounts[p])
            }
        }
    }
}
