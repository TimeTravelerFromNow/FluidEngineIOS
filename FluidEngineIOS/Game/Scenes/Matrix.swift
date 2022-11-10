
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

func positionMatrix( _ atCenter: float2, withSpacing: float2, rowLength: Int, totalCount: Int ) -> CustomMatrix<float2?> {
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
