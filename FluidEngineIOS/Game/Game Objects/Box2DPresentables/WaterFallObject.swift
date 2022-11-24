import MetalKit

class WaterFallObject: Node {
    
    var cliff: BoxPolygon!
    
    var pineTrees: [GameObject] = []
    
    var particleSystem: UnsafeMutableRawPointer!
    private let _defaultRefillTime: Float = 0.3
    private var _refillDelay: Float = 0.1
    var _color: float3 = float3(0.1, 0.3, 0.9)
    var waterColor: float3 = float3(0.1, 0.3, 0.9)
    var modelConstants = ModelConstants()

    private var ptmRatio: Float!
    
    var particleCount: Int = 0
    var _vertexBuffer: MTLBuffer!
    var _fluidBuffer: MTLBuffer!
    var _colorBuffer: MTLBuffer!
    
    init(center: float2) {
        super.init()
        ptmRatio = GameSettings.ptmRatio
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1,
                                                        density: GameSettings.Density)
        
        self.setPositionZ(0.1)

        self.setScale(2 / (GameSettings.ptmRatio * 10))
        cliff = BoxPolygon( center: center, .Cliff, .Cliff)
        cliff.setScale(GameSettings.stmRatio)
        cliff.updateModelConstants()
        
        pineTrees = [GameObject(.PineTree), GameObject(.PineTree), GameObject(.PineTree),GameObject(.PineTree)]
        
        for (i, pine) in pineTrees.enumerated() {
            pine.setScale(GameSettings.stmRatio)
            pine.setPositionX((cliff.getBoxPositionX() + 0.5 * Float(i - 1)) * GameSettings.stmRatio)
            pine.setPositionY((cliff.getBoxPositionY() + 3.8) * GameSettings.stmRatio)
            pine.setPositionZ(0.4)
            pine.setTexture(.PineTree)
            pine.material.useMaterialColor = false
            pine.renderPipelineStateType = .Basic
        }
                
        LiquidFun.createParticleBox(forSystem: particleSystem,
                                    position: float2(x: cliff.getBoxPositionX() - 1.0, y: cliff.getBoxPositionY() + 5.0) ,
                                    size: float2( 1.0, 1.0),
                                    color: _color)
    }
    
    func getCliff() -> BoxPolygon {
        return cliff
    }
    func getPines() -> [GameObject] {
        return pineTrees
    }
    
    func clearParticles() {
        LiquidFun.destroyParticles(inSystem: particleSystem)
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        updateModelConstants()
        if _refillDelay > 0.0 {
            _refillDelay -= deltaTime
        }
            else {
                LiquidFun.deleteBelow(inParticleSystem: particleSystem, belowYPosition: -3.0)

        LiquidFun.createParticleBox(forSystem: particleSystem,
                                    position: float2(x: cliff.getBoxPositionX() - 1.0, y: cliff.getBoxPositionY() + 5.0) ,
                                    size: float2( 0.5, 0.5),
                                    color: _color)
            _refillDelay = _defaultRefillTime
        }
    }
    
    func updateModelConstants() {
        modelConstants.modelMatrix = modelMatrix
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
        var fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
        _fluidBuffer = Engine.Device.makeBuffer(bytes: &fluidConstants, length: FluidConstants.size, options: [])
    }
    
    func setVelocity(_ to: float2) {
        LiquidFun.moveParticleSystem(particleSystem, byVelocity: float2(x:to.x, y: to.y))
        LiquidFun.setPolygonVelocity(cliff.getPolygonRef, velocity: float2(x:to.x, y: to.y))
    }
}

extension WaterFallObject: Renderable {
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

