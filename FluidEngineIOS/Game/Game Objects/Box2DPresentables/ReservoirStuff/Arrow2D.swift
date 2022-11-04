
class Arrow2D {
    
    var tailPos: float2!
    var headPos: float2!
    var length: Float!
    var pathVertices: [float2] = []
    var directionVectors: [float2] = []
        
    private var _unitDir: float2 { return normalize( headPos - tailPos ) }
    private var _newUnitDir: float2 = float2(0)
    public static let ninetyDegreeRotMat = matrix_float2x2( float2( cos(.pi/2), sin(.pi/2) ),
                                                        float2( -sin(.pi/2), cos(.pi/2) ) )
    
    private var _maxTurnAngle: Float = .pi/4
    func setMaxTurnAngle(_ to: Float) { _maxTurnAngle = to }
    func getMaxTurnAngle() -> Float { return _maxTurnAngle }
    
    init(_ origin: float2, length: Float, direction: float2 = float2(0,-1)) {
        self.tailPos = origin
        self.length = length
        let unitDir = normalize( direction )
        _newUnitDir = unitDir
        self.headPos = tailPos + length * unitDir
        pathVertices.append(tailPos)
        directionVectors.append( unitDir )
    }
    
    func turnAndMoveArrow(_ toDest: float2) {
        moveArrowToNewDir()
        turnArrow( toDest )
    }
    
    private func turnArrow(_ toDest: float2) {
            let vectorToDest = toDest - tailPos
            let unitToDest = normalize(vectorToDest)
            let shadow = dot(_unitDir, unitToDest  )
            
            var angleToDest = abs(acos(shadow))
            if (angleToDest > _maxTurnAngle ) {
                angleToDest = _maxTurnAngle
            }
            // determine whether left or right with cross product!
            let cross = cross(_unitDir, unitToDest)
            let sign = cross.z
            if sign < 0 {
                angleToDest *= -1
            }
            
            var rotationMat = matrix_float2x2()
            rotationMat.columns.0 = float2( cos(angleToDest), sin(angleToDest) )
            rotationMat.columns.1 = float2( -sin(angleToDest), cos(angleToDest) )
            _newUnitDir =  rotationMat * _unitDir
    }
    
    private func moveArrowToNewDir() {
        tailPos = headPos
        headPos = headPos + _newUnitDir * length
        pathVertices.append(tailPos)
        directionVectors.append(_newUnitDir)
    }
}
