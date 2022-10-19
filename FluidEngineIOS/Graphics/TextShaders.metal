#include <metal_stdlib>
#include "MetalTypes.metal"
using namespace metal;

// this is for text Rendering
vertex TransformedVertex text_vertex_shader(constant MBEVertex *vertices [[ buffer(0) ]],
                                          constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                          constant ModelConstants &modelConstants [[ buffer(2) ]],
                                              uint vid [[ vertex_id ]]
                                              ) {
    TransformedVertex rd;
    MBEVertex vIn = vertices[vid];
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstants.modelMatrix * float4(vIn.position.xyz, 1);
    rd.texCoords = vIn.texCoords;
    
    return rd;
}

// pixel wise stage_in
fragment half4 text_fragment_shader(TransformedVertex rd [[ stage_in ]],
                                    texture2d<float, access::sample>texture [[texture(0)]]) {
    float4 color = float4(0,0,0,1);
    // Outline of glyph is the isocontour with value 50%
    float edgeDistance = 0.5;
    // Sample the signed-distance field to find distance from this fragment to the glyph outline
    float sampleDistance = texture.sample(sampler2d, rd.texCoords).r;
    // Use local automatic gradients to find anti-aliased anisotropic edge width, cf. Gustavson 2012
    float edgeWidth = 0.75 * length(float2(dfdx(sampleDistance), dfdy(sampleDistance)));
    // Smooth the glyph edge by interpolating across the boundary in a band with the width determined above
    float insideness = smoothstep(edgeDistance - edgeWidth, edgeDistance + edgeWidth, sampleDistance);
    if (insideness < 0.1) {
        discard_fragment();
    }
    return half4(color.r, color.g, color.b, insideness);
}

