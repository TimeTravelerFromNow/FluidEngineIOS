// my attempt at the end all class from Box2D to Swift.
// should serve the following:
// body creation/destruction
// fixture creation
// reference retrieval
// position and rotation setters/getters
// impulses torques etc
// welds
// filtering
import MetalKit

class Infiltrator: Node {
    
    private struct InfiltratorRenderables {
        var mesh: Mesh
        var texture: TextureTypes
        var modelConstants: ModelConstants
        var isCircle: Bool
        var scale: Float
        var zPos: Float = 0.1
    }
    
    typealias b2Body = UnsafeMutableRawPointer
    typealias b2Fixture = UnsafeMutableRawPointer
    typealias b2Joint = UnsafeMutableRawPointer
    
    private var _renderables: [b2Fixture:InfiltratorRenderables] = [:] // each fixture should have a renderable
    var bodyRefs: [b2Body:String] = [:] // let's have some descriptions
    var bodyCount: Int { return bodyRefs.count  }
    var fixtureRefs: [b2Body:[b2Fixture]] = [:]
    var filter: BoxFilter!
    var origin: float2!
    var scale: Float!
    
    var _infiltratorRef: UnsafeMutableRawPointer!
    var positionZ: Float = 0.1
    
    init(origin: float2, scale: Float, startingMesh: MeshTypes? = nil, density: Float = 1.0, restitution: Float = 0.7, filter: BoxFilter = BoxFilterInit()) {
        self.origin = origin
        self.filter = filter
        self.scale = scale
        super.init()
        self.setScale( GameSettings.stmRatio * scale )
        _infiltratorRef = LiquidFun.makeInfiltrator(origin,
                                  velocity: float2(0),
                                  startAngle: 0,
                                  density: density,
                                  restitution: restitution,
                                  filter: filter)
        if( startingMesh != nil ) {
            let body = newBody(origin, withFilter: filter, name: MeshLibrary.Get(startingMesh!).getName())
            attachPolygonFixture(fromMesh: startingMesh!, body: body)
        }
    }
    
    // body methods
    func newBody(_ atPos: float2, angle: Float = 0.0, withFilter: BoxFilter = BoxFilterInit(), name: String) -> b2Body {
        let bodyRef = LiquidFun.newInfiltratorBody( _infiltratorRef, pos: atPos, angle: angle, filter: withFilter)
        bodyRefs.updateValue( name, forKey: bodyRef! )
        return bodyRef!
    }
    
    // getters
    func getBodyPosition(_ ofBody: b2Body?) -> float2 {
        if ofBody != nil {
            return LiquidFun.getPositionOfbody( ofBody )
        } else {
            print("getBodyPos WARN::body was nil")
        }
        return float2(0)
    }
    
    // fixture methods
    func attachCircleFixture(_ radius: Float, pos: float2, texture: TextureTypes, body: b2Body) -> b2Fixture? {
        let circleRenderable = InfiltratorRenderables(mesh: MeshLibrary.Get(.Quad),
                                                      texture: texture,
                                                      modelConstants: ModelConstants(),
                                                      isCircle: true,
                                                      scale: radius)
        guard let fixtureRef = LiquidFun.makeCircleFixture(onInfiltrator: _infiltratorRef, body: body, radius: radius, pos: pos ) else {
            print("Infiltrator:attachCircle() WARN::fixture from make circle was nil, returning nil")
            return nil
        }
        var fixtures: [b2Fixture] = fixtureRefs[body] ?? []
        fixtures.append( fixtureRef )
        fixtureRefs.updateValue( fixtures, forKey: body )
        _renderables.updateValue( circleRenderable, forKey: fixtureRef )
        return fixtureRef
    }
    
    func setFixtureZPos(_ of: b2Fixture, to: Float ) {
        _renderables[of]?.zPos = to
    }
    
    func attachPolygonFixture(_ pos: float2 = float2(0), fixtureScale: Float? = nil, fromMesh: MeshTypes, body: b2Body) -> b2Fixture? {
        let mesh = MeshLibrary.Get(fromMesh)
        var polygonScale = self.scale
        if fixtureScale != nil { polygonScale = fixtureScale }
        let newRenderable = InfiltratorRenderables(mesh: mesh,
                                                 texture: .None,
                                                 modelConstants: ModelConstants(),
                                                 isCircle: false,
                                                 scale: polygonScale!)
        var boxVertices = mesh.getBoxVertices(polygonScale!)
        if (boxVertices.count > 8) { print("infiltrator polygon WARN::too many vertices \(boxVertices.count) count > 8 max."); return nil }
        let fixtureRef: b2Fixture = LiquidFun.makePolygonFixture(onInfiltrator: _infiltratorRef, body: body, pos: pos, vertices: &boxVertices, vertexCount: boxVertices.count)
        var fixtures: [b2Fixture] = fixtureRefs[body] ?? []
        fixtures.append( fixtureRef )
        fixtureRefs.updateValue( fixtures, forKey: body )
        _renderables.updateValue( newRenderable, forKey: fixtureRef)
        return fixtureRef
    }
    
    func attachChainFixture(fromMesh: MeshTypes, body: b2Body) -> b2Fixture? {
        fatalError("not implemented")
        return nil
    }
    
    // joint methods
    func weldJoint( bodyA: b2Body, bodyB: b2Body, weldPos: float2, stiffness: Float, damping: Float) -> b2Joint {
        return LiquidFun.weldJoint( bodyA, bodyB: bodyB, weldPos: weldPos, stiffness: stiffness, damping: damping)
    }
    func wheelJoint( bodyA: b2Body, bodyB: b2Body, weldPos: float2, localAxisA: float2, stiffness: Float, damping: Float) -> b2Joint {
        return LiquidFun.wheelJoint( bodyA, bodyB: bodyB, weldPos: weldPos, localAxisA: localAxisA, stiffness: stiffness, damping: damping)
    }
    
    private func updateModelConstants() {
        for body in bodyRefs.keys {
            let b2Position = LiquidFun.getPositionOfbody( body )
            // just be careful, this node's matrix is changing a bunch per second
            self.setPosition( GameSettings.stmRatio * b2Position.x, GameSettings.stmRatio * b2Position.y, positionZ )
            self.setRotationZ( LiquidFun.getRotationOfBody( body ) )
            
            if fixtureRefs[body] != nil {
                for i in 0..<fixtureRefs[body]!.count {
                    let currFixture = fixtureRefs[body]![i]
                    if _renderables[currFixture] != nil {
                        self.setPositionZ( _renderables[currFixture]!.zPos )
                    self.setScale( GameSettings.stmRatio * _renderables[currFixture]!.scale )
                    _renderables[currFixture]!.modelConstants.modelMatrix = modelMatrix
                    }
                }
            }
        }
    }
    
    var material = CustomMaterial(color: float4(0), useMaterialColor: false, useTexture: true)
    
    override func render(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        super.render( renderCommandEncoder )
        updateModelConstants()
        for fixture in _renderables.keys {
            if (_renderables[fixture] != nil) {
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Basic))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            
            renderCommandEncoder.setVertexBytes(&_renderables[fixture]!.modelConstants, length: ModelConstants.stride, index: 2)
            renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)
            renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1 )
            if( _renderables[fixture]!.isCircle ) {
                _renderables[fixture]!.mesh.drawPrimitives( renderCommandEncoder, baseColorTextureType: _renderables[fixture]!.texture )
            } else {
                _renderables[fixture]!.mesh.drawPrimitives( renderCommandEncoder )
            }
            }
            
        }
        
    }
}
