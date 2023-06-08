
struct CustomMatrix<T> {
    let rows: Int, columns: Int
    var grid: [T]
    
    init(rows: Int, columns: Int,defaultValue: T) {
        self.rows = rows
        self.columns = columns
        grid = Array(repeating: defaultValue, count: rows * columns)
    }
    func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    subscript(row: Int, column: Int) -> T {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }
}

typealias TestTubeMatrix = CustomMatrix<TestTube>

typealias TestTubeLevelMatrix = CustomMatrix<[TubeColors]>

final class CustomMathMethods {
    public static func positionsMatrix( _ atCenter: float2, withSpacing: float2, rowLength: Int, totalCount: Int ) -> CustomMatrix<float2?> {
        let rowCount = Int(ceil( Float(totalCount) / Float(rowLength) ))
        if( rowCount == 0 ) {
            print("positionMatrix() WARN::asked for a matrix with zero elements")
            return CustomMatrix<float2?>.init(rows: 0, columns: 0, defaultValue: nil)
        }
        var firstRowCount = totalCount % rowLength // remainder is last row number, if zero, it is eq to row L
        if(firstRowCount == 0) { firstRowCount = rowLength }
        var outputMat = CustomMatrix<float2?>.init(rows: rowCount, columns: rowLength, defaultValue: float2(0,0))
        let xSep = withSpacing.x
        let ySep = withSpacing.y
        let x_center = atCenter.x - Float(rowLength) * xSep / 2
        let y_center = atCenter.y - Float(rowCount - 1) * ySep / 2
        let firstR_x_center = atCenter.x - Float( firstRowCount - 1 ) * xSep / 2
        
        for x in 0..<rowLength {
            if x < firstRowCount {
                outputMat[0, x] = float2( xSep * Float(x) + firstR_x_center, y_center)
            }
            else{
                outputMat[0, x] = nil
            }
        }
        
        for y in 1..<rowCount {
            for x in 0..<rowLength {
                outputMat[y, x] = float2( xSep * Float(x) + x_center, ySep * Float(y) + y_center )
            }
        }
        
        return outputMat
    }
    
    public static func tParameterArray( _ forArray: [float2] ) -> [ Float ] { // for control points
        // MARK: tParams must be strictly increasing
        var totalL: Float = 0.0
        var tParams: [Float] = [ totalL ]
        // assign tParams to calculated lengths
        for i in 1..<forArray.count {
            totalL += length( forArray[i] - forArray[i - 1] )
            tParams.append( totalL)
        }
        tParams.map { $0 / totalL } // for drawing different shades
        return tParams
    }
    
    public static func getSourceTVals( _ fromControlPts: [Float], density: Int, excludeFirstAndLast: Bool = false ) -> ( Int, [Float] ){
        if( fromControlPts.count < 2 ) { print("Pipe build from control points WARN:: none or not enough control points."); return (0, [])}
        if( fromControlPts.count < 4 && excludeFirstAndLast ) { print("Pipe build from control points WARN:: none or not enough control points."); return (0, [])}
        var trimmedControlPoints = fromControlPts
        if( excludeFirstAndLast ) {
            trimmedControlPoints.removeFirst()
            trimmedControlPoints.removeLast()
        }
        // MARK: dangerous
        let minT = trimmedControlPoints.min()!
        let maxT = trimmedControlPoints.max()!
        var segmentCount = trimmedControlPoints.count * density
        let increment = (maxT - minT) / Float( segmentCount  )
        var outputArr = Array( stride(from: minT, to: maxT, by: increment ))
        
        // we need the last control point to equal the target value no matter what, so we have accurate destinations.
        guard var lastCtrPt = fromControlPts.last
        else {
            print("param t src array WARN:: wanted to get last t parameter to resize perfectly, but it was nil")
            return (0, [])
        }
        if (outputArr.count != segmentCount) {
            print("param t src array WARN::trimmed totalSegments \(segmentCount) not equal to array size \(outputArr.count), adding the final hardcoded t parameter")
            // try to add the last t parameter as the last control point
            outputArr.append( lastCtrPt )
        } else {
            // hardcode the last one to be the final control point, so that we reach our desired destination.
            outputArr[ outputArr.count - 1 ] = lastCtrPt
        }
        segmentCount = outputArr.count
        return ( segmentCount, outputArr )
    }
}
