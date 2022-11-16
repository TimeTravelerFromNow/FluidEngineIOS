import MetalKit

class HomeBase: GameObject {
    private var _selectColors : [TubeSelectColors:float3] =  [ .SelectHighlight: float3(1.0,1.0,1.0),
                                                             .Reject  : float3(1.0,0.0,0.0),
                                                             .Finished: float3(1.0,1.0,0.0) ]
    private var _baseRef: UnsafeMutableRawPointer!
    
    var boxVertices: [Vector2D]!
        
    private var _selected: Bool = false
    
    init(position: float2,
         meshType: MeshTypes,
         textureType: TextureTypes,
         scale: Float = 1.5) {
        super.init(meshType)
        
        setTexture(textureType)
        renderPipelineStateType = .Basic
        boxVertices = getBoxVertices( scale )
        self.setScale(GameSettings.stmRatio / scale )
        self.setPositionZ(0.11)
//        _baseRef = LiquidFun.makeAlien(Vector2D(x:position.x,y:position.y), vertices: &boxVertices, vertexCount: boxVertices.count)
     
        updateModelConstants()
    }
    
    func boxHitTest( _ atPos: float2) -> ButtonActions? {
//        if LiquidFun.boxIs(atPosition: Vector2D(x: atPos.x, y: atPos.y), boxRef: _alienRef) {
//            self._selected = true
//            return buttonAction
//        } else {
//            return nil
//        }
        return nil
    }
    
    func deSelect() { _selected = false }
    func select() { _selected = true }
    
    func freeze() {
//        LiquidFun.freezeButton(_boxRef)
    }
    func unFreeze() {
//        if( !isStatic ) {
//        LiquidFun.unFreezeButton(_boxRef)
//        }
        }
    
    func updateModelConstants() {
        setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        setRotationZ( getRotationZ() )
        LiquidFun.updateBoxButton(_baseRef)
//        if let textObject = _textObject {
//            textObject.setTransformation( float2(self.getPositionX(), self.getPositionY()), -self.getRotationZ())
//        }
        modelConstants.modelMatrix = modelMatrix
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
//        if let _textObject = _textObject {
//            _textObject.update(deltaTime: deltaTime)
//        }
    }
    
    func getBoxPositionX() -> Float {
        return Float(LiquidFun.getBoxButtonPosition(_baseRef).x)
    }
    func getBoxPositionY() -> Float {
        return Float(LiquidFun.getBoxButtonPosition(_baseRef).y)
    }
    
    override func getRotationZ() -> Float {
        return LiquidFun.getBoxButtonRotation(_baseRef)
    }
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        updateModelConstants()
        if _selected {
            var gameTime = GameTime.TotalGameTime
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.RadialSelect))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            // Vertex
            renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
            //Fragment
            renderCommandEncoder.setFragmentBytes(&gameTime, length : Float.size, index : 0)
            renderCommandEncoder.setFragmentBytes(&material, length : CustomMaterial.stride, index : 1)
            renderCommandEncoder.setFragmentBytes(&_selectColors[.SelectHighlight], length : float3.size, index : 2)
            
            mesh.drawPrimitives(renderCommandEncoder)
        } else {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(renderPipelineStateType))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        
        renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)
        renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1 )
        if(!material.useMaterialColor) {
                   renderCommandEncoder.setFragmentTexture(texture, index: 0)
        }
            mesh.drawPrimitives(renderCommandEncoder, baseColorTextureType: .Missing)
        super.render(renderCommandEncoder)
        }
    }
}
