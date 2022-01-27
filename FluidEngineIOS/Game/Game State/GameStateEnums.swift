import Foundation

enum TubeColors {
    case Empty
    case Red
    case Green
    case Blue
    case Purple
    case Dark
    case Light
}

let WaterColors: [TubeColors:float4] =
    [ .Empty:float4(0.1,0.1,0.1,1.0),
      .Red:float4(0.7, 30 / 255, 13 / 255, 255 / 255),
      .Green    :float4(0.4, 0.8, 0.3, 1),
      .Blue     :float4(70 / 255, 130  / 255, 245 / 255, 1),
      .Purple   :float4(140 / 255, 10  / 255, 140 / 255, 1)
]

protocol GameLevel {
    func goBackMoves(_ numMoves: Int) -> Bool
    func goForwardMoves(_ numMoves: Int) -> Bool
    
    func getNumMoves() -> Int
    func resetLevel()
}

class TubeLevel: GameLevel {
    func resetLevel() {
        _moves = 0
    }
    
    init(_ level: Int = 0) {
        self.levelNo = level
        if levelNo > MyGameLevels.count {
            print("only \(MyGameLevels.count) levels programmed, asked for \(levelNo).")
            return
        }
        self.startingLevel = levelMatFromArray( MyGameLevels[level] )
        self.colorStates = levelMatFromArray( MyGameLevels[level] )
    }
    
    let numTubes: Int8 = 0
    private var _moves: Int = 0
    var levelNo : Int = 0
    var startingLevel : TubeLevelMatrix!
    var maxHistory:Int = 5
    
    var colorStates:  TubeLevelMatrix!
    private var _previousColorStates: [ TubeLevelMatrix ] = []// history
    private var _futureColorStates:   [ TubeLevelMatrix ] = [] //for undoing an undo (called future as a joke)
        
    func levelMatFromArray(_ state: StartingColorState   ) -> TubeLevelMatrix  {
        var levelMat: TubeLevelMatrix = TubeLevelMatrix.init(rows: state.rows, columns: state.columns, defaultValue: [TubeColors].init(repeating: .Empty, count: 4))
        var linOff = 0
        for y in 0..<state.rows {
            for x in 0..<state.columns {
                levelMat[y,x] = state.linearColors[linOff]
                linOff += 1
            }
        }
        return levelMat
    }
    func pourTube(pourPos: long2, candPos: long2) -> ([TubeColors],[TubeColors]) {
        
        var pourColors = colorStates[pourPos.x, pourPos.y]
        var candColors = colorStates[candPos.x, candPos.y]
        // save state before overriding
        if _previousColorStates.count > maxHistory {
            _previousColorStates.removeFirst()
        }
        _previousColorStates.append(colorStates)
        print("Before")
        print(pourColors, candColors)
        (pourColors, candColors) = getExchangeColors(pourColors: pourColors, candidateColors: candColors)
        colorStates[pourPos.x, pourPos.y] = pourColors
        colorStates[candPos.x, candPos.y] = candColors
        print("after")
        print(pourColors, candColors)
        return (pourColors, candColors)
    }
    
    func getExchangeColors(pourColors: [TubeColors], candidateColors: [TubeColors]) -> ([TubeColors],[TubeColors]) {
        var newPouredColors : [TubeColors] = pourColors
        var newCandidateColors : [TubeColors] = candidateColors
        var consecCount: Int = 1
        
        var topMostNonEmptyPourIndex = getTopMostNonEmptyIndex(pourColors)
        let top_type = pourColors[topMostNonEmptyPourIndex]
        if topMostNonEmptyPourIndex > 0 { // find out if more are possible
        for index in 1...topMostNonEmptyPourIndex { // count from topMost backwards
            if (top_type == pourColors[topMostNonEmptyPourIndex - index]) {
                consecCount += 1
            }
            else { break }
        }
        }
        print(consecCount)
        var numberPoured = 0
        for (i, color) in candidateColors.enumerated() {
            if( color == .Empty) {
                if (numberPoured < consecCount) {
                    newCandidateColors[i] = top_type
                    newPouredColors[topMostNonEmptyPourIndex] = .Empty
                    numberPoured += 1
                    topMostNonEmptyPourIndex -= 1
                }
            }
        }
        return (newPouredColors, newCandidateColors)
    }
    
    public func getTopMostNonEmptyIndex(_ ofTubeColors: [TubeColors] ) ->Int {
        var topIndex : Int = -1
        for (i,c) in ofTubeColors.enumerated() {
            if( c != .Empty) {
                topIndex = i
            } 
        }
        return topIndex
    }
    
    func pourConflict(pourPos: long2, candPos: long2) -> Bool {
        let pourColors = colorStates[pourPos.x,pourPos.y]
        let candColors = colorStates[candPos.x, candPos.y]
        var conflict = false
        
        let nonEmptyTopIndex = getTopMostNonEmptyIndex(pourColors)
        if(nonEmptyTopIndex == -1) { return true } // empty (nothing to pour!)
        
        let top_type = pourColors[nonEmptyTopIndex]

        let nonEmptyCandidateTopIndex = getTopMostNonEmptyIndex(candColors)
        if(nonEmptyCandidateTopIndex != -1)
        {
            if candColors[nonEmptyCandidateTopIndex] != top_type {
                conflict = true // not empty, and the top candidate doesnt match pouring color.
            }
        }      // else all ok, we can pour into something empty, but we cannot pour into something full.
        if( candColors.last != .Empty ){
            conflict = true
        }
        print(conflict)
        return conflict
    }
    
    func goBackMoves(_ numMoves: Int) -> Bool {
        var success = false
        let maxBackMoves = _previousColorStates.count
        if  maxBackMoves > numMoves {
            for _ in 0..<numMoves-1 { // last one is left for the main state to assume the value of.
                if let backElm = _previousColorStates.popLast() {
                _futureColorStates.append(backElm)
                } else { print("Big problem, all the counting is off somehow."); return false; }
            }
            if let finalBack = _previousColorStates.popLast() {
            colorStates = finalBack
            } else { print("Another problem, last element to pop does not exist, (off by one maybe)."); return false;}
            success = true
        } else { print("Trying to go back more (\(numMoves)) moves than possible (\(maxBackMoves)).")}
        return success
    }
    
    func goForwardMoves(_ numMoves: Int) -> Bool {
        var success = false
        let maxForwardMoves = _previousColorStates.count
        if  maxForwardMoves > numMoves {
            for _ in 0..<numMoves-1 { // last one is left for the main state to assume the value of.
                if let forwardElm = _futureColorStates.popLast() {
                _futureColorStates.append(forwardElm)
                } else { print("Big problem, all the counting is off somehow."); return false; }
            }
            if let finalBack = _futureColorStates.popLast() {
            colorStates = finalBack
            } else { print("Another problem, last element to pop does not exist, (off by one maybe)."); return false;}
            success = true
        } else { print("Trying to go forward more (\(numMoves)) moves than possible (\(maxForwardMoves)).")}
        return success
    }
    
    func getNumMoves() -> Int {
        return _moves
    }
}

