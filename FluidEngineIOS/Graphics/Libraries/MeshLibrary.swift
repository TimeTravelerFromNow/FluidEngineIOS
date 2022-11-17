import MetalKit

enum MeshTypes {

    case TestTube
    case Quad
    
    case Cloud0
    case Cloud1
    case Cloud2
    case Cloud3
    
    case ClearButton
    case TestButton
    case Cliff
    
    case PineTree
    case Menu
    case BeachButton
    case Sand
    
    case Reservoir
    case BulbMesh
    
    case Alien
    case Asteroid
    case Barrel
    
    case NoMesh
}

class Library<T,K> {
    init() {
        fillLibrary()
    }
    
    func fillLibrary() {
        //Override this function when filling the library with default values
    }
    
    subscript(_ type: T)->K? {
        return nil
    }
}


class MeshLibrary: Library<MeshTypes, Mesh> {
    
    private static var meshes : [MeshTypes : Mesh] = [:]
    
    public static func Initialize( ) {
        createDefaultMeshes()
    }
    
    private static func createDefaultMeshes() {
        meshes.updateValue(Mesh(modelName: "reservoir"), forKey: .Reservoir)

        meshes.updateValue(Mesh( modelName: "testFlat"), forKey: .TestTube )
        
        meshes.updateValue(Mesh( modelName: "quad" ), forKey: .Quad)
        meshes.updateValue(Mesh( modelName: "cloud0" ), forKey: .Cloud0 )
        meshes.updateValue(Mesh( modelName: "cloud1" ), forKey: .Cloud1 )
        meshes.updateValue(Mesh( modelName: "cloud2" ), forKey: .Cloud2 )
        meshes.updateValue(Mesh( modelName: "cloud3" ), forKey: .Cloud3 )
        
        meshes.updateValue( Mesh( modelName: "clearButton" ), forKey: .ClearButton )
        meshes.updateValue( Mesh( modelName: "testButton" ), forKey: .TestButton )
        meshes.updateValue( Mesh( modelName: "cliff" ), forKey: .Cliff)
        meshes.updateValue( Mesh( modelName: "pineTree" ), forKey: .PineTree)
        meshes.updateValue( Mesh( modelName: "menuButton" ), forKey: .Menu)
        meshes.updateValue( Mesh( modelName: "beachButton" ), forKey: .BeachButton)
        meshes.updateValue( Mesh( modelName: "bulbMesh" ), forKey: .BulbMesh)
        
        meshes.updateValue( Mesh( modelName: "beach" ), forKey: .Sand)
        
        meshes.updateValue( Mesh( modelName: "Alien" ), forKey: .Alien)
        meshes.updateValue( Mesh( modelName: "Asteroid" ), forKey: .Asteroid)
        meshes.updateValue( Mesh( modelName: "Barrel" ), forKey: .Barrel)

        meshes.updateValue( NoMesh(), forKey: .NoMesh )
    }
    
    public static func Get(_ meshType : MeshTypes) -> Mesh {
        return meshes[meshType]!
    }
}

// Vertex Information
class Mesh {
    private var _vertices: [Vertex] = []
    private var _vertexCount: Int = 0
    private var _vertexBuffer: MTLBuffer! = nil
    private var _instanceCount: Int = 1
    private var _submeshes: [Submesh] = []
    private var _modelName: String = ""
    
    init() {
        createMesh()
        createBuffer()
    }
    
    init(modelName: String, faceless: Bool = false) {
        if !faceless {
        createMeshFromModel(modelName)
        }
    }
    
    func getBoxVertices(_ scale: Float) -> [Vector2D] {
        var boxVertices : [Vector2D] =    [Vector2D(x: 1.2, y:1.0),
                                                 Vector2D(x: 1.2, y: -1.0),
                                                 Vector2D(x: -1.2, y: -1.0),
                                                 Vector2D(x: -1.2, y: 1.0) ] // default box so it doesnt crash
        guard let assetURL = Bundle.main.url(forResource: _modelName, withExtension: "obj") else {
            print("getBoxVertices() WARNING::Asset \(_modelName) does not exist. Returning default box vertices.")
            return boxVertices
        }
        
        let objLoader = OBJLoader(url: assetURL)
        objLoader.parse()
        let vertexData = objLoader.vertices
        let vertexCount = objLoader.vertexCount

        if boxVertices.count != vertexCount  { // resize array.
            boxVertices = [Vector2D].init(repeating: Vector2D(x:0, y:0), count: vertexCount)
        }
        for i in 0..<vertexCount {
            boxVertices[i] = Vector2D(x:vertexData[i].x / scale, y: vertexData[i].y / scale)
        }
        
        return boxVertices
    }
    
