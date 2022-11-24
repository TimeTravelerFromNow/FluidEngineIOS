
class TruckObject: Node {
    
    var truckBody: Friendly!
    var tire0: Friendly!
    var tire1: Friendly!

    let tire0Offset: float2!
    let tire1Offset: float2!
    
    var isParking = false { didSet { _parkDelay = defaultParkDelay }}
    let defaultParkDelay: Float = 0.2
    var _parkDelay: Float = 0.2
    
    var health: Float = 10.0
    
    init(origin: float2, scale: Float = 1.0) {
        tire0Offset = float2(-0.9 / scale, -0.64 / scale)
        tire1Offset = float2(0.9 / scale, -0.64 / scale)
        super.init()
        
        truckBody = Friendly(center: origin, scale: scale, .Truck, density: 60.0)
        truckBody.setAsPolygonShape()
       
        tire0 = Friendly(center: origin + tire0Offset, scale: scale, .Quad, density: 100.0, restitution: 0.1)
        tire1 = Friendly(center: origin + tire1Offset, scale: scale, .Quad, density: 100.0, restitution: 0.1)
        tire0.setPositionZ(0.09)
        tire1.setPositionZ(0.09)
        tire0.setAsCircle(0.5 / scale, circleTexture: .TruckTireTexture)
        tire1.setAsCircle(0.5 / scale, circleTexture: .TruckTireTexture)
        
        LiquidFun.wheelJointFriendlies( truckBody.getFriendlyRef, friendlyB: tire0.getFriendlyRef, jointPos: tire0Offset, stiffness: 10, damping: 0.5 )
        LiquidFun.wheelJointFriendlies( truckBody.getFriendlyRef, friendlyB: tire1.getFriendlyRef, jointPos: tire1Offset, stiffness: 10, damping: 0.5 )
        LiquidFun.setFriendlyFixedRotation(tire0.getFriendlyRef, to: false)
        LiquidFun.setFriendlyFixedRotation(tire1.getFriendlyRef, to: false)
        addChild(truckBody)
        addChild(tire0)
        addChild(tire1)
    }
    
    private func updateTruckHealth() {
        let wheel0 = tire0.health
        let wheel1 = tire1.health
        let chassis = truckBody.health
        var change: Float = 0
        tire0.updateHealth()
        tire1.updateHealth()
        truckBody.updateHealth()
        change += tire0.health - wheel0!
        change += tire1.health - wheel1!
        change += truckBody.health - chassis!
        health += change
    }
    
    func applyTorque(_ amt: Float) {
        LiquidFun.torqueFriendly( tire0.getFriendlyRef, amt: amt )
        LiquidFun.torqueFriendly( tire1.getFriendlyRef, amt: amt )
        
        LiquidFun.setFriendlyFixedRotation(tire0.getFriendlyRef, to: false)
        LiquidFun.setFriendlyFixedRotation(tire1.getFriendlyRef, to: false)
        isParking = false
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        updateTruckHealth()
        if !isParking {
            let b2Vel = LiquidFun.getFriendlyVel(truckBody.getFriendlyRef)
            if( length(float2(b2Vel.x,b2Vel.y)) > 0.1) {
                return
            }
            if( _parkDelay > 0.0 ){
                _parkDelay -= deltaTime
            } else {
                isParking = true
                LiquidFun.setFriendlyVelocity(truckBody.getFriendlyRef, velocity: float2(0))
                LiquidFun.setFriendlyAngularVelocity(truckBody.getFriendlyRef, angV: 0)
                LiquidFun.setFriendlyAngularVelocity(tire0.getFriendlyRef, angV: 0)
                LiquidFun.setFriendlyAngularVelocity(tire1.getFriendlyRef, angV: 0)
                
            }
        } else {
            LiquidFun.setFriendlyAngularVelocity(tire0.getFriendlyRef, angV: 0)
            LiquidFun.setFriendlyAngularVelocity(tire1.getFriendlyRef, angV: 0)
            
            LiquidFun.setFriendlyFixedRotation(tire0.getFriendlyRef, to: true)
            LiquidFun.setFriendlyFixedRotation(tire1.getFriendlyRef, to: true)
        }
    }
}
