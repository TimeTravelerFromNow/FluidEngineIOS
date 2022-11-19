
class GunObject: Node {
    
    var barrel: Friendly!
    var Mount: Friendly!
    
    init(origin: float2) {
        super.init()
        barrel = Friendly( center: origin, scale: 1.0, .Barrel, .BarrelTexture, density: 1.0 )
        addChild(barrel)
    }
}
