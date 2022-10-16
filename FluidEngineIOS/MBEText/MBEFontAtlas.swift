import MetalKit
import UIKit
import CoreText
import Foundation

class MBEFontAtlas {
    private var _parentFont: UIFont!
    private var _fontPointSize: CGFloat!
    private var _spread: CGFloat!
    private var _glyphDescriptors: [MBEGlyphDescriptor] = []
    private var _textureSize: Int!
    private var _textureData: Data!
    public let MBEFontAtlasSize: Int = 4096;

    public let MBEGlyphIndexKey = "glyphIndex";
    public let MBELeftTexCoordKey = "leftTexCoord";
    public let MBERightTexCoordKey = "rightTexCoord";
    public let MBETopTexCoordKey = "topTexCoord";
    public let MBEBottomTexCoordKey = "bottomTexCoord";
    public let MBEFontNameKey = "fontName";
    public let MBEFontSizeKey = "fontSize";
    public let MBEFontSpreadKey = "spread";
    public let MBETextureDataKey = "textureData";
    public let MBETextureWidthKey = "textureWidth";
    public let MBETextureHeightKey = "textureHeight";
    public let MBEGlyphDescriptorsKey = "glyphDescriptors";
    
    init(font: UIFont, textureSize: Int) {
        _parentFont = font
        _fontPointSize = font.pointSize
        _spread = self.estimatedLineWidth(font) * 0.5
        _textureSize = textureSize
        self.createTextureData()
    }
    
    func estimatedGlyphSize(_ forFont: UIFont) -> CGSize {
        let exemplarString: String = "{ǺOJMQYZa@jmqyw"
        let exemplarStringSize: CGSize = exemplarString.size( withAttributes: [ NSAttributedString.Key.font: forFont ] )
        let averageGlyphWidth = ceilf( Float( exemplarStringSize.width / CGFloat(exemplarString.count ) ) )
        let maxGlyphHeight = ceilf( Float( exemplarStringSize.height ) )
        return CGSize( width: CGFloat(averageGlyphWidth), height: CGFloat(maxGlyphHeight) )
    }
    
    func estimatedLineWidth(_ forFont: UIFont) -> CGFloat {
        let estimatedStrokeWidth = "!".size(withAttributes: [ NSAttributedString.Key.font: forFont ] ).width
        return CGFloat(ceilf(Float(estimatedStrokeWidth)))
    }
    
    func createQuantizedDistanceField(_ inData: CustomMatrix<Float>,
                                        width: Int,
                                       height: Int,
                                      normalizationFactor: Float) -> CustomMatrix<UInt8>
    {
        var outData = CustomMatrix<UInt8>.init(rows: height, columns: width, defaultValue: 0)

        for y in 0..<height {
            for x in 0..<width {
                var dist = inData[x, y]
                var clampDist = fmax(-normalizationFactor, fmin(dist, normalizationFactor))
                var scaledDist = clampDist / normalizationFactor
                let value: UInt8 = UInt8((scaledDist + 1) / 2) * UInt8.max
                outData[x, y] = value
            }
        }
        
        return outData;
    }
    
    func createTextureData() {
        assert(MBEFontAtlasSize >= self._textureSize )
        assert(MBEFontAtlasSize % self._textureSize == 0)
        let atlasData: [UInt8] = self.createAtlas(self._parentFont,
                                                  width: MBEFontAtlasSize,
                                                  height: MBEFontAtlasSize)
        
        let scaleFactor: Int = MBEFontAtlasSize / self._textureSize
        
        guard let distanceField = createSignedDistanceField(atlasData, width: MBEFontAtlasSize, height: MBEFontAtlasSize) else { fatalError("MBE createTextureData ERROR::couldn't create signed distance field.") }
        
        // Downsample the signed-distance field to the expected texture resolution
        let scaledField = createResampledData(distanceField,
                                                 width:MBEFontAtlasSize,
                                              height:MBEFontAtlasSize, scaleFactor: scaleFactor)
        let spread: CGFloat = estimatedLineWidth(self._parentFont) * 0.5
        
        // Quantize the downsampled distance field into an 8-bit grayscale array suitable for use as a texture
        let texture = createQuantizedDistanceField(scaledField, width: _textureSize, height: _textureSize, normalizationFactor: Float(spread))
        
        let textureByteCount = _textureSize * _textureSize
        _textureData = Data.init(bytes: texture.grid, count: textureByteCount)
    }
    
