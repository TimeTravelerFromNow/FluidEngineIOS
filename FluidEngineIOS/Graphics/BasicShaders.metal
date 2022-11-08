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

vertex ColorRasterizerData custom_box2d_vertex_shader(const ColorVertex vIn [[ stage_in ]],
                                                      constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                                      constant ModelConstants &fluidModelConstants [[ buffer(2) ]],
                                                      const device FluidConstants &fluidConstants [[ buffer(3) ]],
                                                      unsigned int vid [[ vertex_id ]] ) {
               ColorRasterizerData rd;
    float3 position = vIn.position;
               rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * fluidModelConstants.modelMatrix * float4(position.x * fluidConstants.ptmRatio, position.y * fluidConstants.ptmRatio, 0, 1);
        rd.textureCoordinate = vIn.textureCoordinate;
               return rd;
};

fragment half4 custom_box2d_fragment_shader(const ColorRasterizerData rd [[ stage_in ]],
                                            texture2d<float> baseTexture [[ texture(0) ]],
                                            const float3 selectColor) {
    float2 textureCoord = rd.textureCoordinate;
    float4 color = baseTexture.sample(sampler2d, textureCoord);
    if( color.a < 0.1) {
        discard_fragment();
    }
    return half4(color);
}

// argument is one texture instead of several.
fragment half4 select_custom_box2d_fragment_shader(ColorRasterizerData rd [[ stage_in ]],
                                texture2d<float> baseTexture [[ texture(0) ]],
                                     sampler sampler2d [[ sampler(0) ]],
                                      constant float &totalGameTime [[ buffer(0) ]],
                                      constant float3 &selectColor  [[ buffer(2) ]]
                                      ) {
    float2 texCoord = rd.textureCoordinate;
    float4 color;
    color = baseTexture.sample(sampler2d, texCoord);
    color.r = clamp(color.r + selectColor.r * abs(0.5 * sin(texCoord.x * 10 + totalGameTime * 2)), 0.0, 1.0);
    color.g = clamp(color.g + selectColor.g * abs(0.5 * sin(texCoord.x * 10 + totalGameTime * 2)), 0.0, 1.0);
    color.b = clamp(color.b + selectColor.b * abs(0.5 * sin(texCoord.x * 10 + totalGameTime * 2)), 0.0, 1.0);
    
    if(color.a <= 0.1) {
        discard_fragment();
    }
    return half4(color);
}
