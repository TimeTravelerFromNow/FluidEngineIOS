//
//  MetalTypes.metal
//  FluidEngine
//
//  Created by sebi d on 1/9/22.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
    float3 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
    float2 textureCoordinate [[ attribute(2) ]];
    float3 normal [[ attribute(3) ]];
    float3 tangent [[ attribute(4) ]];
    float3 bitangent [[ attribute(5) ]];
};


struct ColorVertex {
    float3 position [[ attribute(0)]];
    float4 color [[ attribute(1) ]];
    float2 textureCoordinate [[ attribute(2) ]];
};

struct SceneConstants {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

struct ModelConstants {
    float4x4 modelMatrix;
};

struct RasterizerData {
    float4 position [[ position ]];
    float2 textureCoordinate;
    uint instanceId;
};

struct FluidRasterizerData {
    float4 position [[ position ]];
    float2 textureCoordinate;
    uint instanceId;
    float pointSize [[  point_size  ]];
    float4 color;
};


struct ColorRasterizerData {
    float4 position [[ position ]];
    float4 color;
    float2 textureCoordinate;
    uint instanceId;
};

struct GridConstants {
    float2 cellCount;
    float lineWidth;
};

struct Material {
    float4 color;
    bool useMaterialColor;
    bool useTexture;
};

struct DrawRasterizerData {
    float4 position [[  position    ]];
    float4 color;
    float pointSize [[  point_size  ]];
};

struct FluidConstants {
    float ptmRatio;
    float pointSize;
};

struct FinalRasterizerData {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

struct MBEVertex {
    packed_float4 position;
    packed_float2 texCoords;
};
