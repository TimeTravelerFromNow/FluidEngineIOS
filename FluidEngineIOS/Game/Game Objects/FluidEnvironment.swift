
class FluidEnvironment: Node {
    
    private static var FluidEnvironment: DebugEnvironment!
    public static var Environment: DebugEnvironment! { return self.FluidEnvironment }
    
    static func Initialize() {
        FluidEnvironment = DebugEnvironment()
    }
    
}
