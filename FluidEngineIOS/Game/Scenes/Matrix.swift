
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

func getCenteredPositionMatrix(_ atCenter: float2, _ spacing: float2, rowLength: Int, nodeCount: Int) -> CustomMatrix<float2?> {
    let rowCount = Int(ceil( Float(nodeCount / rowLength) ))
    var outputMat = CustomMatrix<float2?>.init(rows: rowCount, columns: rowLength, defaultValue: nil)
    var rows: [ [float2?] ] = []
    var currXOffset = 0.0
    // positions according to spacings
    var linOff = 0
    for y in 0..<rowCount {
        let yPos = Float(y) * spacing.y + atCenter.y
        var currentRow = [float2?].init(repeating: nil, count: rowLength)
        for x in 0..<rowLength {
            if linOff == nodeCount { break }
            outputMat[y,x] = float2( Float(x) * spacing.x + atCenter.x , yPos )
            linOff += 1
        }
        rows.append(currentRow)
    }
    // now center each row.
    let halfX = Float(rowLength) / 2
    let halfY = Float(rowCount - 1) / 2
    var centering = float2(spacing.x * halfX, spacing.y * halfY  )
    for y in 0..<outputMat.rows {
        var extraCentering: Float = 0.0
        for x in 0..<rowLength {
            if( outputMat[y, x] == nil ) { // extra centering for rows missing some tubes.
                extraCentering -= spacing.x / 2
            }
        }
        for x in 0..<rowLength {
            outputMat[y, x]? -= centering + float2(extraCentering,0)
        }
    }
    return outputMat
}
