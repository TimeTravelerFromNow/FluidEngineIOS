import MetalKit

enum MiniMenuActions {
    case ToggleMiniMenu
    case ToggleControlPoints
    case ConstructPipe
    
    case MoveObject
    
    case FireGun
    case None
}

// A square button without a representation in the box2d world
class FloatingButton: Node {
    var b2BodyRef: UnsafeMutableRawPointer? // MARK: I know i said it wouldn't be represented, but it's kinda cool wat im doin (used for valves)
    var buttonQuad: Mesh = MeshLibrary.Get(.Quad)
    var buttonTexture: TextureTypes!
    var selectTexture: TextureTypes?
    var miscTexture: TextureTypes?
    var action: MiniMenuActions!
    var sceneAction: ButtonActions!
    var modelConstants = ModelConstants()
    var box2DPos: float2!
    let startSize: float2!
    var size: float2!
    
    var isSelected = false
    var isMiscOn = false
    var selectTime: Float = 0.0
    var selectColor = float4(0.3,0.4,0.1,1.0)
    
    init(_ boxPos: float2, size: float2, action: MiniMenuActions = .None, sceneAction: ButtonActions = .None, textureType: TextureTypes = .Missing, selectTexture: TextureTypes? = nil, miscTexture: TextureTypes? = nil) {
        self.startSize = size
        super.init()
        self.box2DPos = boxPos
        self.size = size
        self.action = action
        self.sceneAction = sceneAction
        self.buttonTexture = textureType
        self.selectTexture = selectTexture
        self.setPositionZ(0.1)
        refreshModelConstants()
    }
    
    func setButtonSizeFromQuad() {
        
    }
    
    func boxMoveX(_ delta: Float) {
        box2DPos.x += delta
        refreshModelConstants()
    }
    func setScaleRatio(_ to: Float) {
        size = startSize * to
        refreshModelConstants()
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
        self.setScaleX(GameSettings.stmRatio * size.x  )
        self.setScaleY(GameSettings.stmRatio * size.y )
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
    func setBoxPosition(_ to: float2) {
        box2DPos = to
        refreshModelConstants()
    }
    
    func miniMenuHitTest(_ parentOffset: float2, _ atPos: float2) -> MiniMenuActions? {
        let boxCenter = box2DPos + parentOffset
        if ( ( ( (boxCenter.x - size.x) < atPos.x) && (atPos.x < (boxCenter.x + size.x) ) ) &&
             ( ( (boxCenter.y - size.y) < atPos.y) && (atPos.y < (boxCenter.y + size.y) ) )  ){
            return action
        }
        return nil
    }
    
    func hitTest( _ atPos: float2 ) -> ButtonActions? {
        if ( ( ( (box2DPos.x - size.x) < atPos.x) && (atPos.x < (box2DPos.x + size.x) ) ) &&
             ( ( (box2DPos.y - size.y) < atPos.y) && (atPos.y < (box2DPos.y + size.y) ) )  ){
            return sceneAction
        }
        return nil
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        if isSelected {
        selectTime += deltaTime
        }
    }
}

extension FloatingButton: Renderable {
    func doRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        if( isSelected ) {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.RadialSelect))
            renderCommandEncoder.setFragmentBytes(&selectColor, length: float4.size, index: 2)
            renderCommandEncoder.setFragmentBytes(&selectTime, length : Float.size, index : 0)
        }
        
        renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
        buttonQuad.drawPrimitives(renderCommandEncoder, baseColorTextureType: isSelected ? (selectTexture ?? buttonTexture) : (isMiscOn ? (miscTexture ?? buttonTexture) : buttonTexture) )
    }
    
}
