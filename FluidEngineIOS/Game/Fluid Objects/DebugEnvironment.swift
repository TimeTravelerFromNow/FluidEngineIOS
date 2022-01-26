import MetalKit

class DebugEnvironment : Node {
    
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
    var modelConstants = ModelConstants()
    
    var mesh: Mesh!
    var texture: MTLTexture!

    override init() {
        super.init()
        self.ptmRatio = GameSettings.ptmRatio
        self.pointSize = 1
        self.MakeWorld()
       // self.TestParticles()
    }
    
    deinit {
      LiquidFun.destroyWorld()
    }
    
    override func update(deltaTime: Float) {
        LiquidFun.worldStep(CFTimeInterval(deltaTime * GameSettings.TimeScale), velocityIterations: 8, positionIterations: 3)
        updateModelConstants()
    }
    
    func setGravity( x: Float, y: Float) {
        _gravity = float2(x,y)
        LiquidFun.setGravity(Vector2D(x: x,y: y))
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
        LiquidFun.createWorld(withGravity: Vector2D(x: _gravity.x, y: _gravity.y))
        let simulationFrame: float2 = Renderer.ScreenSize
        let screenWidth = simulationFrame.x
        let screenHeight = simulationFrame.y

        LiquidFun.createEdgeBox(withOrigin: Vector2D(x: -0.5, y: 0),
                                size: Size2D(width: screenWidth * 2 / ptmRatio, height: screenHeight * 2 / ptmRatio)) // square
        var sensorVertices : [Vector2D] = [
            Vector2D(x: 1, y: 1),
            Vector2D(x: -1, y: 1),
            Vector2D(x: -1, y: -1),
            Vector2D(x: 1, y: -1)
        ]
        var hitBoxVertices : [Vector2D] = [
            Vector2D(x: -1, y: -1),
            Vector2D(x: -1, y: -2),
            Vector2D(x: 1, y: -2),
            Vector2D(x: 1, y: -1)
        ]
//        jointTest = LiquidFun.makeJointTest(Vector2D(x:2,y:2),
//                                box1Vertices: &sensorVertices, box1Count: 4,
//                                box2Vertices: &hitBoxVertices, box2Count: 4)
        // making lines to smooth edge behavior
        var edgeVertices = [Vector2D(x:screenWidth*0.25/ptmRatio - 2.5,y:-1), Vector2D(x:screenWidth*0.25/ptmRatio,y:1.5)]
        var edge2 = [Vector2D(x: 1.5,y:-1), Vector2D(x:-0.5,y:1.0)]
        LiquidFun.createGroundBox(withOrigin: Vector2D(x: -1, y: -1), size: Size2D(width: 0.1, height: 0.1))
        // "Meter Stick"
        LiquidFun.createEdgeBox(withOrigin: Vector2D(x:0,y:screenHeight/2), size: Size2D(width: 1, height: 1))
    }
    func movePointTest(velocity: float2) {
        LiquidFun.moveJointTest(jointTest, velocity: Vector2D(x:velocity.x,y:velocity.y))
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
        trianglesRender(renderCommandEncoder)
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
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Fluid))
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
