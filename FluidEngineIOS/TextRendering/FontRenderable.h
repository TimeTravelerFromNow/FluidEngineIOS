#import <Foundation/Foundation.h>

#import "MBEMathUtilities.h"
#import "MBETypes.h"
#import "MBEFontAtlas.h"
#import "MBETextMesh.h"

@import Metal;
@import MetalKit;
@import ModelIO;
@import QuartzCore.CAMetalLayer;

#ifndef TextObject_Definitions
#define TextObject_Definitions

#endif
@interface FontRenderable : NSObject

@property (nonatomic, assign) CGPoint textTranslation;
@property (nonatomic, assign) CGFloat textScale;

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end