    func createResampledData(_ inData: CustomMatrix<Float>, width: Int, height: Int, scaleFactor: Int) -> CustomMatrix<Float> {
        assert( width % scaleFactor == 0 && height % scaleFactor == 0 )
        let scaledWidth: Int = width / scaleFactor
        let scaledHeight: Int = height / scaleFactor
        var outData = CustomMatrix<Float>.init(rows: scaledHeight, columns: scaledWidth, defaultValue: 0.0)
        for y in stride(from: 0, to: height, by: scaleFactor) {
            for x in stride(from: 0, to: width, by: scaleFactor) {
                var accum: Float = 0.0
                for ky in 0..<scaleFactor {
                    for kx in 0..<scaleFactor {
                        accum += inData[(x + kx), (y + ky)]
                    }
                }
                accum = accum / Float(scaleFactor * scaleFactor)
                
                outData[(x / scaleFactor), (y / scaleFactor)] = accum
            }
        }
        
        return outData
    }
    
    func createAtlas(_ forFont: UIFont, width: Int, height: Int) -> [UInt8] {
        var imageData: [UInt8] = [UInt8].init(repeating: 0, count: width * height)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo: CGImageAlphaInfo = CGImageAlphaInfo.none
        guard let context: CGContext = CGContext(data: &imageData,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: 8,
                                           bytesPerRow: width,
                                           space: colorSpace,
                                                 bitmapInfo: bitmapInfo.rawValue ) else { fatalError("createAtlas ERROR::CGBitmapContext couldn't be made and was nil") }
        
        // Turn off antialiasing so we only get fully-on or fully-off pixels.
        // This implicitly disables subpixel antialiasing and hinting.
        context.setAllowsAntialiasing(false)
        
        // Flip context coordinate space so y increases downward
        context.translateBy(x: 0, y: CGFloat(height));
        context.scaleBy(x: 1, y: -1);
        
        // Fill the context with an opaque black color
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1);
        
        let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height) )
        context.fill( rect );
        
        _fontPointSize = pointSizeThatFits( forFont, inAtlasRect: rect )
        let ctFont: CTFont =  CTFontCreateWithName((forFont.fontName as CFString),
                                                 _fontPointSize, nil)
        
        _parentFont = UIFont(name: forFont.fontName, size: _fontPointSize)
        
        let fontGlyphCount: CFIndex = CTFontGetGlyphCount(ctFont)
        
        let glyphMargin: CGFloat = estimatedLineWidth( _parentFont )
        
        // Set fill color so that glyphs are solid white
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1);
        
        var mutableGlyphs: [MBEGlyphDescriptor] = _glyphDescriptors
        _glyphDescriptors.removeAll()
        
        let fontAscent: CGFloat = CTFontGetAscent(ctFont);
        let fontDescent: CGFloat = CTFontGetDescent(ctFont);
        
        var origin:  CGPoint = CGPoint(x: 0,y: fontAscent);
        var maxYCoordForLine: CGFloat = -1;
        var glyph: CGGlyph = 0
        for g in 0..<fontGlyphCount {
            glyph = CGGlyph( g )
            var boundingRect = CGRect()
            CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, &glyph, &boundingRect, 1)
            print(boundingRect)
            
            if (origin.x + boundingRect.maxX + glyphMargin > CGFloat(width) ) {
                origin.x = 0
                origin.y = maxYCoordForLine + glyphMargin + fontDescent
                maxYCoordForLine = -1
            }
            
            if (origin.y + boundingRect.maxY > maxYCoordForLine) {
                maxYCoordForLine = origin.y + boundingRect.maxY
            }
            
            let glyphOriginX: CGFloat = origin.x - boundingRect.origin.x + (glyphMargin * 0.5)
            let glyphOriginY: CGFloat = origin.y + (glyphMargin * 0.5)
            
            var glyphTransform: CGAffineTransform = __CGAffineTransformMake(1, 0, 0, -1, glyphOriginX, glyphOriginY)
            
            var path = CGPath(rect: CGRect.null, transform: nil)
            if let glyphPath = CTFontCreatePathForGlyph(ctFont, glyph, &glyphTransform) {
                path = glyphPath
            }
            else {
                print("empty glyph")
            }
            context.addPath( path )
            context.fillPath()
            
            var glyphPathBoundingRect: CGRect = path.boundingBoxOfPath
            
            // The null rect (i.e., the bounding rect of an empty path) is problematic
            // because it has its origin at (+inf, +inf); we fix that up here
            if (glyphPathBoundingRect.equalTo(CGRect.null))
            {
                glyphPathBoundingRect = CGRect.zero
            }
             
            let texCoordLeft: CGFloat = glyphPathBoundingRect.origin.x / CGFloat(width);
            let texCoordRight: CGFloat = (glyphPathBoundingRect.origin.x +  glyphPathBoundingRect.size.width) / CGFloat(width);
            let texCoordTop: CGFloat = (glyphPathBoundingRect.origin.y) / CGFloat(height);
            let texCoordBottom: CGFloat = (glyphPathBoundingRect.origin.y +  glyphPathBoundingRect.size.height) / CGFloat(height);
            
            let topLeftTexCoord = CGPoint(x: texCoordLeft, y: texCoordTop)
            let bottomRightTexCoord = CGPoint(x: texCoordRight, y: texCoordBottom)
            let descriptor = MBEGlyphDescriptor(glyphIndex: glyph,
                                                topLeftTexCoord: topLeftTexCoord,
                                                bottomRightTexCoord: bottomRightTexCoord)
            mutableGlyphs.append(descriptor)
            
            origin.x += boundingRect.width + glyphMargin
        }
        
