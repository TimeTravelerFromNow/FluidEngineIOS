import MetalKit

class MBETextMesh: Mesh {
    
    private var _vertexBuffer: MTLBuffer!
    private var _indexBuffer: MTLBuffer!
    private var _atlasTexture: Data!
    
    private var _vertexCount: Int!
    private var _indexCount: Int!

    
    init(_ withString: String, inRect:CGRect, fontAtlas: MBEFontAtlas, atSize: CGFloat) {
        super.init()
        buildMeshWithString(string: withString, inRect: inRect, fontAtlas: fontAtlas, atSize: atSize)
        _atlasTexture = fontAtlas.textureData
    }
    
    func buildMeshWithString(string: String, inRect: CGRect, fontAtlas: MBEFontAtlas, atSize: CGFloat) {
        guard let font = fontAtlas.parentFont else { fatalError("buildMeshWithString ERROR::font from fontAtlas was nil")}
        let attributes = [NSAttributedString.Key.font: font]
        let attrString = NSAttributedString.init(string: string, attributes: attributes)
        let stringRange = CFRangeMake( 0, attrString.length )
        let rectPath = CGPath(rect: inRect, transform: nil)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let frame = CTFramesetterCreateFrame(framesetter, stringRange, rectPath, nil)
        var frameGlyphCount: CFIndex = 0
        let lines = CTFrameGetLines(frame)
        (lines as NSArray).enumerateObjects { lineObject, lineIndex, stopPtr in
            frameGlyphCount += CTLineGetGlyphCount(lineObject as! CTLine)
        }
        
        let vertexCount = frameGlyphCount * 4
        let indexCount = frameGlyphCount * 6
        _indexCount = indexCount
        _vertexCount = vertexCount
        
        var vertices: [MBEVertex] = [MBEVertex].init(repeating: MBEVertex(), count: vertexCount)
        var indices: [MBEIndexType] = [MBEIndexType].init(repeating: 0, count: indexCount)
        
        var v: MBEIndexType = 0
        var i: MBEIndexType = 0
        
        enumerateGlyphs(frame) { glyph, glyphIndex, glyphBounds in
            if( glyph >= fontAtlas.glyphDescriptors.count) {
                print("MBETextMesh.buildMeshWithString() WARNING::Font atlas has no entry corresponding to glyph \(glyph)")
                return
            }
            
            let glyphInfo = fontAtlas.glyphDescriptors[Int(glyph)]
            let minX = Float(glyphBounds.minX)
            let maxX = Float(glyphBounds.maxX)
            let minY = Float(glyphBounds.minY)
            let maxY = Float(glyphBounds.maxY)
            let minS = Float(glyphInfo.topLeftTexCoord.x)
            let maxS = Float(glyphInfo.bottomRightTexCoord.x)
            let minT = Float(glyphInfo.topLeftTexCoord.y)
            let maxT = Float(glyphInfo.bottomRightTexCoord.y)
            vertices[Int(v.advanced(by: 1))] = MBEVertex(position: packed_float4(minX, maxY,0,1), texCoords: packed_float2(minS, maxT))
            vertices[Int(v.advanced(by: 1))] = MBEVertex(position: packed_float4(minX, minY, 0, 1), texCoords: packed_float2(minS, minT))
            vertices[Int(v.advanced(by: 1))] = MBEVertex(position: packed_float4(maxX, minY, 0, 1), texCoords: packed_float2(maxS, minT))
            vertices[Int(v.advanced(by: 1))] = MBEVertex(position: packed_float4(maxX, minY, 0, 1), texCoords: packed_float2(maxS, maxT) )
            indices[Int(i.advanced(by: 1))] = MBEIndexType(glyphIndex) * 4
            indices[Int(i.advanced(by: 1))] = MBEIndexType(glyphIndex) * 4 + 1
            indices[Int(i.advanced(by: 1))] = MBEIndexType(glyphIndex) * 4 + 2
            indices[Int(i.advanced(by: 1))] = MBEIndexType(glyphIndex) * 4 + 2
            indices[Int(i.advanced(by: 1))] = MBEIndexType(glyphIndex) * 4 + 3
            indices[Int(i.advanced(by: 1))] = MBEIndexType(glyphIndex) * 4
        }
        
        _vertexBuffer = Engine.Device.makeBuffer(bytes: &vertices, length: MBEVertex.size( vertexCount) )
        _vertexBuffer.label = "Text Mesh Vertices"
        _indexBuffer = Engine.Device.makeBuffer(bytes: &indices, length: MBEIndexType.size(indexCount))
        _indexBuffer.label = "Text Mesh Indices"
    }
    func enumerateGlyphs(_ inFrame: CTFrame,
                    closure: ( CGGlyph, Int, CGRect ) -> Void ){
        
        let entire: CFRange = CFRangeMake(0, 0)
        let framePath = CTFrameGetPath(inFrame)
        let frameBoundingRect = framePath.boundingBoxOfPath
        
        let lines: NSArray = CTFrameGetLines(inFrame)
        let lineOriginBuffer = [CGPoint].init(repeating: CGPoint(x:0,y:0), count: lines.count)
        var glyphIndexInFrame: CFIndex = 0
        UIGraphicsBeginImageContext(CGSize(width:1,height:1))
        
        let context = UIGraphicsGetCurrentContext()
        
        lines.enumerateObjects { lineObject, lineIndex, stopPtr in
            let line: CTLine = lineObject as! CTLine
            let lineOrigin = lineOriginBuffer[lineIndex]
            
            let runs: NSArray = CTLineGetGlyphRuns(line)
            runs.enumerateObjects { runObject, rangeIndex, stopPtr in
                let run = runObject as! CTRun
                
                let glyphCount = CTRunGetGlyphCount(run)
                
                var glyphBuffer = [CGGlyph].init(repeating: 0, count: glyphCount)
                
                CTRunGetGlyphs(run, entire, &glyphBuffer)
                
                var positionBuffer = [CGPoint].init(repeating: CGPoint(x:0,y:0), count: glyphCount)
                CTRunGetPositions(run, entire, &positionBuffer)
                
                for glyphIndex in 0..<glyphCount {
                    let glyph = glyphBuffer[glyphIndex]
                    let glyphOrigin = positionBuffer[glyphIndex]
                    var glyphRect = CTRunGetImageBounds(run, context, CFRangeMake(glyphIndex, 1))
                    let boundsTransX = frameBoundingRect.origin.x + lineOrigin.x
                    let boundsTransY = frameBoundingRect.height + frameBoundingRect.origin.y - lineOrigin.y + glyphOrigin.y
                    let pathTransform: CGAffineTransform = __CGAffineTransformMake(1, 0, 0, -1, boundsTransX, boundsTransY)
                    glyphRect = glyphRect.applying(pathTransform)
                    closure( glyph, glyphIndexInFrame, glyphRect )
                    
                    glyphIndexInFrame += 1
                }
            }
        }
        UIGraphicsEndImageContext()
    }
    
}

extension MBETextMesh: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setVertexBytes(&_atlasTexture, length: _atlasTexture.count, index: 2)
        renderCommandEncoder.setVertexBytes(&_vertexBuffer, length: _vertexCount, index: 3)
        renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: _indexCount,
                                                   indexType: .uint16, indexBuffer: _indexBuffer,
                                                   indexBufferOffset: 0)
        
    }
}

// MARK: refactor into proper places
//struct MBEVertex {
//    var position: packed_float4 = packed_float4(0)
//    var texCoords: packed_float2 = packed_float2(0)
//}
extension MBEVertex : sizeable { }

typealias MBEIndexType = UInt16
extension MBEIndexType: sizeable { }
