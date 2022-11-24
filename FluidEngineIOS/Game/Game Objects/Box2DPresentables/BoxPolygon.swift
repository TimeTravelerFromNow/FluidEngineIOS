
import MetalKit

class BoxPolygon: GameObject {

    private var _polygonRef: UnsafeMutableRawPointer!
    var getPolygonRef: UnsafeMutableRawPointer! { return _polygonRef }
    var polygonVertices: [float2]!
    
    init(center: float2, scale: Float = 1.0, _ meshType: MeshTypes, _ texture: TextureTypes, asStaticChain: Bool = true) {
        super.init(meshType)
        setTexture(texture)
        renderPipelineStateType = .Basic
        polygonVertices = getBoxVertices(scale)
        let polygonVerticesCount = polygonVertices.count
        self.setPositionZ(0.11)
        self.setScale( GameSettings.stmRatio / scale )
        
        _polygonRef = LiquidFun.makePolygon(&polygonVertices,
                                            vertexCount: Int32(polygonVerticesCount),
                                            location: float2(x: center.x, y: center.y),
                                            asStaticChain: asStaticChain )

        updateModelConstants()
    }
    
    func updateModelConstants() {
        setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        setRotationZ( getRotationZ() )
        modelConstants.modelMatrix = modelMatrix
    }
    
    func getBoxPositionX() -> Float {
        return Float(LiquidFun.getPolygonPosition(_polygonRef).x)
    }
    func getBoxPositionY() -> Float {
        return Float(LiquidFun.getPolygonPosition(_polygonRef).y)
    }
    override func getRotationZ() -> Float {
        return LiquidFun.getPolygonRotation(_polygonRef)
    }
    func getBoxPosition() -> float2 {
        let boxPos = LiquidFun.getPolygonPosition(_polygonRef)
        return float2(x: boxPos.x, y: boxPos.y)
    }
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        updateModelConstants()
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(renderPipelineStateType))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        
        renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)
        renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1 )
        if(!material.useMaterialColor) {
                   renderCommandEncoder.setFragmentTexture(texture, index: 0)
        }
        mesh.drawPrimitives(renderCommandEncoder)
        super.render(renderCommandEncoder)
    }
}
