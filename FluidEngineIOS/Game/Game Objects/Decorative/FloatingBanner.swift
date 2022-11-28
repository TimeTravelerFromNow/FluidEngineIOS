import MetalKit

// A custom banner without a representation in the box2d world
class FloatingBanner: Node {
  
    var quad: Mesh = MeshLibrary.Get(.Quad)
    var texture: MTLTexture!
    var textureType: TextureTypes!
    var label: TextLabels!
    var modelConstants = ModelConstants()
    var box2DPos: float2!
    var size: float2!
    
    var isSelected = false
    var selectTime: Float = 0.0
    var selectColor = float4(0.3,0.4,0.1,1.0)
    
    init(_ boxPos: float2, size: float2, labelType: TextLabelTypes = .None, textureType: TextureTypes = .Missing, selectTexture: TextureTypes? = nil) {
        super.init()
        self.box2DPos = boxPos
        self.size = size
        let xScale = size.x
        var yScale = size.y
        self.texture = Textures.Get( textureType )
        self.textureType = textureType
        let width = texture.width
        let height = texture.height
        let imageTextureAspect = Float(width)/Float(height)
        if( imageTextureAspect != xScale/yScale) {
            print("FloatingBanner ADVISE::bad scale aspect, autofixing")
            yScale = xScale / imageTextureAspect
        }
        self.setScaleX(GameSettings.stmRatio * xScale  )
        self.setScaleY(GameSettings.stmRatio * yScale )
        self.setPositionZ(0.1)
        refreshModelConstants()
    }
    
    func setButtonSizeFromQuad() {
        
    }
    
    func pressButton( closure: () -> Void ) {
        isSelected = true
    }
    
    func releaseButton( closure: () -> Void ) {
        isSelected = false
    }
    
    func refreshModelConstants() {
        self.setPositionX( box2DPos.x / 5)
        self.setPositionY( box2DPos.y / 5)
        modelConstants.modelMatrix = modelMatrix
    }
    
    func getBoxPositionX() -> Float {
        return box2DPos.x
    }
    func getBoxPositionY() -> Float {
        return box2DPos.y
    }
    func getBoxPosition() -> float2 {
        return box2DPos
    }
    override func setPositionZ(_ zPosition: Float) {
        super.setPositionZ( zPosition )
        refreshModelConstants()
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        if isSelected {
        selectTime += deltaTime
        }
    }
}

extension FloatingBanner: Renderable {
    func doRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        if( isSelected ) {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.RadialSelect))
            renderCommandEncoder.setFragmentBytes(&selectColor, length: float4.size, index: 2)
            renderCommandEncoder.setFragmentBytes(&selectTime, length : Float.size, index : 0)
        }
        
        renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
        quad.drawPrimitives(renderCommandEncoder, baseColorTextureType: textureType! )
    }
    
}
