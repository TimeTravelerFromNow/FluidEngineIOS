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

// this is for text Rendering

vertex ColorRasterizerData text_vertex_shader(constant MBEVertex *vertices [[ buffer(0) ]],
                                          constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                          constant ModelConstants &modelConstants [[ buffer(2) ]],
                                              uint vid [[ vertex_id ]]
                                              ) {
    ColorRasterizerData rd;
    MBEVertex vIn = vertices[vid];
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstants.modelMatrix * float4(vIn.position.xyz, 1);
    rd.color = float4(0,0,0,1);
    rd.textureCoordinate = vIn.texCoords;
    
    return rd;
}

// pixel wise stage_in
fragment half4 text_fragment_shader(ColorRasterizerData rd [[ stage_in ]],
                                    texture2d<float, access::sample>texture [[texture(0)]]) {
    float4 color = float4(1,1,1,1);
    // Outline of glyph is the isocontour with value 50%
    float edgeDistance = 0.5;
    // Sample the signed-distance field to find distance from this fragment to the glyph outline
    float sampleDistance = texture.sample(sampler2d, rd.textureCoordinate).r;
    // Use local automatic gradients to find anti-aliased anisotropic edge width, cf. Gustavson 2012
    float edgeWidth = 0.75 * length(float2(dfdx(sampleDistance), dfdy(sampleDistance)));
    // Smooth the glyph edge by interpolating across the boundary in a band with the width determined above
    float insideness = smoothstep(edgeDistance - edgeWidth, edgeDistance + edgeWidth, sampleDistance);
    return half4(color.r, color.g, color.b, insideness);
}
