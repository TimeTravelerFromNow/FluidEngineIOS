import MetalKit

// Joystick for moving the truck (3d)
class Joystick: FloatingButton {
  
    var perturbed: Bool = false { didSet { hasReturnedRotX = false; hasReturnedRotY = false}}
    var joystick: Mesh = MeshLibrary.Get(.Joystick)
    var joystickNode: Node = Node()
    var texture: MTLTexture!
    var textureType: TextureTypes!
    var joystickModelConstants = ModelConstants() // this guy will rotate freely from quad
    var material = CustomMaterial(color: float4(0), useMaterialColor: false, useTexture: true)
    
    let startingXScale: Float!
    let startingYScale: Float!
    
    // shared function:
    var movementFunction: ((Float, float2) -> Void)?
    
    // touchable
    var isTesting: Bool = false
    var isShowingMiniMenu: Bool = false
    init(_ boxPos: float2, size: float2, textureType: TextureTypes! = .JoystickTexture, sceneAction: ButtonActions, movementFunction: ((Float, float2) -> Void)? = nil ) {
        self.movementFunction = movementFunction
        self.startingXScale = size.x * GameSettings.stmRatio
        self.startingYScale = size.y * GameSettings.stmRatio
        super.init(boxPos, size: size, action: .None, sceneAction: sceneAction, textureType: .JoystickMountTexture)
        self.box2DPos = boxPos
        self.size = size
        let xScale = size.x
        var yScale = size.y
        self.texture = Textures.Get( textureType )
        let width = texture.width
        let height = texture.height
        let imageTextureAspect = Float(width)/Float(height)
        if( imageTextureAspect != xScale/yScale) {
            print("FloatingBanner ADVISE::bad scale aspect, autofixing")
            yScale = xScale / imageTextureAspect
        }
        self.addChild(joystickNode)
        self.setPositionX( box2DPos.x / 5)
        self.setPositionY( box2DPos.y / 5)
        self.setScaleX(GameSettings.stmRatio * size.x  )
        self.setScaleY(GameSettings.stmRatio * size.y )
        joystickModelConstants.modelMatrix = modelMatrix
        self.setPositionZ(0.11)
    }
    
    func setJoystickRotationX(_ to: Float) {
        joystickNode.setRotationX(to)
        refreshModelConstants()
    }
    func setJoystickRotationY(_ to: Float) {
        joystickNode.setRotationY(to)
        refreshModelConstants()
    }
    
    func setJoystickRotationZ(_ to: Float) {
        joystickNode.setRotationZ(to)
        refreshModelConstants()
    }
    
    func rotateJoystickX(_ d: Float) {
        joystickNode.rotateX(d)
        refreshModelConstants()
    }
    
    func rotateJoystickY(_ d: Float) {
        joystickNode.rotateY(d)
        refreshModelConstants()
    }
    
    func rotateJoystickZ(_ d: Float) {
        joystickNode.rotateZ(d)
        refreshModelConstants()
    }
    
    override func refreshModelConstants() {
        super.refreshModelConstants()
        joystickModelConstants.modelMatrix = joystickNode.modelMatrix
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
//        setJoystickRotationX( .pi/2 - sin(GameTime.TotalGameTime) )
        if isSelected {
            selectTime += deltaTime
          
        } else if perturbed {
            returnToOriginStep(deltaTime)
        }
    }
    
    // this step drives the joystick in a unique way, returns a  [-1, 1] normalized range for steering
    var joystickVirtual2DPos: float2 = float2(0)
    var offsetPosition: float2 = float2(0)
    func moveJoystickStep(_ deltaTime: Float,_ boxPos: float2) {
        let offset = boxPos - offsetPosition // offset from touched center
        let clampedOffset = clamp( offset, min: -1, max: 1 ) / 3 // target
        
        
        joystickVirtual2DPos = clamp( offset, min: -0.33, max: 0.33 )
        print(joystickVirtual2DPos)
        let xRot = -joystickVirtual2DPos.y
        let yRot = joystickVirtual2DPos.x
        
        joystickNode.setRotationZ(0)
        joystickNode.setRotationY(0)
        joystickNode.setRotationX(0)
        setJoystickRotationY( yRot )

        setJoystickRotationX( xRot )

        movementFunction?(deltaTime, joystickVirtual2DPos)
    }
    
    var hasReturnedRotX = false
    var hasReturnedRotY = false
    let returnSpeed: Float = 2.0
    func returnToOriginStep(_ deltaTime: Float) {
        let currXRot = joystickNode.getRotationX()
        let currYRot = joystickNode.getRotationY()
        if( currXRot > 0 ) {
            if currXRot - deltaTime * returnSpeed <= 0 {
                setJoystickRotationX(0)
                hasReturnedRotX = true
            } else {
                rotateJoystickX(-deltaTime * returnSpeed)
            }
        } else if (currXRot < 0) {
            if currXRot + deltaTime * returnSpeed >= 0 {
                setJoystickRotationX(0)
                hasReturnedRotX = true
            } else {
                rotateJoystickX(deltaTime * returnSpeed)
            }
        } else if (currXRot == 0) {
            hasReturnedRotX = true
        }
        
        if( currYRot > 0 ) {
            if currYRot - deltaTime * returnSpeed <= 0 {
                setJoystickRotationY(0)
                hasReturnedRotY = true
            } else {
                rotateJoystickY(-deltaTime * returnSpeed)
            }
        } else if (currYRot < 0) {
            if currYRot + deltaTime * returnSpeed >= 0 {
                setJoystickRotationY(0)
                hasReturnedRotY = true
            } else {
                rotateJoystickY(deltaTime * returnSpeed)
            }
        } else if (currYRot == 0) {
            hasReturnedRotY = true
        }
        joystickVirtual2DPos.y = -joystickNode.getRotationX()
        joystickVirtual2DPos.x = joystickNode.getRotationY()
        
        if hasReturnedRotX && hasReturnedRotY {
            perturbed = false
        }
    }
    
    override func render( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        super.render(renderCommandEncoder)
        renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1)
        renderCommandEncoder.setVertexBytes(&joystickModelConstants, length: ModelConstants.stride, index: 2)
        joystick.drawPrimitives( renderCommandEncoder, baseColorTextureType: .JoystickTexture )
    }
    
}

extension Joystick: Testable {
    
    func touchesBegan(_ boxPos: float2) {
        perturbed = true
        offsetPosition = boxPos
    }
    
    func touchDragged(_ boxPos: float2, _ deltaTime: Float) {
      
    }
    
    func touchEnded(_ boxPos: float2) {
        
    }
    
    func testingRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        
    }
    
    
}
