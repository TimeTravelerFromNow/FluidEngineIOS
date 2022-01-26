import MetalKit

enum CustomMeshTypes{
    case Default
    case SkyQuad
    case Quad
}

class CustomMeshes: Library<CustomMeshTypes, CustomMesh> {
    
    private static var customMeshes : [CustomMeshTypes : CustomMesh] = [:]
    
    public static func Initialize( ) {
        createDefaultMeshes()
    }
    
    private static func createDefaultMeshes() {
        customMeshes.updateValue(CustomMesh(), forKey: .Default)
        customMeshes.updateValue(SkyQuad(), forKey: .SkyQuad)
    }
    
    public static func Get(_ meshType : CustomMeshTypes) -> CustomMesh {
        return customMeshes[meshType]!
    }
}

class CustomMesh {
    private var _vertices: [CustomVertex] = []
    private var _indices: [UInt32] = []
    private var _vertexBuffer: MTLBuffer!
    private var _indexBuffer: MTLBuffer!
    
    init() {
        buildMesh()
        buildBuffers()
    }
    
    internal func addVertex(position: float3,
                           color: float4,
                           textureCoordinate: float2 = float2(0,0)) {
        self._vertices.append(CustomVertex(position: position, color: color, textureCoordinate: textureCoordinate))
    }
    
    internal func buildMesh() {
        addVertex(position: float3( 0.5, 0.5, 0.0),color: float4(1.0,0.3,0.9,1.0), textureCoordinate: float2(1,0)) // Top Right,
        addVertex(position: float3(-0.5, 0.5, 0.0),color: float4(1.0,0.3,0.3,1.0), textureCoordinate: float2(0,0)) // Top Left,
        addVertex(position: float3(-0.5,-0.5, 0.0),color: float4(1.0,0.3,0.1,1.0), textureCoordinate: float2(0,1)) // Bottom Left,
        addVertex(position: float3( 0.5,-0.5, 0.0),color: float4(1.0,1.0,0.0,1.0), textureCoordinate: float2(1,1)) // Bottom Right
        
        _indices = [ 0, 1, 2,    0, 2, 3 ]
    }

    internal func setIndices(_ toIndices: [UInt32] ) {
        _indices = toIndices
    }
    
    private func buildBuffers() {
        _vertexBuffer = Engine.Device.makeBuffer(bytes: _vertices,
                                                 length: Vertex.stride(_vertices.count),
                                                 options: [])
        
        _indexBuffer = Engine.Device.makeBuffer(bytes: _indices,
                                                length: UInt32.Stride(self._indices.count),
                                                options: [])
    }
    
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setVertexBuffer(_vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: _indices.count,
                                                   indexType: .uint32,
                                                   indexBuffer: _indexBuffer,
                                                   indexBufferOffset: 0,
                                                   instanceCount: 1)
    }
}

class SkyQuad: CustomMesh {
    override func buildMesh() {
        addVertex(position: float3( 0.5, 0.5, 0.0),color: float4(0.2,0.2,0.6,1.0), textureCoordinate: float2(1,0)) // Top Right,
        addVertex(position: float3(-0.5, 0.5, 0.0),color: float4(0.2,0.2,0.6,1.0), textureCoordinate: float2(0,0)) // Top Left,
        addVertex(position: float3(-0.5,-0.5, 0.0),color: float4(0.6,0.8,1.0,1.0), textureCoordinate: float2(0,1)) // Bottom Left,
        addVertex(position: float3( 0.5,-0.5, 0.0),color: float4(0.4,0.6,1.0,1.0), textureCoordinate: float2(1,1)) // Bottom Right
        
        setIndices( [ 0, 1, 2,    0, 2, 3 ])
    }
}
