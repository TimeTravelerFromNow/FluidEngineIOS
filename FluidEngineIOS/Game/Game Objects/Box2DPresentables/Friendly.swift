import MetalKit

class Friendly: GameObject {

    private var _friendlyRef: UnsafeMutableRawPointer!
    var getFriendlyRef: UnsafeMutableRawPointer! { return _friendlyRef }
    var boxVertices: [Vector2D]!
    var useCustomTexture = false
    var customTexture: TextureTypes?
    var scale: Float!
    
    init(center: float2, scale: Float = 1.0, _ meshType: MeshTypes, density: Float = 1.0, restitution: Float = 0.9) {
        super.init(meshType)
        self.scale = scale
        renderPipelineStateType = .Basic
        boxVertices = getBoxVertices(scale)
        let polygonVerticesCount = boxVertices.count
        self.setPositionZ(0.1)
        self.setScale( GameSettings.stmRatio / scale )
        
        _friendlyRef = LiquidFun.makeFriendly(Vector2D(x:center.x,y:center.y),
                                        density: density,
                                        restitution: restitution,
                                        health: 1.0,
                                        crashDamage: 0.1,
                                        categoryBits: 0x0001,
                                        maskBits: 0x0001,
                                        groupIndex: 0)
        updateModelConstants()
    }
    
    func setAsPolygonShape() {
        LiquidFun.setFriendlyPolygon(_friendlyRef, vertices:  &boxVertices, vertexCount: boxVertices.count)
    }
    func setAsCircle(_ radius: Float, circleTexture: TextureTypes) {
//        setScale( radius / (GameSettings.ptmRatio * 5) )
        LiquidFun.setFriendlyCircle(_friendlyRef, radius: radius)
        
        mesh = MeshLibrary.Get(.Quad)
        setTexture( circleTexture )
        customTexture = circleTexture
        useCustomTexture = true
        setScale( radius * GameSettings.stmRatio )
        updateModelConstants()
    }
    
    func updateModelConstants() {
        setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        setRotationZ( getRotationZ() )
        modelConstants.modelMatrix = modelMatrix
    }
    
    func getBoxPositionX() -> Float {
        return Float(LiquidFun.getFriendlyPosition(_friendlyRef).x)
    }
    func getBoxPositionY() -> Float {
        return Float(LiquidFun.getFriendlyPosition(_friendlyRef).y)
    }
    override func getRotationZ() -> Float {
        return LiquidFun.getFriendlyRotation(_friendlyRef)
    }
    func getBoxPosition() -> float2 {
        let boxPos = LiquidFun.getFriendlyPosition(_friendlyRef)
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
        if useCustomTexture {
            mesh.drawPrimitives( renderCommandEncoder, baseColorTextureType: customTexture! )
        } else {
        mesh.drawPrimitives(renderCommandEncoder)
        }
    }
}
