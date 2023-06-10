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
    float4 viewPosition;
    float4 color;
};

struct EntityConstants {
    float4x4 modelViewMatrix;
};

struct FrameConstants {
    float4x4 projectionMatrix;
    uint lightCount;
};

struct Light {
    float3 direction;
    float3 color;
    float intensity;
};

struct PointLight {
    float3 position;
    float3 color;
    float intensity;
    float radius;
};

static float calcSmoothAttenuation(float3 lightDirection, float radius)
{
    float squareRadius = dot(lightDirection, lightDirection);
    float2 attenuationConst = float2(radius*radius, radius);
    
    if (squareRadius > attenuationConst.x) {
        return 0;
    }
    float result = clamp((squareRadius / attenuationConst.x) * ((2 * (sqrt(squareRadius)) / attenuationConst.y) - 3.0) + 1.0, 0.0, 1.0);
    return result;
}

static float3 calcDirectionalLight(Light light)
{
    float3 normal = (1.0, 1.0, 1.0);
    float3 lightDirection = normalize(-light.direction);
    float diffuseFactor = max(dot(normal, lightDirection), 0.0);
    float3 result = light.color * light.intensity * diffuseFactor;
    return result;
}

static float3 calcPointLight(uint LightCount, PointLight light, float3 fragmentPos, float4x4 modelViewMatrix)
{
    float3 normal = (1.0, 1.0, 1.0);
    float4 ligthPos = modelViewMatrix * float4(light.position, 1.0);
    float3 lightDistance = length((light.position - fragmentPos));
    float attenuation = calcSmoothAttenuation(lightDistance, light.radius);
    lightDistance = normalize(lightDistance);
    float diffuseFactor = max(dot(normal, lightDistance), 0.0);
    
    float3 result = light.color * light.intensity * diffuseFactor * attenuation;
    return result;
}

vertex VertexOut vertex_main(VertexData in [[stage_in]],
                             constant FrameConstants &frame [[buffer(2)]],
                             constant EntityConstants &entityConst [[buffer(3)]])
{
    VertexOut output;
    output.viewPosition = entityConst.modelViewMatrix * float4(in.position, 1.0);
    output.position = frame.projectionMatrix * output.viewPosition;
    output.color = in.color;
    return output;
}

fragment float4 fragment_main(VertexOut vertexOut [[stage_in]],
                              constant FrameConstants &frame [[buffer(2)]],
                              constant PointLight *lights [[buffer(4)]],
                              constant EntityConstants &entityConst [[buffer(3)]])
{

    //float3 litColor = calcDirectionalLight(lights[0]);
    float3 lighting = 0;
    for (uint i = 0; i < frame.lightCount; ++i) {
        lighting += calcPointLight(1, lights[i], vertexOut.viewPosition.xyz, entityConst.modelViewMatrix);
    }
    
    return float4(lighting * vertexOut.color.rgb, 1);
}
