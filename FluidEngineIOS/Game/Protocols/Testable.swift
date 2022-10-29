protocol Testable {
    
    var isTesting: Bool { get set }
    
    var isShowingMiniMenu: Bool { get set }
    
    func touchesBegan(_ boxPos: float2)
    
    func touchDragged(_ boxPos: float2)
    
    func touchEnded()
    
    func testingRender(_ renderCommandEncoder: MTLRenderCommandEncoder )
}
