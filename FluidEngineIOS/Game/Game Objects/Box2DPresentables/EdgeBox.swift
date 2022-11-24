import MetalKit

class EdgeBox: GameObject {
    
    var edgeVertices: [float2]!
    
    var origin: float2!
    var size: float2!
    
    private var _boxRef: UnsafeMutableRawPointer?
    
    var customTextureType: TextureTypes?
    
    var fluidModelConstants: ModelConstants = ModelConstants()
    var particleSystem: UnsafeMutableRawPointer?
    private var _colorBuffer: MTLBuffer!
    private var _vertexBuffer: MTLBuffer!
    private var _fluidBuffer: MTLBuffer!
    var particleCount: Int = 0
//    private var
    
    init(center: float2, size: float2, meshType: MeshTypes, textureType: TextureTypes?, particleSystem: UnsafeMutableRawPointer?) {
        super.init(meshType)
        self.origin = center
        self.size = size
        setScale(1 / (GameSettings.ptmRatio * 5) )
        self.setPositionZ(0.16)
        fluidModelConstants.modelMatrix = modelMatrix
        
        self.setPositionZ(0.01)
        self.setScale( GameSettings.stmRatio )
        createEdgeBox()
        
        self.particleSystem = particleSystem
        customTextureType = textureType
        refreshFluidBuffer()
    }
    
    private func createEdgeBox(){
        if( _boxRef == nil ) {
            _boxRef = LiquidFun.createEdgeBox(withOrigin: origin, size: size)
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
        var fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
        _fluidBuffer = Engine.Device.makeBuffer(bytes: &fluidConstants, length: FluidConstants.size, options: [])
    }
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if( customTextureType != nil ) {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(renderPipelineStateType))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            
            renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)
            renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1 )
            if(!material.useMaterialColor) {
                       renderCommandEncoder.setFragmentTexture(texture, index: 0)
            }
            mesh.drawPrimitives(renderCommandEncoder, baseColorTextureType: customTextureType!)
            
            super.render(renderCommandEncoder)
        } else {
            super.render(renderCommandEncoder)
        }
        
    }
}

extension EdgeBox: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        refreshVertexBuffer()
        fluidSystemRender( renderCommandEncoder )
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
            
//            renderCommandEncoder.setFragmentBytes(&waterColor, length: float4.stride, index: 0)
            renderCommandEncoder.drawPrimitives(type: .point,
                                                vertexStart: 0,
                                                vertexCount: particleCount)
        }
    }

}
