class GunTruck: Infiltrator {
    
    enum GunTypes: String {
        case Howitzer = "howitzer"
        case MG = "machine gun"
        case Shotgun = "shotgun"
        case None = "no gun"
    }
    var currentGun = GunTypes.None
    
    var gunRef: b2Body?
    var barrelFixture: b2Fixture?
    var mountFixture: b2Fixture?
    
    var frontWheelRef: b2Body?
    var backWheelRef: b2Body?
    var frontWheelJoint: b2Joint?
    var backWheelJoint: b2Joint?
    var frontWheelFixture: b2Fixture?
    var backWheelFixture: b2Fixture?
    
    var truckBodyRef: b2Body! // not optional (everything must rest on chassis, if chassis is gone, entire GunTruck is dead)
    var frontTireOffset: float2!
    var backTireOffset: float2!
    var gunMountPosition: float2!

    var torqueBuildUp: Float = 0.0
    let maxTorque: Float = 0.1
    let minTorque: Float = 0.01
    let jerk: Float = 1
    let rpmDecay: Float  = 0.1
    var maxVelocity: Float = 0.3
    
    private var _aimVector: float2 = float2(0,0)
    var isAiming = false
    var isShowingLaser = false { didSet {_laserDelay = defaultLaserDelay}}
    let defaultLaserDelay: Float = 0.3
    var _laserDelay: Float = 0.3
    private var _timeTicked: Float = 0.0
    private var laserSelectColor: float4 = float4(1,0.8,0.8,1)
    private var _laserMesh: CustomMesh!
    private var _fluidConstants: FluidConstants!
    private var fluidModelConstants = ModelConstants()
    
    //touchable
    var isTesting: Bool = false
    var isShowingMiniMenu: Bool = false
    init(origin: float2, scale: Float = 1.0) {
        backTireOffset  = float2(-0.95 * scale, -0.5 * scale)
        frontTireOffset = float2( 0.9 * scale, -0.5 * scale)
        gunMountPosition = float2( -0.55 * scale,  0.37 * scale)
        super.init(origin: origin, scale: scale, startingMesh: .Truck, density: 100 , filter: BoxFilter(categoryBits: 0x0011, maskBits: 0xFF0F, groupIndex: 0, isFiltering: false))
        self.setScale(1 / (GameSettings.ptmRatio * 5) )
        fluidModelConstants.modelMatrix = modelMatrix
        truckBodyRef = bodyRefs.keys.first!
        buildTruck()
        _fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
        _laserMesh = CustomMesh()
    }
    
    func buildTruck() {
        let filter = BoxFilter(categoryBits: 0x0011, maskBits: 0xFF0F, groupIndex: 0, isFiltering: false)
        frontWheelRef = self.newBody(origin + frontTireOffset, withFilter: filter, name: "front-wheel-body")
        backWheelRef  = self.newBody(origin + backTireOffset, withFilter: filter, name: "back-wheel-body")
        LiquidFun.setAngularDamping( frontWheelRef, amount: 0.1)
        LiquidFun.setAngularDamping( backWheelRef, amount: 0.1)

        frontWheelFixture = attachCircleFixture( scale * 0.5, pos: float2(0), texture: .TruckTireTexture, body: frontWheelRef! )
        backWheelFixture = attachCircleFixture( scale * 0.5, pos: float2(0), texture: .TruckTireTexture, body: backWheelRef! )
        
        setFixtureZPos(frontWheelFixture!, to: 0.09)
        setFixtureZPos(backWheelFixture!, to: 0.09)
        
        frontWheelJoint = wheelJoint(bodyA: truckBodyRef, bodyB: frontWheelRef!, weldPos: frontTireOffset, localAxisA: float2(0,1), stiffness: 10, damping: 0.5)
        backWheelJoint = wheelJoint(bodyA: truckBodyRef, bodyB: backWheelRef!, weldPos: backTireOffset, localAxisA: float2(0,1), stiffness: 10, damping: 0.5)
        
            LiquidFun.setFixedRotation(frontWheelRef,to: true)
            LiquidFun.setFixedRotation(backWheelRef, to: true)
    }
    
