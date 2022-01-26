import Foundation
class OBJLoader {
    let objFileURL : URL!
    let objFileData : String!

    let lines: [String.SubSequence]!
    
    var vertexCount : Int { return vertices.count }
    var vertices : [OBJVertex] = []
    var vertexTextures : [VertexTexture] = []
    var vertexNormals : [VertexNormal] = []

    init(url: URL) {
        self.objFileURL = url
        self.objFileData = try! String(contentsOf: url)
        self.lines = objFileData.split(separator: "\n")
    }


struct OBJVertex {
    let x, y, z : Float
    
    init (_ floats : [Float]) {
        x = floats[0]
        y = floats[1]
        z = floats[2]
    }
}

struct VertexTexture {
    let u, v : Float
    init (_ floats : [Float]) {
        u = floats[0]
        v = floats[1]
    }
}

struct VertexNormal {
    let x, y, z : Float
    init (_ floats : [Float]) {
        x = floats[0]
        y = floats[1]
        z = floats[2]
    }
}


    func parse() {
        for x in lines {
            if x.starts(with: "#") {
                continue
            }
            
            let parseFloats = { (line : String.SubSequence) -> [Float] in
                return line.split(separator: " ").dropFirst().map() { Float($0)! }
            }
            
            if x.starts(with: "v ") {
                vertices.append(OBJVertex(parseFloats(x)))
            }
            
            if x.starts(with: "vt ") {
                vertexTextures.append(VertexTexture(parseFloats(x)))
            }
            
            if x.starts(with: "vn ") {
                vertexNormals.append(VertexNormal(parseFloats(x)))
            }
        }
    }
}
