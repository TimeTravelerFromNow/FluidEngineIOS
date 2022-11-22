import Foundation
import CoreHaptics

class DevScene : Scene {
    
    var Enemies: [ Alien ] = []
    var buttons: [ BoxButton ] = []
    var floatingButtons: [ FloatingButton ] = []
    var particleSystem: UnsafeMutableRawPointer?
    
    var testAlien: Alien!
    var gunTruck: GunTruck!
    var environmentBox: EdgeBox!
    let islandCenter = float2(0, -6.5)
    var island: BoxPolygon!
    
    var pauseButton: FloatingButton!
    var buttonPressed: ButtonActions!
    
    var leftArrow: FloatingButton!
    var rightArrow: FloatingButton!
    
    var oceanColor: float4 = float4(0,0.2,0.3,1)
    
    override func buildScene() {

        let asteroid = Alien(center: box2DOrigin + float2(0.2,-0.3), scale: 3.0, .Asteroid, .AsteroidTexture, density: 10 )
        let asteroid1 = Alien(center: box2DOrigin + float2(0.2,-0.3), scale: 3.0, .Asteroid, .AsteroidTexture, density: 10 )
        let asteroid2 = Alien(center: box2DOrigin + float2(0.2,-0.3), scale: 3.0, .Asteroid, .AsteroidTexture, density: 10 )
        let asteroid3 = Alien(center: box2DOrigin + float2(0.2,-0.3), scale: 3.0, .Asteroid, .AsteroidTexture, density: 10 )
        
        let testAlien1 = Alien(center: box2DOrigin, scale: 3.0, .Alien, .AlienTexture, density: 1.0 )
        let testAlien2 = Alien(center: box2DOrigin, scale: 3.0, .Alien, .AlienTexture, density: 1.0 )
        let testAlien3 = Alien(center: box2DOrigin, scale: 3.0, .Alien, .AlienTexture, density: 1.0 )
        let testAlien4 = Alien(center: box2DOrigin, scale: 3.0, .Alien, .AlienTexture, density: 1.0 )
        let testAlien5 = Alien(center: box2DOrigin, scale: 3.0, .Alien, .AlienTexture, density: 1.0 )
        let testAlien6 = Alien(center: box2DOrigin, scale: 3.0, .Alien, .AlienTexture, density: 1.0 )
        addChild(asteroid)
        addChild(asteroid1)
        addChild(asteroid2)
        addChild(asteroid3)
        
        addChild(testAlien1)
        addChild(testAlien2)
        addChild(testAlien3)
        addChild(testAlien4)
        addChild(testAlien5)
        addChild(testAlien6)
        Enemies.append(asteroid)
        

        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0,0.1,1), atIndex: 0)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0.1,0,1), atIndex: 1)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0.1,0,1), atIndex: 2)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0,0.1,1), atIndex: 3)
        
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / GameSettings.ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1, density: GameSettings.Density)
        
        environmentBox = EdgeBox(center: box2DOrigin,
                                 size: float2(20,16),
                                 meshType: .NoMesh,
                                 textureType: .None,
                                 particleSystem: particleSystem)
        
        island = BoxPolygon(center: box2DOrigin + islandCenter, .Island, .IslandTexture, asStaticChain: false)
        addChild(island)
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

//        LiquidFun.setGravity(Vector2D(x:0,y:0))
        
        gunTruck = GunTruck(origin: box2DOrigin + islandCenter + float2(0, 1.3), particleSystem: particleSystem!)
        addChild(gunTruck)
        testAlien = Alien(center: box2DOrigin, scale: 3.0, .Alien, .AlienTexture, density: 1.0 )
        addChild(testAlien)
        
        let leftOceanPos = Vector2D(x:islandCenter.x - 10.0, y: islandCenter.y - 2.0)
        let rightOceanPos =  Vector2D(x:islandCenter.x + 10.0, y: islandCenter.y - 2.0)
        LiquidFun.createParticleBox(forSystem: particleSystem, position: leftOceanPos, size:  Size2D(width:4,height:3), color: &oceanColor)
        LiquidFun.createParticleBox(forSystem: particleSystem, position: rightOceanPos, size: Size2D(width:4,height:3), color: &oceanColor)

        
        (currentCamera as? OrthoCamera)?.setFrameSize(1.5)
//        (currentCamera as? OrthoCamera)?.setFrameSize(1)
//        (currentCamera as? OrthoCamera)?.setPositionY(box2DOrigin.y - 1)

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
            (gunTruck as! Touchable ).touchDragged( boxPos )
            if buttonPressed != nil {
                buttonPressed = boxButtonHitTest(boxPos: boxPos )
                if buttonPressed == .TruckLeft {
                    gunTruck.truckLeft( deltaTime )
                }
                if buttonPressed == .TruckRight {
                    gunTruck.truckRight( deltaTime )
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
            gunTruck.truckLeft( 1 / 60 )
        }
        if buttonPressed == .TruckRight {
            gunTruck.truckRight( 1 / 60 )
        }
        ( gunTruck as! Touchable ).touchesBegan( boxPos )
        
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
        ( gunTruck as! Touchable ).touchEnded( )

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