    func selectGun( _ gunType: GunTypes ){
        if gunRef != nil {
        } else {
            let filter = BoxFilter(categoryBits: 0x0010, maskBits: 0xFF0F, groupIndex: -1, isFiltering: false)
            let attachPos = LiquidFun.getPositionOfbody( truckBodyRef ) + gunMountPosition
            gunRef = newBody(attachPos, angle: 0, withFilter: filter, name: "gun-body")
        }
        if gunType != currentGun {
            if mountFixture != nil {
                removeFixture(gunRef!, fixtureRef: mountFixture!)
                removeFixture(gunRef!, fixtureRef: barrelFixture!)
                mountFixture = nil
                barrelFixture = nil
            }
         attachGun(gunType: gunType)
        }
    }
    
    private func attachGun(gunType: GunTypes) {
        switch gunType {
        case .Howitzer:
            mountFixture = attachCircleFixture(0.09, pos: gunMountPosition, texture: .MountTexture, body: gunRef!)
            barrelFixture = attachPolygonFixture(fixtureScale: 0.5, fromMesh: .Barrel, body: gunRef!)

            wheelJoint(bodyA: truckBodyRef, bodyB: gunRef!, weldPos: gunMountPosition, localAxisA:float2(0,1),stiffness: 10, damping: 0.5)
//            weldJoint(bodyA: truckBodyRef, bodyB: gunRef!, weldPos: gunMountPosition, stiffness: 10, damping: 0.5)
            setFixtureZPos(mountFixture!, to: 0.07)
            setFixtureZPos(barrelFixture!, to: 0.07)
            LiquidFun.setFixedRotation(gunRef, to: true)
        case .MG:
            mountFixture = attachPolygonFixture(fixtureScale: 1.0, fromMesh: .MGMount, body: gunRef!)
            barrelFixture = attachPolygonFixture(fixtureScale: 0.5, fromMesh: .Barrel, body: gunRef!)
            wheelJoint(bodyA: truckBodyRef, bodyB: gunRef!, weldPos: gunMountPosition, localAxisA:float2(0,1),stiffness: 10, damping: 0.5)
//            weldJoint(bodyA: truckBodyRef, bodyB: gunRef!, weldPos: gunMountPosition, stiffness: 10, damping: 0.5)
            setFixtureZPos(mountFixture!, to: 0.07)
            setFixtureZPos(barrelFixture!, to: 0.07)
            LiquidFun.setFixedRotation(gunRef, to: true)
            print("attachGun Implement MG")
        case .Shotgun:
            print("attachGun  Implement Shotgun")
        case .None:
            print("attachGun  No gun")

        }
    }
    
    private func applyTorque(_ amt: Float) {
        LiquidFun.torqueBody( frontWheelRef, amt: amt, awake: true  )
        LiquidFun.torqueBody( backWheelRef, amt: amt, awake: true )
//
//          LiquidFun.setFriendlyFixedRotation(tire0.getFriendlyRef, to: false)
//          LiquidFun.setFriendlyFixedRotation(tire1.getFriendlyRef, to: false)
//          isParking = false
      }

    func steerTruck(_ deltaTime: Float, towards: float2) {
        let magnified = towards * 5
        if magnified.x > 0 {
            driveForward( deltaTime, strength: magnified.x)
        } else if magnified.x < 0 {
            driveReverse( deltaTime, strength: abs(magnified.x))
        } else if magnified.x == 0 {
            
        }
    }
    
