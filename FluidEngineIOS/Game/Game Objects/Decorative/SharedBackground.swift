
class SharedBackground: Node {
    
    private static var background: CloudsBackground!
    public static var Background: CloudsBackground! { return self.background }
    
    static func Initialize() {
        background = CloudsBackground()
        background.setPositionZ(-0.1)
        background.setScale(5)
    }
    
}
