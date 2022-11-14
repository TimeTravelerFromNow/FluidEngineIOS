import Foundation


var MyGameLevels = [  level0, level1, level2, level3]


let level0: [ [ TubeColors ] ] =
[
    [.Red, .Blue, .Red, .Blue],
    [.Blue, .Red, .Blue, .Red],
    [ .Empty, .Empty, .Empty, .Empty],
]

let level1: [ [TubeColors] ] =
    [
        
            [ .Blue, .Green, .Empty, .Empty],
            [  .Green, .Purple, .Blue, .Empty ],
            [  .Purple, .Blue, .Blue, .Green],
        [ .Green, .Empty, .Empty, .Empty],
        [ .Purple, .Red, .Purple, .Red]
        
    ]

let level2: [ [TubeColors] ] =
    [
        
            [ .Blue, .Red, .Green, .Red],
            [  .Green, .Red, .Blue, .Empty ],
            [  .Red, .Empty, .Empty, .Empty],
        [ .Empty, .Empty, .Empty, .Empty],
        [ .Red, .Green, .Red, .Green],
        [ .Empty, .Empty, .Empty, .Empty]

        
    ]
let level3: [ [TubeColors] ] =
    [
        
            [ .Green, .Red, .Green, .Red],
            [  .Blue, .Purple, .Purple, .Blue ],
            [  .Blue, .Red, .Empty, .Empty],
        [ .Empty, .Empty, .Empty, .Empty],
        [ .Red, .Blue, .Red, .Blue],
        [ .Empty, .Empty, .Empty, .Empty],

            
                [ .Green, .Red, .Green, .Red],
                [  .Blue, .Purple, .Purple, .Blue ],
                [  .Blue, .Red, .Empty, .Empty],
            [ .Empty, .Empty, .Empty, .Empty],
            [ .Red, .Blue, .Red, .Blue],
            [ .Empty, .Empty, .Empty, .Empty]
    ]
