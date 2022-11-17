import Foundation
import CoreHaptics

class DevScene : Scene {
    
    var buttons: [ BoxButton ] = []
    var floatingButtons: [ FloatingButton ] = []
    var particleSystem: UnsafeMutableRawPointer?
    
    var alien: BoxPolygon!
    var barrel: BoxPolygon!
    var environmentBox: EdgeBox!
    
    var pauseButton: FloatingButton!
    
    override func buildScene() {
            
        alien = BoxPolygon(center: box2DOrigin, scale: 3.0, .Alien, .AlienTexture )
        addChild(alien)
        
        barrel = BoxPolygon(center: box2DOrigin + float2(0,-4), scale: 1.0, .Barrel, .BarrelTexture )
        addChild(barrel)

        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0,0.1,1), atIndex: 0)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0.1,0,1), atIndex: 1)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0.1,0,1), atIndex: 2)
        CustomMeshes.Get(.SkyQuad).updateVertexColor(float4(0,0,0.1,1), atIndex: 3)
        
        particleSystem = LiquidFun.createParticleSystem(withRadius: GameSettings.particleRadius / GameSettings.ptmRatio,
                                                        dampingStrength: GameSettings.DampingStrength,
                                                        gravityScale: 1, density: GameSettings.Density)
        
        environmentBox = EdgeBox(center: box2DOrigin,
                                 size: float2(5,10),
                                 meshType: .Asteroid,
                                 textureType: .AsteroidTexture,
                                 particleSystem: particleSystem)
        LiquidFun.setGravity(Vector2D(x:0,y:0))
        addChild(environmentBox)
        
        let menuButton = BoxButton(.Menu,.Menu, .ToMenu, center: box2DOrigin + float2(0.0, 1.0), label: .MenuLabel)
        
        buttons.append(menuButton)
        addChild(menuButton)
        pauseButton = FloatingButton(box2DOrigin + float2(0.0, 3.0), size: float2(1.5,1.5), textureType: .ControlPointsTexture)
        addChild(pauseButton)
        floatingButtons.append(pauseButton)
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
            }
        }
        if hits.count != 0 {
            return hits.first
        }
        return nil
    }
    
    private func switchToTestTubeScene() {
        SceneManager.SetCurrentScene(.TestTubes)
        SceneManager.currentScene.sceneSizeWillChange()
    }

    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        if panVelocity != float2(0.0,0.0) {
            moveOrthoCamera(deltaTime: deltaTime)
        }
    }
    
    var pColor = float4(1,1,0,1)
    override func touchesBegan() {
        switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
        case .None:
            print("hit a test button")
        case .Clear:
            print("hit the clear button")
        case .NewGame:
            print("hit the new game button")
        case nil:
            print("clicked no button")
        default:
            print("clicked a button")
        }
        FluidEnvironment.Environment.debugParticleDraw(atPosition: Touches.GetBoxPos())
        LiquidFun.createParticleBall(forSystem: particleSystem, position: Vector2D(x:box2DOrigin.x,y:box2DOrigin.y - 2.6), velocity: Vector2D(x:0,y:210), angV: -3, radius: 0.3, color: &pColor)
    }
    
    override func touchesEnded() {
        switch boxButtonHitTest(boxPos: Touches.GetBoxPos()) {
        case .None:
            print("let go of a button")
        case .ToMenu:
            SceneManager.sceneSwitchingTo = .Menu
        case nil:
            print("let go of no button")
        default:
            print("button action not defined in beach scene")
            break
        }
        for b in buttons {
            b.deSelect()
        }
    }
}

