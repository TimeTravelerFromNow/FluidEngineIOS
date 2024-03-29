import MetalKit

class DebugEnvironment : Node {
    
    var shouldUpdate = true
    var isDebugging = false
    var particleCount: Int = 0
    var waterColor: float4 = float4(0.1,0.1,0.9,1.0)
    private var ptmRatio: Float!
    private var pointSize: Float!
    
    private var _vertexBuffer: MTLBuffer!
    private var _fluidBuffer: MTLBuffer!
    
    var jointTest: UnsafeMutableRawPointer!
    
    var pointsCount: Int = 0
    var drawPointsPositions: UnsafeMutableRawPointer!

    var linesCount: Int = 0
    var drawLinesVertices: UnsafeMutableRawPointer!

    var trianglesVerticesCount: Int = 0
    var drawTrianglesVertices: UnsafeMutableRawPointer! // you can see sort of how this ports from vertices in my Box2D DebugDraw methods
                                                        // to each MTLBuffer
    private var _pointsPositionsBuffer: MTLBuffer!
    private var _pointsColorsBuffer: MTLBuffer!
    private var _pointsSizesBuffer: MTLBuffer!
    
    private var _linesVertexBuffer: MTLBuffer!
    private var _linesColorBuffer: MTLBuffer!

    private var _trianglesBuffer: MTLBuffer!
    
    private var _gravity: float2 = [0,-9.80665]
    var particleSystem: UnsafeMutableRawPointer!
    private var _worldBoundingBox: UnsafeMutableRawPointer!
    
    var modelConstants = ModelConstants()
    
    var mesh: Mesh!
    var texture: MTLTexture!

    var debugColor: float3 = float3(1,0,0)
    
    override init() {
        super.init()
        self.ptmRatio = GameSettings.ptmRatio
        self.pointSize = 1
        self.setScale(1 / (GameSettings.ptmRatio * 5) )
        self.setPositionZ(0.11)
        self.MakeWorld()
    }
    
    deinit {
      LiquidFun.destroyWorld()
    }
    
    override func update(deltaTime: Float) {
        if shouldUpdate {
        LiquidFun.worldStep(CFTimeInterval(deltaTime), velocityIterations: 8 * Int32(GameTime.TimeScale), positionIterations: 3 * Int32(GameTime.TimeScale))
        updateModelConstants()
        }
    }
    
    func setGravity( x: Float, y: Float) {
        _gravity = float2(x,y)
        LiquidFun.setGravity(float2(x: x,y: y))
    }
    
    func updateModelConstants() {
        modelConstants.modelMatrix = modelMatrix
    }
    
    func refreshFluidBuffer () {
      var fluidConstants = FluidConstants(ptmRatio: ptmRatio, pointSize: GameSettings.particleRadius)
      _fluidBuffer = Engine.Device.makeBuffer(bytes: &fluidConstants, length: FluidConstants.size, options: [])
    }
    func refreshVertexBuffer () {
        if particleSystem != nil {
            particleCount = Int(LiquidFun.particleCount(forSystem: particleSystem))
            if particleCount > 0 {
                let positions = LiquidFun.particlePositions(forSystem: particleSystem)
                let bufferSize = float2.stride(particleCount)
                _vertexBuffer = Engine.Device.makeBuffer(bytes: positions!, length: bufferSize, options: [])
            }
        }
    }
    //debug draw
    func refreshDrawBuffer() {
        pointsCount = Int(LiquidFun.getPointsDrawCount())
        if pointsCount > 0{
            let positions = LiquidFun.getPointsPositions()
            let bufferSize = float2.stride(pointsCount)
            _pointsPositionsBuffer = Engine.Device.makeBuffer(bytes: positions!, length: bufferSize, options: [])
            let colors = LiquidFun.getPointsColors()
            let colorBufferSize = float3.stride(pointsCount)
            _pointsColorsBuffer = Engine.Device.makeBuffer(bytes: colors!, length: colorBufferSize, options: [])
        }
        linesCount = Int(LiquidFun.getLinesDrawCount())
        if linesCount > 0 {
            let linesVertices = LiquidFun.getLinesVertices()
            let linesBufferSize = float2.stride(linesCount)
            _linesVertexBuffer = Engine.Device.makeBuffer(bytes: linesVertices!, length: linesBufferSize, options: [])
            let colors = LiquidFun.getPointsColors()
            let colorBufferSize = float3.stride(linesCount)
            _linesColorBuffer = Engine.Device.makeBuffer(bytes: colors!, length: colorBufferSize, options: [])
        }
        trianglesVerticesCount = Int(LiquidFun.getTrianglesDrawCount())
        if trianglesVerticesCount > 0 {
            let triangleVertices = LiquidFun.getTrianglesVertices()
            let trianglesBufferSize = float2.stride(trianglesVerticesCount)
            _trianglesBuffer = Engine.Device.makeBuffer(bytes: triangleVertices!, length: trianglesBufferSize, options: [])
        }
    }

