import Foundation


var MyGameLevels = [  level0, level1, level2]


let level0: [ [ TubeColors ] ] =
[
    [.Red, .Blue, .Red, .Blue],
    [.Blue, .Red, .Blue, .Red],
    [.Empty,.Empty,.Empty,.Empty]
]

let level1: [ [TubeColors] ] =
    [
        
            [ .Blue, .Red, .Green, .Red],
            [  .Green, .Red, .Blue, .Empty ],
            [  .Red, .Empty, .Empty, .Empty],
        [ .Empty, .Empty, .Empty, .Empty],
        [ .Red, .Red, .Red, .Red]
        
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
