//
//  Shader.metal
//  Titanium
//
//  Created by Cl0ud7.
//

#include <metal_stdlib>
using namespace metal;

struct VertexData {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(VertexData vertexData [[stage_in]])
{
    VertexOut output;
    output.position = float4(vertexData.position, 1.0);
    output.color = vertexData.color;
    return output;
}

fragment float4 fragment_main(VertexOut vertexOut [[stage_in]]) {
//    return float4 (0.8, 0.5, 0.0, 1.0);
    return vertexOut.color;
}
