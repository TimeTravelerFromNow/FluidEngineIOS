#include <metal_stdlib>
#include "MetalTypes.metal"

using namespace metal;


vertex LinesRasterizerData lines_vertex( const device packed_float2* line_vertices [[ buffer(0) ]],
                                   constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                   constant ModelConstants &modelConstants [[ buffer(2) ]],
                                   const device FluidConstants &fluidConstants [[ buffer(3) ]],
                                   unsigned int vid [[ vertex_id ]] ) {
    LinesRasterizerData rd;
    float2 position = line_vertices[vid];
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstants.modelMatrix * float4(position.x * fluidConstants.ptmRatio, position.y * fluidConstants.ptmRatio, 0, 1);
    return rd;
}

fragment half4 lines_fragment( RasterizerData rd [[ stage_in ]] ) {
    return half4(0.1,0.3,0.3,1.0);
}

vertex DrawRasterizerData draw_vertex(const device packed_float2* fluid_vertices [[buffer(0)]],
                                           constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                           constant ModelConstants &modelConstants [[ buffer(2) ]],
                                           const device FluidConstants &fluidConstants [[ buffer(3) ]],
                                           const device packed_float3* points_colors [[ buffer(4) ]],
                                           unsigned int vid [[ vertex_id ]] ) {
    DrawRasterizerData rd;
    float2 position = fluid_vertices[vid];
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstants.modelMatrix * float4(position.x * fluidConstants.ptmRatio, position.y * fluidConstants.ptmRatio, 0, 1);
    rd.pointSize = fluidConstants.pointSize;
    rd.color = float4(points_colors[vid].x,points_colors[vid].y,points_colors[vid].z,1.0);
    return rd;
};

vertex FluidRasterizerData color_fluid_vertex( VertexIn vIn [[ stage_in ]],
                                              const device packed_float2* fluid_vertices [[buffer(0)]],
                                           constant SceneConstants &sceneConstants [[ buffer(1) ]],
                                           constant ModelConstants &modelConstants [[ buffer(2) ]],
                                           const device FluidConstants &fluidConstants [[ buffer(3) ]],
                                           const device unsigned char* color_buffer [[ buffer(4) ]],
                                           unsigned int vid [[ vertex_id ]] ) {
    FluidRasterizerData rd;
    float2 position = fluid_vertices[vid];    
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstants.modelMatrix * float4(position.x * fluidConstants.ptmRatio, position.y * fluidConstants.ptmRatio, 0, 1);
    rd.pointSize = fluidConstants.pointSize;
    int cIndex = vid * 4;
    rd.color = float4( float(color_buffer[cIndex]) / 255,
                      float(color_buffer[cIndex + 1]) / 255,
                      float(color_buffer[cIndex + 2]) / 255,
                      float(color_buffer[cIndex + 3]) / 255) ;
    return rd;
};

fragment half4 draw_fragment(DrawRasterizerData rd [[ stage_in ]]) {
    return half4(rd.color);
};

fragment half4 color_fluid_fragment(FluidRasterizerData rd [[ stage_in ]]) {
    return half4(rd.color);
};

fragment half4 fluid_fragment(FluidRasterizerData rd [[ stage_in ]],
                              constant float4 &waterColor [[ buffer(0) ]]) {
    return half4(waterColor);
};

