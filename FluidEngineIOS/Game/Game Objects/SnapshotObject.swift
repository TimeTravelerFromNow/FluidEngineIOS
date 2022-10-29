import MetalKit

class SnapshotObject: Node {
    var boxPos: float2!
    
    var mesh: Mesh!
    var modelConstants = ModelConstants()
    var material = CustomMaterial()
    var texture: MTLTexture!
    
    var snapshotType: TextureTypes?
    
    init(_ boxCenter: float2) {
        super.init()
        mesh = MeshLibrary.Get(.Quad)
        boxPos = boxCenter
        self.setScale(1000 / ( GameSettings.ptmRatio * 5) )
        self.setPositionZ(0.11)
    }
    
    override func update() {
        setPositionX(self.getBoxPositionX() * GameSettings.stmRatio)
        setPositionY(self.getBoxPositionY() * GameSettings.stmRatio)
        modelConstants.modelMatrix = modelMatrix
        super.update()
    }
    
    func getBoxPositionX() -> Float {
        return boxPos.x
    }
    func getBoxPositionY() -> Float {
        return boxPos.y
    }
        
    func takeSnapshot(_ type: TextureTypes) {
        
        let commandBuffer =  Engine.CommandQueue.makeCommandBuffer()
        let blitCommandEncoder = commandBuffer?.makeBlitCommandEncoder()
        let textureDesc = MTLTextureDescriptor()
        textureDesc.width = Textures.Get(.BaseColorRender_0).width
        textureDesc.height = Textures.Get(.BaseColorRender_0).height
        textureDesc.pixelFormat = Textures.Get(.BaseColorRender_0).pixelFormat
        textureDesc.sampleCount = Textures.Get(.BaseColorRender_0).sampleCount
        textureDesc.mipmapLevelCount = Textures.Get(.BaseColorRender_0).mipmapLevelCount
        textureDesc.resourceOptions = .storageModeShared
        
        let bytesPerRow =  Textures.Get(.BaseColorRender_0).bufferBytesPerRow
        texture = Engine.Device.makeTexture(descriptor: textureDesc)
//        texture.replace(region: MTLRegion(origin: MTLOrigin(x:0,y:0,z:0), size: MTLSize(width: textureDesc.width, height: textureDesc.height, depth: 0)), mipmapLevel: 0, withBytes: Textures.Get(.BaseColorRender_0)., bytesPerRow: bytesPerRow)
//        blitCommandEncoder?.copy( from: Textures.Get(.BaseColorRender_0), to: texture )
        blitCommandEncoder?.endEncoding()
        Textures.Set(textureType: type, texture: texture )
        snapshotType = type
//        material.useMaterialColor = false
    }
}

extension SnapshotObject: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
        
        renderCommandEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        renderCommandEncoder.setFragmentSamplerState(SamplerStates.Get(.Linear), index: 0)
        renderCommandEncoder.setFragmentBytes(&material, length: CustomMaterial.stride, index: 1 )
        if(!material.useMaterialColor) {
                   renderCommandEncoder.setFragmentTexture(texture, index: 0)
        }
        mesh.drawPrimitives(renderCommandEncoder, baseColorTextureType: snapshotType ?? .Missing)
    }
}
