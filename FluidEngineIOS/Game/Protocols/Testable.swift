protocol Testable {
    
    var isTesting: Bool { get set }
    
    var isShowingMiniMenu: Bool { get set }
    
    func touchesBegan(_ boxPos: float2)
    
    func touchDragged(_ boxPos: float2, _ deltaTime: Float)
    
    func touchEnded(_ boxPos: float2)
    
    func testingRender(_ renderCommandEncoder: MTLRenderCommandEncoder )
}