    func createMesh() { }
    
    private func createBuffer() {
        if(_vertices.count > 0){
            _vertexBuffer = Engine.Device.makeBuffer(bytes: _vertices,
                                                     length: Vertex.stride(_vertices.count),
                                                     options: [])
        }
    }
    
    private func createMeshFromModel(_ modelName: String, ext: String = "obj") {
        _modelName = modelName
        guard let assetURL = Bundle.main.url(forResource: modelName, withExtension: ext) else {
            fatalError("Asset \(modelName) does not exist.")
        }
        
        let descriptor = MTKModelIOVertexDescriptorFromMetal(RenderPipelineStates.GetDescriptor(.Basic))
        (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeColor
        (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        (descriptor.attributes[3] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (descriptor.attributes[4] as! MDLVertexAttribute).name = MDLVertexAttributeTangent
        (descriptor.attributes[5] as! MDLVertexAttribute).name = MDLVertexAttributeBitangent
        
        let bufferAllocator = MTKMeshBufferAllocator(device: Engine.Device)
        let asset: MDLAsset = MDLAsset(url: assetURL,
                                       vertexDescriptor: descriptor,
                                       bufferAllocator: bufferAllocator,
                                       preserveTopology: true,
                                       error: nil)
        
        asset.loadTextures()
        
        var mdlMeshes: [MDLMesh] = []
        do{
            mdlMeshes = try MTKMesh.newMeshes(asset: asset,
                                              device: Engine.Device).modelIOMeshes
        } catch {
            print("ERROR::LOADING_MESH::__\(modelName)__::\(error)")
        }
        
        var mtkMeshes: [MTKMesh] = []
        for mdlMesh in mdlMeshes {
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent,
                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
            mdlMesh.vertexDescriptor = descriptor
            do{
                let mtkMesh = try MTKMesh(mesh: mdlMesh, device: Engine.Device)
                mtkMeshes.append(mtkMesh)
            } catch {
                print("ERROR::LOADING_MDLMESH::__\(modelName)__::\(error)")
            }
        }
        
        let mtkMesh = mtkMeshes[0]
        let mdlMesh = mdlMeshes[0]
     
        self._vertexBuffer = mtkMesh.vertexBuffers[0].buffer
        self._vertexCount = mtkMesh.vertexCount
        for i in 0..<mtkMesh.submeshes.count {
            let mtkSubmesh = mtkMesh.submeshes[i]
            let mdlSubmesh = mdlMesh.submeshes![i] as! MDLSubmesh
            let submesh = Submesh(mtkSubmesh: mtkSubmesh,
                                  mdlSubmesh: mdlSubmesh)
            addSubmesh(submesh)
        }
    }
    
    func setInstanceCount(_ count: Int) {
        self._instanceCount = count
    }
    
    func addSubmesh(_ submesh: Submesh) {
        _submeshes.append(submesh)
    }
    
    func addVertex(position: float3,
                   color: float4 = float4(1,0,1,1),
                   textureCoordinate: float2 = float2(0,0),
                   normal: float3 = float3(0,1,0),
                   tangent: float3 = float3(1,0,0),
                   bitangent: float3 = float3(0,0,1)) {
        _vertices.append(Vertex(position: position,
                                color: color,
                                textureCoordinate: textureCoordinate,
                                normal: normal,
                                tangent: tangent,
                                bitangent: bitangent))
    }
    
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder,
                        material: Material? = nil,
                        baseColorTextureType: TextureTypes = .None,
                        normalMapTextureType: TextureTypes = .None) {
        if(_vertexBuffer != nil) {
            renderCommandEncoder.setVertexBuffer(_vertexBuffer, offset: 0, index: 0)
            
            if(_submeshes.count > 0) {
                for submesh in _submeshes {
                    submesh.applyTextures(renderCommandEncoder: renderCommandEncoder,
                                          customBaseColorTextureType: baseColorTextureType,
                                          customNormalMapTextureType: normalMapTextureType)
                    submesh.applyMaterials(renderCommandEncoder: renderCommandEncoder,
                                           customMaterial: material)
                    renderCommandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                               indexCount: submesh.indexCount,
                                                               indexType: submesh.indexType,
                                                               indexBuffer: submesh.indexBuffer,
                                                               indexBufferOffset: submesh.indexBufferOffset,
                                                               instanceCount: _instanceCount)
                }
            } else {
                renderCommandEncoder.drawPrimitives(type: .triangle,
                                                    vertexStart: 0,
                                                    vertexCount: _vertices.count,
                                                    instanceCount: _instanceCount)
            }
        }
    }
}

// Index Information
class Submesh {
    private var _indices: [UInt32] = []
    
