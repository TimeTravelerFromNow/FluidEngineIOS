class GunSelectionMenu: Node {
    
    var howitzerSelectButton: FloatingButton!
    var mgSelectButton: FloatingButton!
    var shotgunSelectButton: FloatingButton!
    let gunSelectActions: [ButtonActions] = [ .HowitzerSelect, .MGSelect, .ShotgunSelect]
    var box2DOrigin: float2!
    var weaponSelectText: TextObject!
    
    var buttons: [FloatingButton] = []
    var buttonPressed: ButtonActions? = nil
    
    // scroll variables
    let leftBound: Float = -1.0
    let rightBound: Float = 1.0
    let defaultDragDelay: Float = 0.1
    private var _dragDelay: Float = 0.1
    var startDragPos: Float = 0.0
    var wheelCenter: Float = 0.0
    var didDragGunSelectionWheel = false { didSet { _dragDelay = defaultDragDelay}}
    
    // parent closure
    var selectionClosure: ((GunTruck.GunTypes) -> Void)!
    
    //testable
    var isTesting: Bool = false
    var isShowingMiniMenu: Bool = false
    init(_ center: float2, selectionClosure: @escaping (GunTruck.GunTypes) -> Void ) {
        self.box2DOrigin = center
        self.selectionClosure = selectionClosure
        super.init()
        buildWeaponSelectMenu()
    }
    
    private func buildWeaponSelectMenu() {
        howitzerSelectButton = FloatingButton(box2DOrigin + float2(-1,0), size: float2(1), sceneAction: .HowitzerSelect, textureType: .HowitzerBannerTexture)
        let clampedVal0 = clamp( howitzerSelectButton.getBoxPosition(), min: -0.5, max: 0.5)
        howitzerSelectButton.setScaleRatio( 1 / (1.0 + abs(clampedVal0.x) ))

        mgSelectButton       = FloatingButton(box2DOrigin + float2(0,0), size: float2(1), sceneAction: .MGSelect, textureType: .MGBannerTexture)
        shotgunSelectButton       = FloatingButton(box2DOrigin + float2(1,0), size: float2(1), sceneAction: .ShotgunSelect, textureType: .ShotgunBannerTexture)
        
        let clampedVal1 = clamp( shotgunSelectButton.getBoxPosition(), min: -3.5, max: 3.5)
        shotgunSelectButton.setScaleRatio( 1 / (1.0 + abs(clampedVal1.x) ))
        
        weaponSelectText = TextLabels.Get(.WeaponSelectText)
        weaponSelectText.setBoxPos( box2DOrigin + float2(0,1) )
        addChild( weaponSelectText )
        
        addChild( howitzerSelectButton )
        addChild( mgSelectButton       )
        addChild( shotgunSelectButton       )
        buttons.append(howitzerSelectButton)
        buttons.append(mgSelectButton      )
        buttons.append(shotgunSelectButton      )
    }
    
    private func gunSelectStep( _ deltaTime: Float,_ boxPos: float2 ) {
        if _dragDelay > 0.0 && !didDragGunSelectionWheel {
            _dragDelay -= deltaTime
        } else {
            if !didDragGunSelectionWheel {
            didDragGunSelectionWheel = true
            startDragPos = boxPos.x
            }
        }
        if didDragGunSelectionWheel {
            if boxPos.x > startDragPos {
                if wheelCenter < rightBound {
                    let movement = deltaTime * ( boxPos.x - startDragPos ) * 2
                   moveButtons( movement )
                    wheelCenter += movement
                    startDragPos += deltaTime * 0.3
                }
            }
            if boxPos.x < startDragPos {
                if wheelCenter > leftBound {
                    let movement = deltaTime * (startDragPos - boxPos.x) * 2
                    moveButtons(-movement)
                    wheelCenter -= movement
                    startDragPos -= deltaTime * 0.3
                }
            }
        }
    }
    
    private func moveButtons(_ by: Float ) {
        for button in buttons {
            button.boxMoveX(by)
            let clampedVal = clamp( button.getBoxPosition(), min: -3.5, max: 3.5)
            button.setScaleRatio( 1 / (1.0 + abs(clampedVal.x) ))
        }
    }
    
    var isLocking: Bool = false
    let lockSpeed: Float = 4.0
    let maxSlowIterations: Int = 100
   
    private func selectLockStep(_ deltaTime: Float) {
        let target = round(startDragPos)
        let centerPos = mgSelectButton.getBoxPositionX()
        let distToClose = target - centerPos
        var slowIter = 0
        var variableSpeed = lockSpeed
        if ( distToClose ) > 0.0 {
            while(deltaTime * variableSpeed > distToClose && slowIter < maxSlowIterations ) {
                variableSpeed *= 0.98
                slowIter += 1
            }
            moveButtons( deltaTime * lockSpeed )
            if slowIter > 0 {
                selectGunFromPos(position: target)
                isLocking = false
                return
            }
        } else {
            if distToClose == 0.0 {
                selectGunFromPos(position: target)
                isLocking = false
                return
            }
            while( -deltaTime * variableSpeed < distToClose && slowIter < maxSlowIterations ) {
                variableSpeed *= 0.98
                slowIter += 1
            }
            moveButtons( -deltaTime * variableSpeed )
            if slowIter > 0 {
                selectGunFromPos(position: target)
                isLocking = false
                return
            }
        }
    }
    private func selectGunFromPos(position: Float) {
        let gunSelectPositions: [Float: GunTruck.GunTypes ] = [1.0:.Howitzer,
                                                               0.0:.MG,
                                                               -1.0:.Shotgun]
        guard let gunSelectFromPos = gunSelectPositions[position] else {
            fatalError("selectLockStep() ERROR::no dictionary value for target pos: \(position)")
        }
        selectGun(gunSelectFromPos)
    }
    
    private func selectGun(_ type: GunTruck.GunTypes) {
        selectionClosure( type )
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        if buttonPressed == nil {
        weaponSelectText.setScaleRatio( (sin( GameTime.TotalGameTime * 3) + 10.3) / 11.3  )
        }
        if isLocking {
            selectLockStep(deltaTime)
        }
    }
    
    func hitTest(_ pos: float2) -> ButtonActions? {
        for b in buttons {
            let hitResult =  b.hitTest(pos)
            if hitResult != nil {
                return hitResult
            }
        }
        return nil
    }
}

extension GunSelectionMenu: Testable {
   
    func touchesBegan(_ boxPos: float2) {
        let hitAction = hitTest(boxPos)
        if hitAction != nil {
            buttonPressed = hitAction
         if gunSelectActions.contains( buttonPressed! ) {
             didDragGunSelectionWheel = false
         }
        }
    }
    
    func touchDragged(_ boxPos: float2,_ deltaTime: Float) {
        if buttonPressed != nil {
       gunSelectStep( deltaTime, boxPos)
        }
    }
    
    func touchEnded(_ boxPos: float2) {
        if buttonPressed != nil {
            if !didDragGunSelectionWheel {
                let hit = hitTest(boxPos)
                if hit == buttonPressed { // tell wheel to lock at tapped gun icon
                    if buttonPressed == .HowitzerSelect {
                        startDragPos = 1.0
                    }
                    if buttonPressed == .MGSelect {
                        startDragPos = 0.0
                    }
                    if buttonPressed == .ShotgunSelect {
                        startDragPos = -1.0
                    }
                }
            }
            buttonPressed = nil
            isLocking = true
        }
    }
    
    func testingRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        
    }
    
    
}

