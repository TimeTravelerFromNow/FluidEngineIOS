import MetalKit

class TubeRep: Node {

    private var _selectColors : [TubeSelectColors:float3] =  [ .Selected: float3(1.0,1.0,1.0),
                                                             .Reject  : float3(1.0,0.0,0.0),
                                                             .Finished: float3(1.0,1.0,0.0) ]
    
    private var _currentSelect: TubeSelectColors = .NoSelection
        
    var shouldUpdate = false
    init(_ ttHeight: Float ) {
        super.init()
        self.setPositionZ(1.1)
        self.setScale( ttHeight * GameSettings.stmRatio * 0.14)
        self.setTexture(.ttFlat)
        self.mesh = MeshLibrary.Get(.ttFlat)

    }
    var modelConstants = ModelConstants()
    var mesh: Mesh!
    var texture: MTLTexture!
    var material = CustomMaterial()

    func setTexture(_ texture: TextureTypes){
        self.texture = Textures.Get(texture)
        self.material.useTexture = true
    }
    
    override func update() {
        modelConstants.modelMatrix = modelMatrix
        super.update()
    }
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        if shouldUpdate {
        switch _currentSelect {
        case .Reject:
            rejectStep(deltaTime)
        default:
            print("updating Tube Representation for no reason.")
        }
        }
    }
    
    var previousSelectState: TubeSelectColors = .NoSelection
    func conflict() {
        _selectCountdown = defaultSelectCountdown
        if _currentSelect != .Reject {
            previousSelectState = _currentSelect
        }
        _currentSelect = .Reject
    }
    private var _selectCountdown: Float = 1.0
    let defaultSelectCountdown: Float =  1.0
    func rejectStep(_ deltaTime: Float) {
        if _selectCountdown > 0.0 {
        _selectCountdown -= deltaTime
        } else {
            _selectCountdown = defaultSelectCountdown
           _currentSelect = previousSelectState
            shouldUpdate = false
        }
    }
    
    func selectEffect(_ selectType: TubeSelectColors) {
        previousSelectState = selectType
        _currentSelect = selectType
    }
    
    func clearEffect() {
        _currentSelect = .NoSelection
    }
    
}

extension TubeRep: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        switch _currentSelect {
        case .NoSelection:
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Instanced))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            // Vertex
            renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
            //Fragment
            renderCommandEncoder.setFragmentBytes(&material, length : CustomMaterial.stride, index : 1)
            mesh.drawPrimitives(renderCommandEncoder)
        default:
            var gameTime = GameTime.TotalGameTime
            renderCommandEncoder.setRenderPipelineState(RenderPipelineStates.Get(.Select))
            renderCommandEncoder.setDepthStencilState(DepthStencilStates.Get(.Less))
            // Vertex
            renderCommandEncoder.setVertexBytes(&modelConstants, length : ModelConstants.stride, index: 2)
            //Fragment
            renderCommandEncoder.setFragmentBytes(&gameTime, length : Float.size, index : 0)
            renderCommandEncoder.setFragmentBytes(&material, length : CustomMaterial.stride, index : 1)
            renderCommandEncoder.setFragmentBytes(&_selectColors[_currentSelect], length : float3.size, index : 2)
            
            mesh.drawPrimitives(renderCommandEncoder)
        }
    }
}

enum TubeSelectColors {
    case NoSelection
    case Selected
    case Reject
    case Finished
}
