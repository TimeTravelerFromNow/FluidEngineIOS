import MetalKit

class CloudsBackground: Node {
    private var _timeTicked: Float = 0
    var clouds: [Clouds] = []
    var skyBG = SkyBackground(.SkyQuad)
    
    override init() {
        super.init()
        let cloudTypes: [MeshTypes] = [.Cloud0, .Cloud1, .Cloud2, .Cloud3]
        for type in cloudTypes {
            let cloudInstances = Int.random(in: 10...20)
            clouds.append(Clouds(instanceCount: cloudInstances, meshType: type))
        }
        for cGrp in clouds {
            addChild(cGrp)
            cGrp.setPositionZ(0.1)
            cGrp.setScale(0.01)
        }
        skyBG.setScale(10)
        addChild(skyBG)
    }
}

class Clouds: InstancedObject {
    var doneAnimatingStart = false
    var cloudsPerMinute: Float = 20
    var cloudsPerMinRatio: Float { return cloudsPerMinute * Renderer.ScreenSize.x * 0.001 / 60  }
    let scale: Float = 0.02
    private var _speedBuffer: [Float] = []
    
    var vRange: [Float] { return [Renderer.ScreenSize.y * scale * 0.5 - 10, 0.9 * Renderer.ScreenSize.y * scale - 10] }
    var hRange: [Float] { return  [-Renderer.ScreenSize.x * scale  , 1.6 * Renderer.ScreenSize.x * scale ] }
    init(instanceCount: Int, meshType: MeshTypes) {
        super.init(meshType: meshType, instanceCount: instanceCount )
        randomizeStart()
        _speedBuffer = [Float].init(repeating: Float.random(min: 2, max: 2.5), count: instanceCount)
    }
    
    func positionRight(_ node: Node) {
        let randF =  Float.randomZeroToOne * Renderer.ScreenSize.x * scale * 0.5
            node.setPositionX( hRange[1] + randF)
            node.setPositionY( Float.random(min: vRange[0], max: vRange[1]) )
        }
    
    func randomizeStart() {
        for (index, cloud) in _nodes.enumerated() {
            let y = Float.random(min: vRange[0], max: vRange[1])
            let x = Float.random(min: hRange[0], max: hRange[1])
            cloud.setPosition(float3(x: x,
                                        y: y, z : 0.9))
        }
    }
    override func update(deltaTime : Float) {
        for (index, node) in _nodes.enumerated() {
                    node.moveX(-deltaTime * cloudsPerMinRatio * _speedBuffer[index])
            if node.getPositionX() < hRange[0] {
                        positionRight(node)
                    }
        }
            
            super.update(deltaTime: deltaTime)
    }
}
