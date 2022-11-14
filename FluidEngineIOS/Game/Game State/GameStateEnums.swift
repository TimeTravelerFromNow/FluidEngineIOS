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
    [ .Empty    :float4(0.1,0.1,0.1,1.0),
      .Red      :float4(0.9, 30 / 255, 13 / 255, 255 / 255),
      .Green    :float4(0.4, 0.8, 0.3, 1),
      .Blue     :float4(70 / 255, 130  / 255, 245 / 255, 1),
      .Purple   :float4(48 / 255, 30  / 255, 80 / 255, 1)
]
//XMas ?
//let WaterColors: [TubeColors:float4] =
//    [ .Empty    :float4(0.1,0.1,0.1,1.0),
//      .Red      :float4(213/255, 5/255, 0, 1),
//      .Green    :float4(7/255, 213/255, 0, 1),
//    .Blue     :float4(0.55, 0.9, 1.0, 1),
//    .Purple   :float4(0.71 , 0.55, 1.0, 1)
//]

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
    
    init(_ level: Int = 1) {
        self.levelNo = level
        if levelNo > MyGameLevels.count {
            print("only \(MyGameLevels.count) levels programmed, asked for \(levelNo).")
            return
        }
        self.startingLevel = MyGameLevels[level]
        self.colorStates = MyGameLevels[level]
    }
    
    let numTubes: Int8 = 0
    private var _moves: Int = 0
    var levelNo : Int = 0
    var startingLevel : [ [ TubeColors ] ] = [] // Colors for each tube
    var maxHistory:Int = 5
    
    var colorStates:  [ [TubeColors] ] = []
    private var _previousColorStates: [ [[TubeColors]] ] = []// history
    private var _futureColorStates:   [ [[TubeColors]] ] = [] //for undoing an undo (called future as a joke)
        
    func pourTube(pouringTubeIndex: Int, pourCandidateIndex: Int) -> ([TubeColors],[TubeColors]) {
        if pouringTubeIndex > colorStates.count { print("Pouring Tube Index \(pouringTubeIndex), out of range")
            return ([],[])}
        if pourCandidateIndex > colorStates.count { print("Pouring Candidate Index \(pourCandidateIndex), out of range")
            return ([],[])}
        var pouringTubeColors = colorStates[pouringTubeIndex]
        var candidateTubeColors = colorStates[pourCandidateIndex]
        // save state before overriding
        if _previousColorStates.count > maxHistory {
            _previousColorStates.removeFirst()
        }
        _previousColorStates.append(colorStates)
        print("Before")
        print(pouringTubeColors, candidateTubeColors)
        (pouringTubeColors, candidateTubeColors) = getExchangeColors(pourColors: pouringTubeColors, candidateColors: candidateTubeColors)
        colorStates[pouringTubeIndex] = pouringTubeColors
        colorStates[pourCandidateIndex] = candidateTubeColors
        print("after")
        print(pouringTubeColors, candidateTubeColors)
        return (pouringTubeColors, candidateTubeColors)
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
    
    func pourConflict(pouringTubeIndex: Int, pouringCandidateIndex: Int) -> Bool {
        let pouringTypes   = colorStates[pouringTubeIndex]
        let candidateTypes = colorStates[pouringCandidateIndex]
        var conflict = false
        
        let nonEmptyTopIndex = getTopMostNonEmptyIndex(pouringTypes)
        if(nonEmptyTopIndex == -1) { return true } // empty (nothing to pour!)
        
        let top_type = pouringTypes[nonEmptyTopIndex]

        let nonEmptyCandidateTopIndex = getTopMostNonEmptyIndex(candidateTypes)
        if(nonEmptyCandidateTopIndex != -1)
        {
            if candidateTypes[nonEmptyCandidateTopIndex] != top_type {
                conflict = true // not empty, and the top candidate doesnt match pouring color.
            }
        }      // else all ok, we can pour into something empty, but we cannot pour into something full.
        if( candidateTypes.last != .Empty ){
            conflict = true
        }
        if( candidateTypes.first == .Empty) {
            conflict = false // we can always pour into empty tubes
        }
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

