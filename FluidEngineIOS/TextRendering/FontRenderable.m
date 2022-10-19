
#import "FontRenderable.h"

#define MBE_FORCE_REGENERATE_FONT_ATLAS 0

static NSString *const MBEFontName = @"HoeflerText-Regular";
static float MBEFontDisplaySize = 72;
static NSString *const MBESampleText = @"It was the best of times, it was the worst of times, "
                                        "it was the age of wisdom, it was the age of foolishness...\n\n"
                                        "Все счастливые семьи похожи друг на друга, "
                                        "каждая несчастливая семья несчастлива по-своему.";
static vector_float4 MBETextColor = { 0.1, 0.1, 0.1, 1 };
static MTLClearColor MBEClearColor = { 1, 1, 1, 1 };
static float MBEFontAtlasSize = 2048;

@interface FontRenderable ()
@property (nonatomic, strong) id<MTLDevice> device;
// Resources
@property (nonatomic, strong) MBEFontAtlas *fontAtlas;
@property (nonatomic, strong) MBETextMesh *textMesh;
@property (nonatomic, strong) id<MTLTexture> fontTexture;
@end

@implementation FontRenderable

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super init]))
    {
        _device = device;
        [self buildResources];

        _textScale = 1.0;
        _textTranslation = CGPointMake(0, 0);
    }
    return self;
}

- (void)buildResources {
    [self buildFontAtlas];
    [self buildTextMesh];
}

- (void) buildFontAtlas {
    NSURL *fontURL = [[self.documentsURL URLByAppendingPathComponent:MBEFontName] URLByAppendingPathExtension:@"sdff"];
    
#if !MBE_FORCE_REGENERATE_FONT_ATLAS
    _fontAtlas = [NSKeyedUnarchiver unarchiveObjectWithFile:fontURL.path];
#endif
    // Cache miss: if we don't have a serialized version of the font atlas, build it now
    if (!_fontAtlas)
    {
        UIFont *font = [UIFont fontWithName:MBEFontName size:32];
        _fontAtlas = [[MBEFontAtlas alloc] initWithFont:font textureSize:MBEFontAtlasSize];
        [NSKeyedArchiver archiveRootObject:_fontAtlas toFile:fontURL.path];
    }

    MTLTextureDescriptor *textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                                                           width:MBEFontAtlasSize
                                                                                          height:MBEFontAtlasSize
                                                                                       mipmapped:NO];
    MTLRegion region = MTLRegionMake2D(0, 0, MBEFontAtlasSize, MBEFontAtlasSize);
    _fontTexture = [_device newTextureWithDescriptor:textureDesc];
    [_fontTexture setLabel:@"Font Atlas"];
    [_fontTexture replaceRegion:region mipmapLevel:0 withBytes:_fontAtlas.textureData.bytes bytesPerRow:MBEFontAtlasSize];
    
}

- (NSURL *)documentsURL
{
    NSArray *candidates = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [candidates firstObject];
    return [NSURL fileURLWithPath:documentsPath isDirectory:YES];
}

- (void)buildTextMesh
{
    CGRect textRect = CGRectInset([UIScreen mainScreen].nativeBounds, 10, 10);

    _textMesh = [[MBETextMesh alloc] initWithString:MBESampleText
                                             inRect:textRect
                                      withFontAtlas:_fontAtlas
                                             atSize:MBEFontDisplaySize
                                             device:_device];
}


- (id<MTLTexture>)getTexture {
    return _fontTexture;
}

- (id<MTLBuffer>)getVertices {
    return _textMesh.vertexBuffer;
}

- (id<MTLBuffer>)getIndices {
    return _textMesh.indexBuffer;
}

@end
