import Foundation
import CoreHaptics

enum ButtonActions {
    case Clear
    case NewGame
    case ToMenu
    case ToDev
    
    case StartGameAction
    case TestAction1
    case TestAction2
    case TestAction3
    
    case Pause
    case Fire
    case TruckLeft
    case TruckRight
    case SteerTruck
    
    case HowitzerSelect
    case MGSelect
    case ShotgunSelect
    
    case None
}

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
    
    var oceanColor: float3 = float3(0,0.2,0.3)
    var startingBanner: FloatingBanner!
    var gunSelectionMenu: GunSelectionMenu!
    var testJoystick: Joystick!
    
    private func makeSkyBlack() {
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0,0.1,1), atIndex: 0)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0.1,0,1), atIndex: 1)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0.1,0,1), atIndex: 2)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0,0.1,1), atIndex: 3)
    }
    
    private func makeSkyGreen() {
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,1,0,1), atIndex: 0)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,1,0,1), atIndex: 1)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,1,0,1), atIndex: 2)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,1,0,1), atIndex: 3)
    }
    
    private func buildButtons() {
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(-1.9, 4.0), label: .MenuLabel)
        
        buttons.append(menuButton)
        addChild(menuButton)
      
        pauseButton = FloatingButton(box2DOrigin + float2(1.9, 4.0), size: float2(0.35,0.35), sceneAction: .Pause, textureType: .PauseTexture)
        let newAlienButton = FloatingButton(box2DOrigin + float2(-1, 1.0), size: float2(0.35,0.35), sceneAction: .TestAction1, textureType: .NewAlienButtonTexture)
        addChild(newAlienButton)
        addChild(pauseButton)
        floatingButtons.append(newAlienButton)
        floatingButtons.append(pauseButton)
    }
    
    override func buildScene() {
//        makeSkyGreen()
        buildButtons()
        
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / GameSettings.ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1, density: GameSettings.Density)
        
        environmentBox = EdgeBox(center: box2DOrigin,
                                 size: float2(20,26),
                                 meshType: .NoMesh,
                                 textureType: .None,
                                 particleSystem: particleSystem)
        
        addChild(environmentBox)
        
        gunTruck = GunTruck(origin: box2DOrigin + islandCenter + float2(0,1), scale: 0.2)
        island =  Island(origin: box2DOrigin + islandCenter)
        addChild(gunTruck)
        addChild(island)
        startingBanner = FloatingBanner(box2DOrigin + float2(0,3), size: float2(3,1.5), labelType: .MenuLabel, textureType: .AlienInfiltratorsBannerTexture)
        startingBanner.setPositionZ(0.2)
        addChild( startingBanner )
        
        gunSelectionMenu = GunSelectionMenu(box2DOrigin, selectionClosure: selectGun )
        addChild( gunSelectionMenu )
        
        let leftOceanPos = float2(x:islandCenter.x - 6, y: islandCenter.y)
        let rightOceanPos =  float2(x:islandCenter.x + 6.0, y: islandCenter.y)
        LiquidFun.createParticleBox(forSystem: particleSystem, position: leftOceanPos, size:  float2(2,2), color: oceanColor)
        LiquidFun.createParticleBox(forSystem: particleSystem, position: rightOceanPos, size: float2(2,2), color: oceanColor)
        
        (currentCamera as? OrthoCamera)?.setFrameSize(1)
//        (currentCamera as? OrthoCamera)?.setFrameSize(0.5)
//        (currentCamera as? OrthoCamera)?.setPositionY(box2DOrigin.y - 0.18)
        
        testJoystick = Joystick( box2DOrigin + float2(0,-3.9), size: float2(0.45,0.45), sceneAction: .SteerTruck, movementFunction: gunTruck.steerTruck)
        addChild(testJoystick)
        floatingButtons.append(testJoystick)
    }
    
    func selectGun( _ gunType: GunTruck.GunTypes ) {
        gunTruck.selectGun( gunType )
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
        if (!pauseButton.isSelected) {
        startingBanner.setScaleRatio( (sin( GameTime.TotalGameTime) + 7.3) / 12.3  )
        }
        if( Touches.IsDragging ){
            let boxPos = Touches.GetBoxPos()
            for c in children {
                if let testable = c as? Testable {
                    testable.touchDragged(boxPos, deltaTime)
                }
            }
            if buttonPressed != nil {
                if buttonPressed == .TruckLeft {
                    gunTruck.driveReverse( deltaTime )
                }
                if buttonPressed == .TruckRight {
                    gunTruck.driveForward( deltaTime )
                }
                if buttonPressed == .SteerTruck {
                    testJoystick.moveJoystickStep(deltaTime, boxPos)
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
        for c in children {
            if let touchable = c as? Testable {
                touchable.touchesBegan(boxPos)
            }
        }
        if buttonPressed == .SteerTruck { // dont
            gunTruck.touchEnded(boxPos)
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
        for c in children {
            if let touchable = c as? Testable {
                touchable.touchEnded(Touches.GetBoxPos())
            }
        }
        switch buttonPressed {
        case .TestAction1:
            let newAlien = Infiltrator(origin: box2DOrigin, scale: 0.4, startingMesh: .Alien)
            addChild(newAlien)
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