//#if MBE_GENERATE_DEBUG_ATLAS_IMAGE
//    CGImageRef contextImage = CGBitmapContextCreateImage(context);
//    // Break here to view the generated font atlas bitmap
//    UIImage *fontImage = [UIImage imageWithCGImage:contextImage];
//    fontImage = nil;
//    CGImageRelease(contextImage);
//#endif
        
        return imageData
    }
    
    func pointSizeThatFits(_ forFont: UIFont, inAtlasRect: CGRect) -> CGFloat {
        var fittedSize: CGFloat = forFont.pointSize
        
        while( isLikelyToFit(inAtlasRect, font: forFont, atSize: fittedSize ) ) {
            fittedSize += 1
        }
        
        while( isLikelyToFit(inAtlasRect, font: forFont, atSize: fittedSize) ) {
            fittedSize -= 1
        }
            
        return fittedSize
    }
    
    func isLikelyToFit(_ inAtlasRect: CGRect, font: UIFont, atSize: CGFloat) -> Bool {
        let textureArea = inAtlasRect.size.width * inAtlasRect.size.height
        guard let trialFont: UIFont = UIFont(name: font.fontName, size: atSize)
        else { fatalError("UIFont ERROR::Couldn't create trialFont with name \(font.fontName).") }
        let cfName: CFString = font.fontName as CFString
        let trialCTFont: CTFont = CTFontCreateWithName(cfName, atSize, nil)
        let fontGlyphCount: CFIndex = CTFontGetGlyphCount(trialCTFont)
        let glyphMargin: CGFloat = estimatedLineWidth(trialFont)
        let averageGlyphSize = estimatedGlyphSize(trialFont)
        let estimatedGlyphTotalArea: CGFloat =  ( averageGlyphSize.width + glyphMargin ) * ( averageGlyphSize.height + glyphMargin ) * CGFloat(fontGlyphCount)
        
        let fits: Bool = ( estimatedGlyphTotalArea < textureArea )
        return fits
    }
    
    func createSignedDistanceField(_ imageData: [UInt8]?, width: Int, height: Int) -> CustomMatrix<Float>? {
        if (imageData == nil || width == 0 || height == 0) {
            return nil
        }
        let maxDist: Float32 = hypot(Float(width), Float(height))
        let distUnit: Float32 = 1
        let distDiag: Float32 = sqrt(2)
        
        // Initialization phase: set all distances to "infinity"; zero out nearest boundary point map
        var distanceMap = CustomMatrix<Float32>.init(rows: height,
                                                                        columns: width,
                                                                        defaultValue: maxDist) // distance to nearest boundary point map
        
        var boundaryPointMap = CustomMatrix<ushort2>.init(rows: height,
                                                        columns: width,
                                                        defaultValue: ushort2(0) ) // nearest boundary point map
        
        // Some helpers for manipulating the above arrays
        func image(_ x: Int, _ y: Int) -> Bool { return imageData?[y * width + x] ?? 0x00 > 0x7f }
        
        // Immediate interior/exterior phase: mark all points along the boundary as such
        for y in 1..<( height - 1 ) {
            for x in 1..<( width - 1 ) {
                let inside: Bool = image(x, y);
                if (image(x - 1, y) != inside ||
                    image(x + 1, y) != inside ||
                    image(x, y - 1) != inside ||
                    image(x, y + 1) != inside)
                {
                    distanceMap[x, y] = 0;
                    boundaryPointMap[x, y] = ushort2( UInt16(x), UInt16(y) );
                }
            }
        }
        //MARK: for porting: image(x,y) is imageData[x,y]   distance(x,y) is distanceMap[x,y]   and nearestpt(x,y) is boundaryPointMap[x,y]
        
        // Forward dead-reckoning pass
        for y in 1..<(height - 2) {
            for x in 1..<(width - 2) {
                if (distanceMap[(x - 1), (y - 1)] + distDiag < distanceMap[x, y])
                {
                    boundaryPointMap[x, y] = boundaryPointMap[x - 1, y - 1];
                    distanceMap[x, y] = hypot(Float(x) - Float(boundaryPointMap[x, y].x), Float(y) - Float(boundaryPointMap[x, y].y));
                }
                if (distanceMap[x, y - 1] + distUnit < distanceMap[x, y])
                {
                    boundaryPointMap[x, y] = boundaryPointMap[x, y - 1];
                    distanceMap[x, y] = hypot(Float(x) - Float(boundaryPointMap[x, y].x), Float(y) - Float(boundaryPointMap[x, y].y));
                }
                if (distanceMap[x + 1, y - 1] + distDiag < distanceMap[x, y])
                {
                    boundaryPointMap[x, y] = boundaryPointMap[x + 1, y - 1];
                    distanceMap[x, y] = hypot(Float(x) - Float(boundaryPointMap[x, y].x), Float(y) - Float(boundaryPointMap[x, y].y));
                }
                if (distanceMap[x - 1, y] + distUnit < distanceMap[x, y])
                {
                    boundaryPointMap[x, y] = boundaryPointMap[x - 1, y];
                    distanceMap[x, y] = hypot(Float(x) - Float(boundaryPointMap[x, y].x), Float(y) - Float(boundaryPointMap[x, y].y));
                }
            }
        }
        
        // Backward dead-reckoning pass
        for y in (1..<height - 2).reversed() {
            for x in (1..<width - 2).reversed() {
                if (distanceMap[x + 1, y] + distUnit < distanceMap[x, y])
                {
                    boundaryPointMap[x, y] = boundaryPointMap[x + 1, y];
                    distanceMap[x, y] = hypot(Float(x) - Float(boundaryPointMap[x, y].x), Float(y) - Float(boundaryPointMap[x, y].y));
                }
                if (distanceMap[x - 1, y + 1] + distDiag < distanceMap[x, y])
                {
                    boundaryPointMap[x, y] = boundaryPointMap[x - 1, y + 1];
                    distanceMap[x, y] = hypot(Float(x) - Float(boundaryPointMap[x, y].x), Float(y) - Float(boundaryPointMap[x, y].y));
                }
                if (distanceMap[x, y + 1] + distUnit < distanceMap[x, y])
                {
                    boundaryPointMap[x, y] = boundaryPointMap[x, y + 1];
                    distanceMap[x, y] = hypot(Float(x) - Float(boundaryPointMap[x, y].x), Float(y) - Float(boundaryPointMap[x, y].y));
                }
                if (distanceMap[x + 1, y + 1] + distDiag < distanceMap[x, y])
                {
                    boundaryPointMap[x, y] = boundaryPointMap[x + 1, y + 1];
                    distanceMap[x, y] = hypot(Float(x) - Float(boundaryPointMap[x, y].x), Float(y) - Float(boundaryPointMap[x, y].y));
                }
            }
        }
        
        // Interior distance negation pass; distances outside the figure are considered negative
        for y in 0..<height
        {
            for x in 0..<width
            {
                if (!image(x, y)) {
                    distanceMap[x, y] = -distanceMap[x, y];
                }
            }
        }
        
        return distanceMap
    }
}

struct MBEGlyphDescriptor {
    var glyphIndex: CGGlyph
    var topLeftTexCoord: CGPoint
    var bottomRightTexCoord: CGPoint
}

