import MetalKit

enum MiniMenuActions {
    case ToggleMiniMenu
    case ToggleControlPoints
    case ConstructPipe
    
    case MoveObject
    
    case None
}

// A button without a representation in the box2d world
class FloatingButton: Node {
    
    var buttonQuad: Mesh = MeshLibrary.Get(.Quad)
    var buttonTexture: TextureTypes!
    var action: MiniMenuActions!
    var modelConstants = ModelConstants()
    var parentNode: Node!
    var box2DPos: float2!
    var size: float2!
    
    var isSelected = false
    
    init(_ boxPos: float2, size: float2, action: MiniMenuActions = .None, textureType: TextureTypes = .Missing) {
        super.init()
        box2DPos = boxPos
        self.size = size
        let xScale = size.x
        let yScale = size.y
        self.action = action
        self.buttonTexture = textureType
        self.setScaleX(GameSettings.stmRatio * xScale  )
        self.setScaleY(GameSettings.stmRatio * yScale )
        self.setPositionZ(0.1)
    }
    
    func setButtonSizeFromQuad() {
        
    }
    
    func pressButton( closure: () -> Void ) {
        isSelected = true
    }
    func releaseButton( closure: () -> Void ) {
        isSelected = false
    }
}