    private func MakeWorld() {
        LiquidFun.createWorld(withGravity: float2(x: _gravity.x, y: _gravity.y))
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1, density: GameSettings.Density)
    }
    
    func makeBoundingBox(center: float2, size: float2) {
        if _worldBoundingBox == nil {
        let boxCenter = float2(x: center.x, y: center.y )
        _worldBoundingBox = LiquidFun.createEdgeBox(withOrigin: boxCenter, size: size)
        } else { print("bounding box already made.")}
    }
    
    func destroyBoundingBox() {
        if _worldBoundingBox != nil {
            LiquidFun.destroyBody(_worldBoundingBox)
            _worldBoundingBox = nil
        } else { print("bounding box already destroyed")}
    }
    
    func debugParticleDraw(atPosition: float2) {
        if !isDebugging { return }
        if particleSystem != nil {
            print("debugParticleDraw at: x: \(atPosition.x), \(atPosition.y)")
        LiquidFun.createParticleBox(forSystem: particleSystem,
                                    position: float2(x: atPosition.x, y: atPosition.y),
                                    size: float2( 0.1, 0.1),
                                    color: debugColor)
        } else { print("trying to debug draw particle at (x: \(atPosition.x), y: \(atPosition.y)) without having initialized the particle system")}
    }
}

extension DebugEnvironment: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if isDebugging {
        refreshDrawBuffer()
        }
        refreshVertexBuffer()
        refreshFluidBuffer()
        fluidSystemRender(renderCommandEncoder)
        if isDebugging{
        pointsRender( renderCommandEncoder )
        linesRender(renderCommandEncoder)
//        trianglesRender(renderCommandEncoder)
        }
    }
    
    func trianglesRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if trianglesVerticesCount > 0 {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Lines))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            
            renderCommandEncoder.setVertexBuffer(_trianglesBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBuffer(_fluidBuffer,
                                                       offset: 0,
                                                       index: 3)
            renderCommandEncoder.drawPrimitives(type: .triangle,
                                                vertexStart: 0,
                                                vertexCount: trianglesVerticesCount,
                                                instanceCount: 1)
        }
    }

    func linesRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if linesCount > 0 {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Lines))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            
            renderCommandEncoder.setVertexBuffer(_linesVertexBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBytes(&modelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBuffer(_fluidBuffer,
                                                       offset: 0,
                                                       index: 3)
            renderCommandEncoder.setVertexBuffer(_linesColorBuffer,
                                                       offset: 0,
                                                       index: 4)
            renderCommandEncoder.drawPrimitives(type: .line,
                                                vertexStart: 0,
                                                vertexCount: linesCount,
                                                instanceCount: 1)
        }
        
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
            renderCommandEncoder.setVertexBytes(&waterColor, length: float4.stride, index: 4)
            renderCommandEncoder.setFragmentBytes(&waterColor, length: float4.stride, index: 0)
            renderCommandEncoder.drawPrimitives(type: .point,
                                                vertexStart: 0,
                                                vertexCount: particleCount)
        }
    }
    
    func pointsRender( _ renderCommandEncoder: MTLRenderCommandEncoder ){
        if pointsCount > 0 {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Points))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        
        renderCommandEncoder.setVertexBuffer(_pointsPositionsBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(_pointsColorsBuffer,
                                             offset: 0,
                                             index: 4)
        renderCommandEncoder.setVertexBytes(&modelConstants,
                                            length: ModelConstants.stride,
                                            index: 2)
        renderCommandEncoder.setVertexBuffer(_fluidBuffer,
                                                   offset: 0,
                                                   index: 3)
        renderCommandEncoder.drawPrimitives(type: .point,
                                             vertexStart: 0,
                                             vertexCount: pointsCount
                                             )
        }
                                    
}
    
}