    private var _indexCount: Int = 0
    public var indexCount: Int { return _indexCount }
    
    private var _indexBuffer: MTLBuffer!
    public var indexBuffer: MTLBuffer { return _indexBuffer }

    private var _primitiveType: MTLPrimitiveType = .triangle
    public var primitiveType: MTLPrimitiveType { return _primitiveType }
    
    private var _indexType: MTLIndexType = .uint32
    public var indexType: MTLIndexType { return _indexType }
    
    private var _indexBufferOffset: Int = 0
    public var indexBufferOffset: Int { return _indexBufferOffset }
    
    private var _material = Material()
    
    private var _baseColorTexture: MTLTexture!
    private var _normalMapTexture: MTLTexture!
    
    init(indices: [UInt32]) {
        self._indices = indices
        self._indexCount = indices.count
        createIndexBuffer()
    }
    
    init(mtkSubmesh: MTKSubmesh,
         mdlSubmesh: MDLSubmesh) {
        _indexBuffer = mtkSubmesh.indexBuffer.buffer
        _indexBufferOffset = mtkSubmesh.indexBuffer.offset
        _indexCount = mtkSubmesh.indexCount
        _indexType = mtkSubmesh.indexType
        _primitiveType = mtkSubmesh.primitiveType
        
        createTexture(mdlSubmesh.material!)
        createMaterial(mdlSubmesh.material!)
    }
    
    private func texture(for semantic: MDLMaterialSemantic,
                         in material: MDLMaterial?,
                         textureOrigin: MTKTextureLoader.Origin) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: Engine.Device)
        guard let materialProperty = material?.property(with: semantic) else { return nil }
        guard let sourceTexture = materialProperty.textureSamplerValue?.texture else { return nil }
        let options: [MTKTextureLoader.Option : Any] = [
            MTKTextureLoader.Option.origin : textureOrigin as Any,
            MTKTextureLoader.Option.generateMipmaps : true
        ]
        let tex = try? textureLoader.newTexture(texture: sourceTexture, options: options)
        return tex
    }
    
    private func createTexture(_ mdlMaterial: MDLMaterial) {
        _baseColorTexture = texture(for: .baseColor,
                                    in: mdlMaterial,
                                    textureOrigin: .bottomLeft)
        
        _normalMapTexture = texture(for: .tangentSpaceNormal,
                                    in: mdlMaterial,
                                    textureOrigin: .bottomLeft)
    }

    private func createMaterial(_ mdlMaterial: MDLMaterial) {
        if let ambient = mdlMaterial.property(with: .emission)?.float3Value { _material.ambient = ambient }
        if let diffuse = mdlMaterial.property(with: .baseColor)?.float3Value { _material.diffuse = diffuse }
        if let specular = mdlMaterial.property(with: .specular)?.float3Value { _material.specular = specular }
        if let shininess = mdlMaterial.property(with: .specularExponent)?.floatValue { _material.shininess = shininess }
    }
        
    private func createIndexBuffer() {
        if(_indices.count > 0) {
            _indexBuffer = Engine.Device.makeBuffer(bytes: _indices,
                                                    length: UInt32.stride(_indices.count),
                                                    options: [])
        }
    }
    
    func applyTextures(renderCommandEncoder: MTLRenderCommandEncoder,
                      customBaseColorTextureType: TextureTypes,
                      customNormalMapTextureType: TextureTypes) {
        _material.useBaseTexture = customBaseColorTextureType != .None || _baseColorTexture != nil
        _material.useNormalMapTexture = customNormalMapTextureType != .None || _normalMapTexture != nil
        
        renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)

        let baseColorTex = customBaseColorTextureType == .None ? _baseColorTexture : Textures.Get(customBaseColorTextureType)
        if(baseColorTex != nil) {
            renderCommandEncoder.setFragmentTexture(baseColorTex, index: 0)
        }
        
        let normalMapTex = customNormalMapTextureType == .None ? _normalMapTexture : Textures.Get(customNormalMapTextureType)
        if(normalMapTex != nil) {
            renderCommandEncoder.setFragmentTexture(normalMapTex, index: 1)
        }
    }
    
    func applyMaterials(renderCommandEncoder: MTLRenderCommandEncoder,
                        customMaterial: Material?) {
        var mat = customMaterial == nil ? _material : customMaterial
        renderCommandEncoder.setFragmentBytes(&mat, length: Material.stride, index: 1)
    }
}

