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
    float3 normal [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 worldPosition;
    float4 viewPosition;
    float4 color;
    float4 viewNormal;
};

struct EntityConstants {
    float4x4 modelMatrix;
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
    float3 normal = (0.3, 0.0, 0.2);
    float3 lightDirection = normalize(-light.color);
    float diffuseFactor = max(dot(normal, lightDirection), 0.0);
    float3 result = light.color * light.intensity * diffuseFactor;
    return result;
}

static float3 calcPointLight(uint LightCount, PointLight light, float3 vertexWorldPos, float3 vertexNormal, float3 viewPos)
{
    float3 normal = normalize(vertexNormal);
    float3 lightDirection = -(light.position - vertexWorldPos);
    float3 lightDistance = length(lightDirection);
    lightDirection = normalize(lightDirection);
    float attenuation = calcSmoothAttenuation(lightDistance, light.radius);
    
    // Calc Diffuse Factor
    lightDistance = normalize(lightDistance);
    float diffuseFactor = max(dot(normal, lightDirection), 0.0);
    diffuseFactor *= attenuation;
    float3 result = light.color * light.intensity * diffuseFactor;
    
    // Specular
    float specularStrenght = 1;
    float3 reflectionDirection = 2 * (normal * lightDirection) * normal - lightDirection;
    float specularFactor = pow(saturate(dot(-viewPos, reflectionDirection)), specularStrenght);
    result += light.color * light.intensity * specularFactor * attenuation;
    
    return result;
}

vertex VertexOut vertex_main(VertexData in [[stage_in]],
                             constant FrameConstants &frame [[buffer(3)]],
                             constant EntityConstants &entityConst [[buffer(4)]])
{
    VertexOut output;
    output.worldPosition = entityConst.modelViewMatrix * float4(in.position, 1.0);
    output.position = frame.projectionMatrix * (entityConst.modelViewMatrix * float4(in.position, 1.0));
    output.viewPosition = entityConst.modelViewMatrix * float4(in.position, 1.0);
    output.color = in.color;
    output.viewNormal = entityConst.modelViewMatrix * float4(in.normal, 0.0);
    return output;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant FrameConstants &frame [[buffer(2)]],
                              constant PointLight *lights [[buffer(4)]],
                              constant EntityConstants &entityConst [[buffer(3)]])
{
    float3 viewPos = normalize(float3(0) - in.viewPosition.xyz);
    
    //float3 litColor = calcDirectionalLight(lights[0]);
    float3 lighting = 0;

    for (uint i = 0; i < frame.lightCount; ++i) {
        lighting += calcPointLight(1, lights[i], in.worldPosition.xyz, in.viewNormal.xyz, viewPos);
    }
    
    return float4(lighting * in.color.rgb, 1);
}
