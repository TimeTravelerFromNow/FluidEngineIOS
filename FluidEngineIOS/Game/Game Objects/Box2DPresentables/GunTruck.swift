
class GunTruck: Node {
    
    var barrel: Friendly!
    var mount: Friendly!
    
    var particleSystem: UnsafeMutableRawPointer!
    
    let fireButtonOffset = float2(-1.0, -0.3)
    var fireButton: FloatingButton!
    var truck: TruckObject!

    var barrelTop: float2 = float2(0, 0.5)
    var pColor = float4(1,1,0,1)

    init(origin: float2, scale: Float = 2.0, particleSystem: UnsafeMutableRawPointer) {
        super.init()
        self.particleSystem = particleSystem
        self.mount = Friendly( center: origin, scale: scale, .Quad, density: 1.0 )
        self.barrel = Friendly( center: origin, scale: scale, .Barrel, density: 1.0 )
        self.fireButton = FloatingButton(origin + fireButtonOffset, size: float2(0.35,0.35), sceneAction: .Fire, textureType: .FireButtonUp, selectTexture: .FireButton)

        barrelTop = origin + float2(0,0.2)
        self.barrel.setAsPolygonShape()
        self.mount.setAsCircle(0.2 / scale, circleTexture: .MountTexture)
        truck = TruckObject(origin: origin, scale: 1.5 * scale)
        addChild(truck)
        addChild(fireButton)
        addChild(barrel)
        addChild(mount)
        self.mount.setPositionZ(0.11)
        self.fireButton.setPositionZ(0.12)
        self.truck.setPositionZ(0.12)
        LiquidFun.weldJointFriendlies(barrel.getFriendlyRef, friendly1: mount.getFriendlyRef, weldPos: Vector2D(x:0,y:0), stiffness: 1.0 )
        LiquidFun.weldJointFriendlies(mount.getFriendlyRef, friendly1: truck.truckBody.getFriendlyRef, weldPos: Vector2D(x:0.3,y:0), stiffness: 0.0)
    }
    
    func setBaseAngularV(_ to: Float) {
        
        LiquidFun.setFriendlyAngularVelocity(mount.getFriendlyRef, angV: to)
    }
    func updateFireButtonModelConstants() {
        fireButton.box2DPos = float2(mount.getBoxPositionX() + fireButtonOffset.x, mount.getBoxPositionY() + fireButtonOffset.y)
        fireButton.refreshModelConstants()
    }
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        updateFireButtonModelConstants()
        if( torqueBuildUp > 20 ) {
            torqueBuildUp -= deltaTime * 20
        }
    }
    
    var torqueBuildUp: Float = 20.0
    func truckLeft() {
        truck.applyTorque( torqueBuildUp )
        if torqueBuildUp < 100.0 {
        torqueBuildUp += 1.0
        }
    }
    func truckRight() {
        truck.applyTorque( -torqueBuildUp )
        if torqueBuildUp < 100.0 {
        torqueBuildUp += 1.0
        }
    }
    
    func fireAt( _ boxPos: float2 ) {
        let currGunPos = barrel.getBoxPosition()
        let vel = boxPos - currGunPos
        let exitV = Vector2D(x:vel.x,y:vel.y)
        LiquidFun.createParticleBall(forSystem: particleSystem, position: Vector2D(x:currGunPos.x,y:currGunPos.y + 1.0), velocity: exitV, angV: 0, radius: 0.3, color: &pColor)
    }
    
    //testables
    var isTesting: Bool = false
    var isShowingMiniMenu: Bool = false
}

extension GunTruck: Touchable {
   
    func touchesBegan(_ boxPos: float2) {
        if( fireButton.hitTest(boxPos) == .Fire ) {
            fireButton.isSelected = true
            LiquidFun.createParticleBall(forSystem: particleSystem, position: Vector2D(x:barrelTop.x,y:barrelTop.y), velocity: Vector2D(x:0,y:10), angV: 0, radius: 0.3, color: &pColor)
        }
    }
    
    func touchDragged(_ boxPos: float2) {
        if fireButton.isSelected {
        if( fireButton.hitTest(boxPos) != .Fire ) {
            fireButton.isSelected = false
        }
        }
    }
    
    func touchEnded() {
        fireButton.isSelected = false
    }
    
    func testingRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        
    }
}
