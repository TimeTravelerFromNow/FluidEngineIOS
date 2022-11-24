
// my attempt at the end all class from Box2D to Swift.
// should serve the following:
// body creation/destruction
// fixture creation
// reference retrieval
// position and rotation setters/getters
// impulses torques etc
// welds
// filtering

class Infiltrator: Node {
    
    var polygonMeshes: [Mesh] = []
    var circleTextures: [TextureTypes] = []
    var bodyRefs: [UnsafeMutableRawPointer] = []
    var fixtureRefs: [UnsafeMutableRawPointer] = []
    var filter: BoxFilter!
    
}
