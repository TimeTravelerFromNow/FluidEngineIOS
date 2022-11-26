class GunTruck: Infiltrator {
    
    var gunRef: b2Body?
    var frontWheelRef: b2Body?
    var backWheelRef: b2Body?
    var frontWheelJoint: b2Joint?
    var backWheelJoint: b2Joint?
    var frontWheelFixture: b2Fixture?
    var backWheelFixture: b2Fixture?
    
    var truckBodyRef: b2Body! // not optional (everything must rest on chassis, if chassis is gone, entire GunTruck is dead)
    var frontTireOffset: float2!
    var backTireOffset: float2!

    var torqueBuildUp: Float = 0.0
    let maxTorque: Float = 0.1
    let minTorque: Float = 0.01
    let jerk: Float = 1
    let rpmDecay: Float  = 0.1
    let maxVelocity: Float = 0.3
    
    init(origin: float2, scale: Float = 1.0) {
        backTireOffset  = float2(-0.95 * scale, -0.5 * scale)
        frontTireOffset = float2( 0.9 * scale, -0.5 * scale)
        super.init(origin: origin, scale: scale, startingMesh: .Truck, density: 100)
        truckBodyRef = bodyRefs.keys.first!
        buildTruck()
    }
    
    func buildTruck() {
        let filter = BoxFilter(categoryBits: 0x0001, maskBits: 0xFFFF, groupIndex: 0, isFiltering: false)
        frontWheelRef = self.newBody(origin + frontTireOffset, withFilter: filter, name: "front-wheel-body")
        backWheelRef  = self.newBody(origin + backTireOffset, withFilter: filter, name: "back-wheel-body")
        LiquidFun.setAngularDamping( frontWheelRef, amount: 0.1)
        LiquidFun.setAngularDamping( backWheelRef, amount: 0.1)

        frontWheelFixture = attachCircleFixture( scale * 0.5, pos: float2(0), texture: .TruckTireTexture, body: frontWheelRef!)
        backWheelFixture = attachCircleFixture( scale * 0.5, pos: float2(0), texture: .TruckTireTexture, body: backWheelRef!)
        
        setFixtureZPos(frontWheelFixture!, to: 0.09)
        setFixtureZPos(backWheelFixture!, to: 0.09)

        frontWheelJoint = wheelJoint(bodyA: truckBodyRef, bodyB: frontWheelRef!, weldPos: frontTireOffset, localAxisA: float2(0,1), stiffness: 10, damping: 0.5)
        backWheelJoint = wheelJoint(bodyA: truckBodyRef, bodyB: backWheelRef!, weldPos: backTireOffset, localAxisA: float2(0,1), stiffness: 10, damping: 0.5)
        
            LiquidFun.setFixedRotation(frontWheelRef,to: true)
            LiquidFun.setFixedRotation(backWheelRef, to: true)
    }
    
    private func applyTorque(_ amt: Float) {
        LiquidFun.torqueBody( frontWheelRef, amt: amt, awake: true  )
        LiquidFun.torqueBody( backWheelRef, amt: amt, awake: true )
//
//          LiquidFun.setFriendlyFixedRotation(tire0.getFriendlyRef, to: false)
//          LiquidFun.setFriendlyFixedRotation(tire1.getFriendlyRef, to: false)
//          isParking = false
      }

    func driveForward(_ deltaTime: Float) {
      
        if torqueBuildUp < maxTorque {
            torqueBuildUp += deltaTime * (jerk + rpmDecay )
        }
        if torqueBuildUp > minTorque {
            let horizV = LiquidFun.getVelocityOfBody( frontWheelRef ).x
              if( horizV < -0.03) {
                  LiquidFun.setFixedRotation(frontWheelRef, to: true)
                  LiquidFun.setFixedRotation(backWheelRef, to: true) // brake instead of forwards accelerate.
              } else {
                  if( horizV < maxVelocity ) {
                  LiquidFun.setFixedRotation(frontWheelRef, to: false)
                  LiquidFun.setFixedRotation(backWheelRef, to: false)
                  applyTorque( -torqueBuildUp )
                  }
              }
        }
    }
    func driveReverse( _ deltaTime: Float ) {
        if torqueBuildUp < maxTorque {
            torqueBuildUp += deltaTime * ( jerk + rpmDecay )
        }
        if torqueBuildUp > minTorque {
            let horizV = LiquidFun.getVelocityOfBody( frontWheelRef ).x
            if( horizV > 0.03) {
                LiquidFun.setFixedRotation(frontWheelRef, to: true)
                LiquidFun.setFixedRotation(backWheelRef, to: true) // brake instead of backwards accelerate.
            } else {
                if horizV > -maxVelocity {
                LiquidFun.setFixedRotation(frontWheelRef, to: false)
                LiquidFun.setFixedRotation(backWheelRef, to: false)
                applyTorque( torqueBuildUp )
                }
            }
        }
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        if( torqueBuildUp > 0.0 ) {
            torqueBuildUp -= deltaTime * rpmDecay
            if torqueBuildUp < minTorque {
                LiquidFun.setFixedRotation(frontWheelRef,to: true)
                LiquidFun.setFixedRotation(backWheelRef, to: true)

            }
        }
    }

}
