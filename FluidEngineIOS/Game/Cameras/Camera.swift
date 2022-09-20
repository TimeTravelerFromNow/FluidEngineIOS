
import simd

class Camera: Node {
    var aspect: Float = 1.0
    var viewMatrix: matrix_float4x4 {
        var viewMatrix = matrix_identity_float4x4
        viewMatrix.rotate(angle: self.getRotationX(), axis: X_AXIS)
        viewMatrix.rotate(angle: self.getRotationY(), axis: Y_AXIS)
        viewMatrix.rotate(angle: self.getRotationZ(), axis: Z_AXIS)
        viewMatrix.translate(-getPosition())
        return viewMatrix
    }
    
    var projectionMatrix: matrix_float4x4 {
        return matrix_float4x4.perspective(degreesFov: 90,
                                           aspectRatio: aspect,
                                           near: 0.1,
                                           far: 100)
    }
}

class OrthoCamera: Camera {
    private var frameSize: Float = 1.0
    
    func setFrameSize(_ to: Float) { frameSize = to}
    func getFrameSize() -> Float { return frameSize }
    func scaleFrame(_ by: Float) { frameSize += by }
    
    var rect : Rectangle { return Rectangle(left: frameSize * aspect,
                                            right: -frameSize * aspect,
                         top: frameSize,
                         bottom: -frameSize)}
    override var projectionMatrix: matrix_float4x4 {
        return matrix_float4x4.orthographicRect(rect: rect, near: 0.1, far: 100)
    }
}

