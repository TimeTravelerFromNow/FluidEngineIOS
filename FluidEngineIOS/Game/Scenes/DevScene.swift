import Foundation
import CoreHaptics

class DevScene : Scene {
    
    var buttons: [ BoxButton ] = []
    var floatingButtons: [ FloatingButton ] = []
    var particleSystem: UnsafeMutableRawPointer?
    
    var gunTruck: GunTruck!
    var island: Island!
    var environmentBox: EdgeBox!
    let islandCenter = float2(0, -3.5)
    
    var pauseButton: FloatingButton!
    var buttonPressed: ButtonActions!
    
    var leftArrow: FloatingButton!
    var rightArrow: FloatingButton!
    
    var oceanColor: float3 = float3(0,0.2,0.3)
    
    override func buildScene() {
        

        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0,0.1,1), atIndex: 0)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0.1,0,1), atIndex: 1)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0.1,0,1), atIndex: 2)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0,0.1,1), atIndex: 3)
        
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / GameSettings.ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1, density: GameSettings.Density)
        
        environmentBox = EdgeBox(center: box2DOrigin,
                                 size: float2(20,26),
                                 meshType: .NoMesh,
                                 textureType: .None,
                                 particleSystem: particleSystem)
        
        addChild(environmentBox)
        
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(-1.9, 4.0), label: .MenuLabel)
        
        buttons.append(menuButton)
        addChild(menuButton)
      
        pauseButton = FloatingButton(box2DOrigin + float2(-1.9, 3.0), size: float2(0.35,0.35), sceneAction: .Pause, textureType: .PauseTexture)
        leftArrow = FloatingButton(box2DOrigin + float2(-2.5, -3.0), size: float2(0.5,0.5), sceneAction: .TruckLeft, textureType: .LeftArrowTexture)
        rightArrow = FloatingButton(box2DOrigin + float2(-1, -3.0), size: float2(0.5,0.5), sceneAction: .TruckRight, textureType: .RightArrowTexture)
        addChild(pauseButton)
        addChild(leftArrow)
        addChild(rightArrow)
        floatingButtons.append(leftArrow)
        floatingButtons.append(rightArrow)
        floatingButtons.append(pauseButton)

        LiquidFun.setGravity(float2(0,-9.8065))
        
        gunTruck = GunTruck(origin: box2DOrigin + islandCenter + float2(0,1), scale: 0.2)
        island =  Island(origin: box2DOrigin + islandCenter)
        addChild(gunTruck)
        addChild(island)
        
        let leftOceanPos = float2(x:islandCenter.x - 6, y: islandCenter.y)
        let rightOceanPos =  float2(x:islandCenter.x + 6.0, y: islandCenter.y)
        LiquidFun.createParticleBox(forSystem: particleSystem, position: leftOceanPos, size:  float2(2,2), color: oceanColor)
        LiquidFun.createParticleBox(forSystem: particleSystem, position: rightOceanPos, size: float2(2,2), color: oceanColor)

        (currentCamera as? OrthoCamera)?.setFrameSize(1.5)
        (currentCamera as? OrthoCamera)?.setFrameSize(1)
        (currentCamera as? OrthoCamera)?.setPositionY(box2DOrigin.y + 0.2)

    }
    
    override func freeze() {
        for button in buttons {
            button.freeze()
        }
    }
    override func unFreeze() {
        for button in buttons {
            button.unFreeze()
        }
    }
    
    private func boxButtonHitTest( boxPos: float2) -> ButtonActions? {
        var hits: [ButtonActions] = []
        for b in buttons {
            if let action = b.boxHitTest( boxPos ) {
                hits.append( action )
            }
        }
        
        for fB in floatingButtons {
            if let action = fB.hitTest( boxPos ) {
                hits.append(action)
                fB.isSelected = true
            }
        }
        if hits.count != 0 {
            return hits.first
        }
        return nil
    }

    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        if panVelocity != float2(0.0,0.0) {
            moveOrthoCamera(deltaTime: deltaTime)
        }
        if( Touches.IsDragging ){
            let boxPos = Touches.GetBoxPos()
            if buttonPressed != nil {
                buttonPressed = boxButtonHitTest(boxPos: boxPos )
                if buttonPressed == .TruckLeft {
                    gunTruck.driveReverse( deltaTime )
                }
                if buttonPressed == .TruckRight {
                    gunTruck.driveForward( deltaTime )
                }
                if buttonPressed == nil { // we lost connection
                    deselectButtons()
                }
            }
        }
    }
    
    override func touchesBegan() {
        let boxPos = Touches.GetBoxPos()
        buttonPressed = boxButtonHitTest(boxPos: boxPos )
        if buttonPressed == .TruckLeft {
        }
        if buttonPressed == .TruckRight {
        }
        
        FluidEnvironment.Environment.debugParticleDraw(atPosition: Touches.GetBoxPos())
      
    }
    
    private func deselectButtons() {
        for b in buttons {
            b.deSelect()
        }
        for fB in floatingButtons {
            fB.isSelected = false
        }
    }
    override func touchesEnded() {

        switch buttonPressed {
        case .None:
            print("let go of a button")
        case .ToMenu:
            SceneManager.sceneSwitchingTo = .Menu
        case .Pause:
            FluidEnvironment.Environment.shouldUpdate.toggle()
            SharedBackground.Background.shouldUpdate.toggle()
        case nil:
            print("let go of no button")
        default:
            print("button action not defined in beach scene")
            break
        }
        deselectButtons()
    }
}

