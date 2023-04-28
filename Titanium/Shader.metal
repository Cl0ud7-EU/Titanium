//
//  Shader.metal
//  Titanium
//
//  Created by Cl0ud7.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 vertex_main( device float3 const* positions [[buffer(0)]], uint vertexID [[vertex_id]])
{
    float3 position = positions[vertexID];
    return float4(position, 1.0);
}

fragment float4 fragment_main(float4 position [[stage_in]]) {
    return float4 (0.8, 0.5, 0.0, 1.0);
}
