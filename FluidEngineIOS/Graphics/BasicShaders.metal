//
//  BasicShaders.metal
//  FluidEngine
//
//  Created by sebi d on 1/10/22.
//

#include <metal_stdlib>
#include "MetalTypes.metal"
using namespace metal;


// this is for basic obj rendering, like a quad with a texture, (non instanced).
//fragment float4 basic_fragment_shader


vertex ColorRasterizerData basic_color_vertex_shader(const ColorVertex vIn [[ stage_in ]],
                                          constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                          constant ModelConstants &modelConstants [[ buffer(2) ]]) {
    ColorRasterizerData rd;
    
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstants.modelMatrix * float4(vIn.position, 1);
    rd.color = vIn.color;
    rd.textureCoordinate = vIn.textureCoordinate;
    
    return rd;
}

// pixel wise stage_in
// THese are for beautiful custom time dependent shading of the sky background
fragment half4 color_fragment_shader(ColorRasterizerData rd [[ stage_in ]],
                                     constant Material &material [[ buffer(1) ]]) {
    float4 color = material.useMaterialColor ? material.color : rd.color;
    return half4(color.r, color.g, color.b, color.a);
}

fragment float4 bg_color_fragment(const ColorRasterizerData rd [[ stage_in ]],
                                               constant float &totalGameTime [[ buffer(0) ]]) {
    float4 color = abs(float4(rd.color.r * (1 - rd.textureCoordinate.y *abs(sin(totalGameTime*0.1))),
                              rd.color.g * (1 - rd.textureCoordinate.y *abs(sin(totalGameTime*0.1))),
                              rd.color.b * (1 - rd.textureCoordinate.y *abs(sin(totalGameTime*0.1))), 1.0));

    return color;
}