    func driveForward( _ deltaTime: Float, strength: Float = 0.3 ) {
        maxVelocity = strength

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
                  } else {
                      if( horizV > maxVelocity * 1.05 ) {
                          applyTorque( torqueBuildUp ) // brake a bit
                      }
                  }
              }
        }
    }
    func driveReverse( _ deltaTime: Float, strength: Float = 0.3 ) {
        maxVelocity = strength
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
                } else {
                    if( horizV < -maxVelocity * 1.05 ) {
                        applyTorque( -torqueBuildUp ) // brake a bit
                    }
                }
            }
        }
    }
    
    private func aimStep( _ deltaTime: Float ) {
        if gunRef == nil { return }
        let currAngle = LiquidFun.getRotationOfBody(gunRef) + .pi/2
        LiquidFun.setFixedRotation( gunRef, to: false )
        let dirVector = float2( cos(currAngle ), sin( currAngle ) )
        let xProd = cross( dirVector, _aimVector)
        var destAngle =   atan( _aimVector.y / _aimVector.x )
        if destAngle < 0 {
            destAngle += .pi
        }
        let angToClose = abs(destAngle - currAngle)
        let maxCloseIter = 100
        var i = 0
        var angVToSet: Float = 2.0
        if (angToClose < 0.01) {
            LiquidFun.setAngV(gunRef, amount: 0)
            LiquidFun.setFixedRotation( gunRef, to: true )
            return
        }
        while( angVToSet * deltaTime > angToClose && i < maxCloseIter ) {
            angVToSet *= 0.95
            i += 1
        }
        if xProd.z > 0.0 { // need to rotate CC
            //                LiquidFun.torqueFriendly( mount.getFriendlyRef, amt: 0.8)
            LiquidFun.setAngV(gunRef, amount: angVToSet)
        } else {
            //                LiquidFun.torqueFriendly( mount.getFriendlyRef, amt: -0.8)
            LiquidFun.setAngV(gunRef, amount: -angVToSet)
        }
    }
    
    private func updateLaserModelConstants() {
        if gunRef == nil { return }
        let currAngle = LiquidFun.getRotationOfBody(gunRef) + .pi/2
        let dirVector = float2( cos(currAngle), sin(currAngle) )
        let start =  LiquidFun.getPositionOfbody(gunRef)
        let end = 100 * dirVector + start
        let tangentV = normalize(MoveableArrow2D.ninetyDegreeRotMat * dirVector) * 0.01
        let newVertexPositions = [
            start - tangentV,
            start + tangentV,
            end + tangentV,
            end - tangentV
        ]
        
        let texCoords =  [
            float2(0,1),
            float2(1,1),
            float2(0,0),
            float2(1,0)
        ]
        
        var newVs = [CustomVertex].init(repeating: CustomVertex(position: float3(0), color: float4(1,0,0,1), textureCoordinate: float2(0)), count: 4)
        for (i, nVP) in newVertexPositions.enumerated() {
            newVs[i].position = float3(nVP.x,nVP.y,0.17)
            newVs[i].textureCoordinate = texCoords[i]
        }
        _laserMesh.setVertices(newVs)
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
        if( isAiming ) {
            updateLaserModelConstants()
            aimStep( deltaTime ) // call after update.
            _timeTicked += deltaTime
        } else if ( isShowingLaser ) {
            updateLaserModelConstants()
            if(_laserDelay > 0.0 ) {
                _laserDelay -= deltaTime
            } else {
                isShowingLaser = false
                LiquidFun.setFixedRotation( gunRef, to: true )
            }
        }
    }

}
extension GunTruck: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        if isShowingLaser {
            if isAiming {
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.SelectCustomBox2D))
                renderCommandEncoder.setFragmentBytes(&_timeTicked, length : Float.size, index :     0)
                renderCommandEncoder.setFragmentBytes(&laserSelectColor, length : float3.size, index : 2)
            }
            else {
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.CustomBox2D))
            }
            renderCommandEncoder.setVertexBytes(&fluidModelConstants,
                                                length: ModelConstants.stride,
                                                index: 2)
            renderCommandEncoder.setVertexBytes(&_fluidConstants,
                                                length: FluidConstants.stride,
                                                index: 3)
            renderCommandEncoder.setFragmentTexture(Textures.Get(.LaserTexture), index: 0)
            _laserMesh.drawPrimitives( renderCommandEncoder )
        }
    }
}

extension GunTruck: Testable {

    func touchesBegan(_ boxPos: float2) {
        if gunRef != nil {
            isAiming = true
            isShowingLaser = true
            _aimVector = boxPos - getBodyPosition(gunRef)
        }
    }

    func touchDragged(_ boxPos: float2, _ deltaTime: Float) {
        _aimVector = boxPos - getBodyPosition(gunRef)
    }

    func touchEnded(_ boxPos: float2) {
        isAiming = false
    }

    func testingRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {

    }
}
