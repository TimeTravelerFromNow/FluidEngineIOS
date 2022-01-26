//
//  InstancedShaders.metal
//  FluidEngine
//
//  Created by sebi d on 1/9/22.
//

#include <metal_stdlib>
#include "MetalTypes.metal"
using namespace metal;

vertex RasterizerData instanced_vertex_shader(VertexIn vIn [[ stage_in ]],
                                    constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                    constant ModelConstants *modelConstants [[ buffer(2) ]],
                                    uint instanceId [[ instance_id ]]) {
    RasterizerData rd;
    rd.instanceId = instanceId;
    ModelConstants modelConstant = modelConstants[ instanceId ];

    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstant.modelMatrix * float4(vIn.position, 1);
    rd.textureCoordinate = vIn.textureCoordinate;
    return rd;
}

constexpr sampler sampler2d(address::clamp_to_zero,
                            filter::linear,
                            compare_func::less);

// argument is one texture instead of several.
fragment half4 basic_fragment_shader(RasterizerData rd [[ stage_in ]],
                                texture2d<float> texture [[ texture(0) ]],
                                     sampler sampler2d [[ sampler(0) ]],
                               constant Material &material [[ buffer(1) ]]
                                         ) {
    float2 texCoord = rd.textureCoordinate;
    float4 color;
    if(material.useTexture){
           color = texture.sample(sampler2d, texCoord);
       }else if(material.useMaterialColor) {
           color = material.color;
       }else{
           color = float4(0.5,0.0,0.0,1.0);
       }
    if(color.a <= 0.1) {
        discard_fragment();
    }
    return half4(color);
}
// argument is one texture instead of several.
fragment half4 select_fragment_shader(RasterizerData rd [[ stage_in ]],
                                texture2d<float> texture [[ texture(0) ]],
                                     sampler sampler2d [[ sampler(0) ]],
                                      constant float &totalGameTime [[ buffer(0) ]],
                                      constant Material &material [[ buffer(1) ]],
                                      constant float3 &selectColor  [[ buffer(2) ]]
                                      ) {
    float2 texCoord = rd.textureCoordinate;
    float4 color;
    if(material.useTexture){
           color = texture.sample(sampler2d, texCoord);
        color.r = clamp(color.r + selectColor.r * abs(0.5 * sin(texCoord.x * 10 + totalGameTime * 2)), 0.0, 1.0);
        color.g = clamp(color.g + selectColor.g * abs(0.5 * sin(texCoord.x * 10 + totalGameTime * 2)), 0.0, 1.0);
        color.b = clamp(color.b + selectColor.b * abs(0.5 * sin(texCoord.x * 10 + totalGameTime * 2)), 0.0, 1.0);
       }else if(material.useMaterialColor) {
           color = material.color;
       }else{
           color = float4(0.5,0.0,0.0,1.0);
       }
    if(color.a <= 0.1) {
        discard_fragment();
    }
    return half4(color);
}

