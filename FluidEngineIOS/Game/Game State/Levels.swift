import Foundation


var MyGameLevels: [StartingColorState] = [  level0, level1 ]


struct StartingColorState {
    let linearColors: [ [TubeColors] ]!
    let rows: Int!
    let columns: Int!
}
// linear representations, convert to matrix at runtime.
let level0 = StartingColorState( linearColors:
    [
        
            [ .Blue, .Red, .Green, .Red],
            [  .Green, .Red, .Blue, .Empty ],
            [  .Red, .Empty, .Empty, .Empty],
        [ .Empty, .Empty, .Empty, .Empty],
        [ .Red, .Red, .Red, .Red],
        []
        
    ]
                                , rows: 2, columns: 3)


let level1 = StartingColorState( linearColors:
    [
        
            [ .Blue, .Red, .Green, .Red],
            [  .Green, .Red, .Blue, .Empty ],
            [  .Red, .Empty, .Empty, .Empty],
        [ .Empty, .Empty, .Empty, .Empty],
        [ .Red, .Green, .Red, .Green],
        [ .Empty, .Empty, .Empty, .Empty]

        
    ]
    , rows: 2, columns: 3)
