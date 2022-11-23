
class GunTruck: Node {
    
    var gunObject: Friendly!
    
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

    var particleSystem: UnsafeMutableRawPointer!
    
    let fireButtonOffset = float2(-1.0, -0.3)
    var fireButton: FloatingButton!
    var truck: TruckObject!

    var pColor = float4(1,1,0,1)

    let maxTorque: Float = 70.0
    let minTorque: Float = 10.0
    let jerk: Float = 10.0
        
    init(origin: float2, scale: Float = 2.0, particleSystem: UnsafeMutableRawPointer) {
        super.init()
        self.setScale(1 / (GameSettings.ptmRatio * 5) )
        fluidModelConstants.modelMatrix = modelMatrix
        self.setScale(1)
        self.particleSystem = particleSystem
        self.gunObject = GunObject(center: origin, scale: scale)
        self.fireButton = FloatingButton(origin + fireButtonOffset, size: float2(0.35,0.35), sceneAction: .Fire, textureType: .FireButtonUp, selectTexture: .FireButton)

        _fluidConstants = FluidConstants(ptmRatio: GameSettings.ptmRatio, pointSize: GameSettings.particleRadius)
        _laserMesh = CustomMesh()
        
        truck = TruckObject(origin: origin, scale: 1.5 * scale)
        addChild(truck)
        addChild(fireButton)
        addChild(gunObject)
        self.gunObject.setPositionZ(0.11)
        self.fireButton.setPositionZ(0.12)
        self.truck.setPositionZ(0.12)
//        LiquidFun.wheelJointFriendlies(gunObject.getFriendlyRef, friendlyB: truck.truckBody.getFriendlyRef, jointPos: Vector2D(x:0.4 / scale,y: -0.8 / scale), stiffness: 10, damping: 0.1)
        LiquidFun.weldJointFriendlies(truck.truckBody.getFriendlyRef, friendly1: gunObject.getFriendlyRef, weldPos:  Vector2D(x:-0.5 / scale,y: 0.2 / scale), stiffness: 0.1)
//        LiquidFun.wheelJointFriendlies( truck.truckBody.getFriendlyRef, friendlyB: gunObject.getFriendlyRef, jointPos: Vector2D(x:-0.5 / scale,y: 0.2 / scale), stiffness: 10, damping: 0.8 )
    }
    
    func setBaseAngularV(_ to: Float) {
        
        LiquidFun.setFriendlyAngularVelocity(gunObject.getFriendlyRef, angV: to)
    }
    func updateFireButtonModelConstants() {
        fireButton.box2DPos = float2(gunObject.getBoxPositionX() + fireButtonOffset.x, gunObject.getBoxPositionY() + fireButtonOffset.y)
        fireButton.refreshModelConstants()
    }
    
    func updateLaserModelConstants() {
        let currAngle = gunObject.getRotationZ() + .pi/2
        let dirVector = float2( cos(currAngle), sin(currAngle) )
        let start = gunObject.getBoxPosition()
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
        
        updateFireButtonModelConstants()
        if( torqueBuildUp > minTorque ) {
            torqueBuildUp -= deltaTime * jerk
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
                LiquidFun.setFriendlyFixedRotation( gunObject.getFriendlyRef, to: true )
            }
        }
    }
    
    
    private func aimStep( _ deltaTime: Float ) {
        let currAngle = gunObject.getRotationZ() + .pi/2
        LiquidFun.setFriendlyFixedRotation( gunObject.getFriendlyRef, to: false )
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
            gunObject.setAngV(0)
            LiquidFun.setFriendlyFixedRotation( gunObject.getFriendlyRef, to: true )
            return
        }
        while( angVToSet * deltaTime > angToClose && i < maxCloseIter ) {
            angVToSet *= 0.95
            i += 1
        }
        if xProd.z > 0.0 { // need to rotate CC
            //                LiquidFun.torqueFriendly( mount.getFriendlyRef, amt: 0.8)
            gunObject.setAngV( angVToSet )
        } else {
            //                LiquidFun.torqueFriendly( mount.getFriendlyRef, amt: -0.8)
            gunObject.setAngV( -angVToSet )
        }
    }
    
    var torqueBuildUp: Float = 0.0
    func truckLeft(_ deltaTime: Float) {
        truck.applyTorque( torqueBuildUp )
        if torqueBuildUp < maxTorque {
        torqueBuildUp += deltaTime * jerk
        }
    }
    func truckRight( _ deltaTime: Float ) {
        truck.applyTorque( -torqueBuildUp )
        if torqueBuildUp < maxTorque {
        torqueBuildUp += deltaTime * jerk
        }
    }
    
    func fireGun() {
        let currGunPos = gunObject.getBoxPosition()
        let currAngle = gunObject.getRotationZ() + .pi/2
        let startDir = float2(cos(currAngle), sin(currAngle)) * 0.3
        let shellFriendly = Friendly(center: currGunPos + startDir, scale: 2.0, velocity: startDir * 60, angle: currAngle - .pi/2, .Shell)
        shellFriendly.setAsPolygonShape()
        addChild(shellFriendly)
    }
    
    //testables
    var isTesting: Bool = false
    var isShowingMiniMenu: Bool = false
    
}
extension GunTruck: Renderable {
    func doRender( _ renderCommandEncoder: MTLRenderCommandEncoder ) {
        if isShowingLaser {
            if isAiming {
                renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.SelectCustomBox2D))
                renderCommandEncoder.setFragmentBytes(&_timeTicked, length : Float.size, index : 0)
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
extension GunTruck: Touchable {
   
    func touchesBegan(_ boxPos: float2) {

        if( fireButton.hitTest(boxPos) == .Fire ) {
            fireButton.isSelected = true
            fireGun( )
        } else {
            isAiming = true
            isShowingLaser = true
            _aimVector = boxPos - gunObject.getBoxPosition()
        }
    }
    
    func touchDragged(_ boxPos: float2) {
        _aimVector = boxPos - gunObject.getBoxPosition()
        if fireButton.isSelected {
        if( fireButton.hitTest(boxPos) != .Fire ) {
            fireButton.isSelected = false
        }
        }
    }
    
    func touchEnded() {
        isAiming = false
        fireButton.isSelected = false
    }
    
    func testingRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        
    }
}
