class Island: Infiltrator {
    var island: b2Body!
    var leftPalm: b2Body?
    var rightPalm: b2Body?
    var leftStemFix: b2Fixture?
    var rightStemFix: b2Fixture?
    var leftPalmFix: b2Fixture?
    var rightPalmFix: b2Fixture?

    var leftPalmOffset: float2!
    var rightPalmOffset: float2!
    var leftTreeJoint: b2Joint?
    var rightTreeJoint: b2Joint?
    
    
    init(origin: float2) {
        leftPalmOffset = float2(-1.7, 0.87)
        rightPalmOffset = float2(1.6, 0.9)

        super.init(origin: origin, scale: 0.5, startingMesh: .Island, density: 100)
        island = bodyRefs.keys.first!
        buildIsland()
    }
    
    func buildIsland() {
        let filter = BoxFilter(categoryBits: 0x0001, maskBits: 0xFFFF, groupIndex: 0, isFiltering: false)
        leftPalm = self.newBody(origin + leftPalmOffset, name: "front-wheel-body")
        rightPalm  = self.newBody(origin + rightPalmOffset, name: "back-wheel-body")
        // found out positions dont do anything
        leftStemFix = attachPolygonFixture( float2(0,-1.3), fromMesh: .Palm, body: leftPalm!)
        rightStemFix = attachPolygonFixture( float2(0,-0.3), fromMesh: .Palm, body: rightPalm!)
        leftPalmFix  = attachCircleFixture(0.2, pos: float2(0,2.3), texture: .PalmTexture, body: leftPalm!)
        rightPalmFix  = attachCircleFixture(0.2, pos: float2(0,2.3), texture: .PalmTexture, body: rightPalm!)

        setFixtureZPos(leftStemFix!, to: 0.09)
        setFixtureZPos(rightStemFix!, to: 0.09)

        leftTreeJoint = weldJoint(bodyA: island, bodyB: leftPalm!, weldPos: leftPalmOffset, stiffness: 10, damping: 0.5)
        rightTreeJoint = weldJoint(bodyA: island, bodyB: rightPalm!, weldPos: rightPalmOffset, stiffness: 10, damping: 0.5)
        
        LiquidFun.setFixedRotation(leftPalm,to: true)
        LiquidFun.setFixedRotation(rightPalm, to: true)
    }
}
