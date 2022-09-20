
class FluidEnvironment: Node {
    
    private static var fluidEnvironment: DebugEnvironment!
    public static var Environment: DebugEnvironment! { return self.fluidEnvironment }
    
    static func Initialize() {
        fluidEnvironment = DebugEnvironment()
    }
    
}
