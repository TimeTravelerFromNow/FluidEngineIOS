
class TruckObject: Node {
    
    var engineOn: Bool = true
    var truckBody: Friendly!
    var tire0: Friendly!
    var tire1: Friendly!
    
    private var vibrateUp = false
    private var angV: Float = 0.0
    let defaultVibeDelay: Float = 0.1
    private var _vibeDelay: Float = 0.1
    
    private var startParking = false
    private var _parkDelay: Float = 0.4
    let defaultParkDelay: Float = 0.4
    
    private var startingEngine = false
    private var _startEngineDelay: Float = 0.2
    let defaultEngineStart: Float = 0.2
    let tire0Offset: float2!
    let tire1Offset: float2!
    
    init(origin: float2, scale: Float = 1.0) {
        tire0Offset = float2(-0.9 / scale, -0.44 / scale)
        tire1Offset = float2(0.9 / scale, -0.44 / scale)
        super.init()
        
        truckBody = Friendly(center: origin, scale: scale, .Truck, density: 150.0)
        truckBody.setAsPolygonShape()
       
        tire0 = Friendly(center: origin + tire0Offset, scale: scale, .Quad, density: 10.0, restitution: 0.1)
        tire1 = Friendly(center: origin + tire1Offset, scale: scale, .Quad, density: 10.0, restitution: 0.1)
        tire0.setPositionZ(0.1)
        tire1.setPositionZ(0.1)
        tire0.setAsCircle(0.4 / scale, circleTexture: .TruckTireTexture)
        tire1.setAsCircle(0.4 / scale, circleTexture: .TruckTireTexture)
        
        LiquidFun.weldJointFriendlies( truckBody.getFriendlyRef, friendly1: tire0.getFriendlyRef, weldPos: Vector2D(x:tire0Offset.x,y:tire0Offset.y), stiffness: 0.1 )
        LiquidFun.weldJointFriendlies( truckBody.getFriendlyRef, friendly1: tire1.getFriendlyRef, weldPos: Vector2D(x:tire1Offset.x,y:tire1Offset.y), stiffness: 0.1 )
        LiquidFun.setFriendlyFixedRotation(tire0.getFriendlyRef, to: false)
        LiquidFun.setFriendlyFixedRotation(tire1.getFriendlyRef, to: false)
        addChild(truckBody)
        addChild(tire0)
        addChild(tire1)
    }
    
    func applyTorque(_ amt: Float) {
        if( engineOn ) {
        LiquidFun.torqueFriendly( tire0.getFriendlyRef, amt: amt )
        LiquidFun.torqueFriendly( tire1.getFriendlyRef, amt: amt )
        } else {
            startingEngine = true
        }
    }
    
    private func getAngV() {
        angV = LiquidFun.getFriendlyAngV( tire0.getFriendlyRef )
    }
    
    private func engineVibrationImpulse() {
        if vibrateUp {
            vibrateUp.toggle()
        LiquidFun.impulseFriendly( truckBody.getFriendlyRef, imp: Vector2D(x: 0, y: 2), atPt: Vector2D(x:tire1Offset.x, y:tire1Offset.y + 0.25))
        } else {
            vibrateUp.toggle()
        LiquidFun.impulseFriendly( truckBody.getFriendlyRef, imp: Vector2D(x: 0, y: -2), atPt: Vector2D(x:tire1Offset.x, y:tire1Offset.y + 0.25))
        }
        getAngV()
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        
        if( startingEngine ){
            if _startEngineDelay > 0.0 {
                _startEngineDelay -= deltaTime
            } else {
                startingEngine = false
                engineOn = true
                LiquidFun.setFriendlyAngularVelocity( tire0.getFriendlyRef, angV: 0)
                LiquidFun.setFriendlyAngularVelocity( tire1.getFriendlyRef, angV: 0)

                LiquidFun.setFriendlyFixedRotation( tire0.getFriendlyRef, to: false)
                LiquidFun.setFriendlyFixedRotation( tire1.getFriendlyRef, to: false)
            }
            if _vibeDelay > 0.0 {
                _vibeDelay -= deltaTime
            } else {
                engineVibrationImpulse()
                _vibeDelay = defaultVibeDelay
            }
        }
        
        if( engineOn ){
           
            if _vibeDelay > 0.0 {
                _vibeDelay -= deltaTime
            } else {
                engineVibrationImpulse()
                if abs(angV) < 3.0 {
                    startParking = true
                } else {
                    startParking = false
                }
                if abs(angV) < 1.0 {
                    startParking = true
                    if angV < 0.0 {
                        angV = -1.0
                    }
                    else {
                        angV = 1.0
                    }
                }
                _vibeDelay = defaultVibeDelay / abs(angV) // more frequent with higher rpm.
            }
        }
        if( startParking ) {
            if( _parkDelay > 0.0 ){
                _parkDelay -= deltaTime
            } else {
                _parkDelay = defaultParkDelay
                startParking = false
                engineOn = false
                LiquidFun.setFriendlyFixedRotation( tire0.getFriendlyRef, to: true)
                LiquidFun.setFriendlyFixedRotation( tire1.getFriendlyRef, to: true)
            }
        }
    }
    
}
