import MetalKit

class InstancedObject: Node {

    private var _mesh : Mesh!
    
    var material = CustomMaterial()
    
    internal var _nodes: [Node] = []
    private var _modelConstants: [ModelConstants] = []
    private var _texture: MTLTexture!
    
    private var _modelConstantBuffer: MTLBuffer!
    private var _textureIndexBuffer : MTLBuffer!
    private var _textureBuffer : MTLBuffer!
    
    init(meshType: MeshTypes, instanceCount: Int) {
        super.init()
        self._mesh = MeshLibrary.Get(meshType)
        self.generateInstances(instanceCount)
        self._mesh.setInstanceCount(instanceCount)
        self.createBuffers(instanceCount)
    }
    
    func generateInstances(_ instanceCount : Int) {
        for _ in 0..<instanceCount {
            _nodes.append(Node())
            _modelConstants.append(ModelConstants())
        }
    }
    
    func setTexture(_ toTexture: TextureTypes) {
        self._texture = Textures.Get(toTexture)
        self.material.useTexture = true
    }
        
    func createBuffers(_ instanceCount: Int) {
        _modelConstantBuffer = Engine.Device.makeBuffer(length: ModelConstants.stride(instanceCount), options: [])
    
    }
    
    private func updateModelConstantsBuffer() {
        var pointer = _modelConstantBuffer.contents().bindMemory(to: ModelConstants.self, capacity: _modelConstants.count)

        for node in _nodes {
            pointer.pointee.modelMatrix = matrix_multiply( self.modelMatrix , node.modelMatrix)
            
            pointer = pointer.advanced(by: 1)
        }
        
    }
    
    override func update() {
        updateModelConstantsBuffer()
        super.update()
    }
    
}

extension InstancedObject : Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        // Vertex
        renderCommandEncoder.setVertexBuffer(_modelConstantBuffer, offset: 0, index : 2)
        //Fragment
        renderCommandEncoder.setFragmentBytes(&material, length : CustomMaterial.stride, index : 1)
        
        _mesh.drawPrimitives(renderCommandEncoder)
        }
    }

//Material properties
extension InstancedObject {
    public func setColor(_ color : float4) {
        self.material.color = color
        self.material.useMaterialColor = true
    }
}
