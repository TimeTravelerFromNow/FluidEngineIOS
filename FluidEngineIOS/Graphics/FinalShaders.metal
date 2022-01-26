//
//  FinalShaders.metal
//  FluidEngine
//
//  Created by sebi d on 1/22/22.
//

#include <metal_stdlib>
#include "MetalTypes.metal"
using namespace metal;

constexpr sampler sampler2d(address::clamp_to_zero,
                    filter::linear,
                    compare_func::less);

vertex FinalRasterizerData final_vertex_shader(const ColorVertex vIn [[ stage_in ]]) {
    FinalRasterizerData rd;
    
    rd.position = float4(vIn.position, 1.0);
    rd.textureCoordinate = float2(vIn.textureCoordinate);
    
    return rd;
}

fragment half4 final_fragment_shader(const FinalRasterizerData rd [[ stage_in ]],
                                     texture2d<float> baseTexture [[ texture(0) ]]) {
    
    float2 textureCoord = rd.textureCoordinate;
    float4 color = baseTexture.sample(sampler2d, textureCoord);
    return half4(color);
}

