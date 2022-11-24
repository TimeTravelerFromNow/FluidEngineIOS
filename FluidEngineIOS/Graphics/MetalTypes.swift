import MetalKit

protocol sizeable{ }
extension sizeable{
    static var size: Int{
        return MemoryLayout<Self>.size
    }
    
    static var stride: Int{
        return MemoryLayout<Self>.stride
    }
    
    static func size(_ count: Int)->Int{
        return MemoryLayout<Self>.size * count
    }
    
    static func stride(_ count: Int)->Int{
        return MemoryLayout<Self>.stride * count
    }
}

typealias uint32 = UInt32
typealias half2  = SIMD2<Float32>
typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>
typealias int2 = SIMD2<Int32>
typealias long2 = SIMD2<Int>

extension Bool: sizeable { }
extension uint32: sizeable { }
extension Int32: sizeable { }
extension Float: sizeable { }
extension float2: sizeable { }
extension float3: sizeable { }
extension float4: sizeable { }

struct Vertex: sizeable {
    var position: float3
    var color: float4 = ColorUtil.randomColor
    var textureCoordinate: float2
    var normal : float3
    var tangent : float3
    var bitangent : float3
}

struct SceneConstants: sizeable {
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
}

struct ModelConstants: sizeable {
    var modelMatrix = matrix_identity_float4x4
}

struct Material: sizeable{
    var color = float4(0.6, 0.6, 0.6, 1.0)
    var isLit: Bool = true
    var useBaseTexture: Bool = false
    var useNormalMapTexture: Bool = false
    
    var ambient: float3 = float3(0.1, 0.1, 0.1)
    var diffuse: float3 = float3(1,1,1)
    var specular: float3 = float3(1,1,1)
    var shininess: Float = 2
}

struct CustomMaterial : sizeable {
    var color = float4(0.8,0.8,0.8,1.0)
    var useMaterialColor : Bool = false
    var useTexture: Bool = false
}

struct CustomVertex: sizeable {
    var position: float3
    var color: float4
    var textureCoordinate: float2
}

struct FluidConstants: sizeable {
    var ptmRatio: Float
    var pointSize: Float
}

struct MBEVertex: sizeable {
    var position: packed_float4
    var texCoords: packed_float2
}
