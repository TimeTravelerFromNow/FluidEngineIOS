//
//  MBEMesh.h
//  TextRendering
//
//  Created by Warren Moore on 11/10/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//
// modified by Sebastian Detering to update the text meshes. on 10/19/2022

@import UIKit;
@import Metal;
#include "MBEFontAtlas.h"

@interface MBEMesh : NSObject

@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic, readonly) MBEFontAtlas * fontAtlasRef;
@property (nonatomic, readonly) CGFloat size;
@property (nonatomic, readonly) id<MTLDevice> device;

@end