class NoMesh: Mesh { }

class TriangleMesh: Mesh {
    override func createMesh() {
        addVertex(position: float3( 0, 1,0), color: float4(1,0,0,1), textureCoordinate: float2(0.5,0.0))
        addVertex(position: float3(-1,-1,0), color: float4(0,1,0,1), textureCoordinate: float2(0.0,1.0))
        addVertex(position: float3( 1,-1,0), color: float4(0,0,1,1), textureCoordinate: float2(1.0,1.0))
    }
}

class CustomQuad: Mesh {
    override func createMesh() {
        addVertex(position: float3(-1,-1,0), color: float4(0,1,0,1), textureCoordinate: float2(0.0,1.0))
        addVertex(position: float3( 1,-1,0), color: float4(0,0,1,1), textureCoordinate: float2(1.0,1.0))
        addVertex(position: float3( 1,1,0), color: float4(0,0,1,1), textureCoordinate: float2(1.0,0.0))
        addVertex(position: float3( -1, 1,0), color: float4(1,0,0,1), textureCoordinate: float2(0.0,0.0))
    }
}

class CubeMesh: Mesh {
    override func createMesh() {
        //Left
        addVertex(position: float3(-1.0,-1.0,-1.0), color: float4(1.0, 0.5, 0.0, 1.0), normal: float3(-1, 0, 0))
        addVertex(position: float3(-1.0,-1.0, 1.0), color: float4(0.0, 1.0, 0.5, 1.0), normal: float3(-1, 0, 0))
        addVertex(position: float3(-1.0, 1.0, 1.0), color: float4(0.0, 0.5, 1.0, 1.0), normal: float3(-1, 0, 0))
        addVertex(position: float3(-1.0,-1.0,-1.0), color: float4(1.0, 1.0, 0.0, 1.0), normal: float3(-1, 0, 0))
        addVertex(position: float3(-1.0, 1.0, 1.0), color: float4(0.0, 1.0, 1.0, 1.0), normal: float3(-1, 0, 0))
        addVertex(position: float3(-1.0, 1.0,-1.0), color: float4(1.0, 0.0, 1.0, 1.0), normal: float3(-1, 0, 0))
        
        //RIGHT
        addVertex(position: float3( 1.0, 1.0, 1.0), color: float4(1.0, 0.0, 0.5, 1.0), normal: float3( 1, 0, 0))
        addVertex(position: float3( 1.0,-1.0,-1.0), color: float4(0.0, 1.0, 0.0, 1.0), normal: float3( 1, 0, 0))
        addVertex(position: float3( 1.0, 1.0,-1.0), color: float4(0.0, 0.5, 1.0, 1.0), normal: float3( 1, 0, 0))
        addVertex(position: float3( 1.0,-1.0,-1.0), color: float4(1.0, 1.0, 0.0, 1.0), normal: float3( 1, 0, 0))
        addVertex(position: float3( 1.0, 1.0, 1.0), color: float4(0.0, 1.0, 1.0, 1.0), normal: float3( 1, 0, 0))
        addVertex(position: float3( 1.0,-1.0, 1.0), color: float4(1.0, 0.5, 1.0, 1.0), normal: float3( 1, 0, 0))
        
        //TOP
        addVertex(position: float3( 1.0, 1.0, 1.0), color: float4(1.0, 0.0, 0.0, 1.0), normal: float3( 0, 1, 0))
        addVertex(position: float3( 1.0, 1.0,-1.0), color: float4(0.0, 1.0, 0.0, 1.0), normal: float3( 0, 1, 0))
        addVertex(position: float3(-1.0, 1.0,-1.0), color: float4(0.0, 0.0, 1.0, 1.0), normal: float3( 0, 1, 0))
        addVertex(position: float3( 1.0, 1.0, 1.0), color: float4(1.0, 1.0, 0.0, 1.0), normal: float3( 0, 1, 0))
        addVertex(position: float3(-1.0, 1.0,-1.0), color: float4(0.5, 1.0, 1.0, 1.0), normal: float3( 0, 1, 0))
        addVertex(position: float3(-1.0, 1.0, 1.0), color: float4(1.0, 0.0, 1.0, 1.0), normal: float3( 0, 1, 0))
        
        //BOTTOM
        addVertex(position: float3( 1.0,-1.0, 1.0), color: float4(1.0, 0.5, 0.0, 1.0), normal: float3( 0,-1, 0))
        addVertex(position: float3(-1.0,-1.0,-1.0), color: float4(0.5, 1.0, 0.0, 1.0), normal: float3( 0,-1, 0))
        addVertex(position: float3( 1.0,-1.0,-1.0), color: float4(0.0, 0.0, 1.0, 1.0), normal: float3( 0,-1, 0))
        addVertex(position: float3( 1.0,-1.0, 1.0), color: float4(1.0, 1.0, 0.5, 1.0), normal: float3( 0,-1, 0))
        addVertex(position: float3(-1.0,-1.0, 1.0), color: float4(0.0, 1.0, 1.0, 1.0), normal: float3( 0,-1, 0))
        addVertex(position: float3(-1.0,-1.0,-1.0), color: float4(1.0, 0.5, 1.0, 1.0), normal: float3( 0,-1, 0))
        
        //BACK
        addVertex(position: float3( 1.0, 1.0,-1.0), color: float4(1.0, 0.5, 0.0, 1.0), normal: float3( 0, 0,-1))
        addVertex(position: float3(-1.0,-1.0,-1.0), color: float4(0.5, 1.0, 0.0, 1.0), normal: float3( 0, 0,-1))
        addVertex(position: float3(-1.0, 1.0,-1.0), color: float4(0.0, 0.0, 1.0, 1.0), normal: float3( 0, 0,-1))
        addVertex(position: float3( 1.0, 1.0,-1.0), color: float4(1.0, 1.0, 0.0, 1.0), normal: float3( 0, 0,-1))
        addVertex(position: float3( 1.0,-1.0,-1.0), color: float4(0.0, 1.0, 1.0, 1.0), normal: float3( 0, 0,-1))
        addVertex(position: float3(-1.0,-1.0,-1.0), color: float4(1.0, 0.5, 1.0, 1.0), normal: float3( 0, 0,-1))
        
        //FRONT
        addVertex(position: float3(-1.0, 1.0, 1.0), color: float4(1.0, 0.5, 0.0, 1.0), normal: float3( 0, 0, 1))
        addVertex(position: float3(-1.0,-1.0, 1.0), color: float4(0.0, 1.0, 0.0, 1.0), normal: float3( 0, 0, 1))
        addVertex(position: float3( 1.0,-1.0, 1.0), color: float4(0.5, 0.0, 1.0, 1.0), normal: float3( 0, 0, 1))
        addVertex(position: float3( 1.0, 1.0, 1.0), color: float4(1.0, 1.0, 0.5, 1.0), normal: float3( 0, 0, 1))
        addVertex(position: float3(-1.0, 1.0, 1.0), color: float4(0.0, 1.0, 1.0, 1.0), normal: float3( 0, 0, 1))
        addVertex(position: float3( 1.0,-1.0, 1.0), color: float4(1.0, 0.0, 1.0, 1.0), normal: float3( 0, 0, 1))
    }
}
