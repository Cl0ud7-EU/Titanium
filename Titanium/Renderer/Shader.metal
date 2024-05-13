//
//  Shader.metal
//  Titanium
//
//  Created by Cl0ud7.
//

#include <metal_stdlib>
using namespace metal;

constant float pi = 3.14159265359;

struct VertexData {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float4 textCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 wsVertexPosition; // WorldSpace
    float4 vsVertexPosition; // ViewSpace
    float4 vsVertexNormal;
    float4 color;
    float4 textCoords;
    
};

struct EntityConstants {
    float4x4 modelMatrix;
    float4x4 modelViewMatrix;
};

struct FrameConstants {         // 132 - 36 -> 144
    float4x4 projectionMatrix;  // 64  - 16
    float4x4 viewMatrix;        // 64  - 16
    float3 cameraPos;           // 16  - 16
    uint pointLightCount;       // 4   - 4
    uint spotLightCount;
};

struct DirectionalLight {
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

struct SpotLight {
    float3 position;
    float3 direction;
    float3 directionViewS;
    float4 colorAndAngle;
    float intensity;
};

static float3 calcDiffuseReflection(float3 lightColor, float3 normal, float3 lightDirection) {
    return lightColor * max(dot(normal, lightDirection), 0.0);
}

static float3 calcSpecularReflection(float3 lightColor, float3 normal, float3 lightDirection, float3 viewDirection, float shininess) {
    float3 halfwayVector = normalize(lightDirection + viewDirection);
    float specularFactor = pow(saturate(dot(normal, halfwayVector)), shininess);
    return lightColor * specularFactor;
}

static float calcSmoothAttenuation(float lightDistance, float lightRadius)
{
    float2 attenuationConst = float2(1 / pow(lightRadius, 2), 2 / lightRadius);
    
    float result = saturate(pow(lightDistance,2) * attenuationConst.x * (lightDistance * attenuationConst.y - 3.0) + 1.0);
    
    return result;
}

static float calcInverseSquareAttenuation(float lightDistance, float radius)
{
    
    float rmin = 150.0;
    float2 attenuationConst = float2(pow(rmin,2) / (pow(radius, 2) - pow(rmin, 2)), pow(radius, 2));
                  
    float result = saturate(attenuationConst.x * (attenuationConst.y / pow(lightDistance, 2) - 1.0));
    
    return result;
}

static float calcAngleAttenuation(float3 lightDir, float3 normalizedLightVector, float cosOuter, float cosInner)
{
    float lightAngleScale = 1.0f / max(0.001f, (cosInner - cosOuter));
    float lightAngleOffset = -cosOuter * lightAngleScale;

    float cd = dot(lightDir, normalizedLightVector);
    float attenuation = saturate(cd*lightAngleScale + lightAngleOffset);

    return attenuation;
}

static float3 calcDirectionalLight(DirectionalLight light, float3 vertexViewPos, float3 vertexNormal, float3 viewDirection)
{
    float3 normal = normalize(vertexNormal);
    float3 lightDirection = normalize(-light.direction);
    
    float3 diffuseFactor = calcDiffuseReflection(light.color, normal, lightDirection);
    float3 result = light.intensity * diffuseFactor;
    return result;
}

static float3 calcPointLight(PointLight light, float3 vertexViewPos, float3 vertexNormal, float3 viewDirection, float4x4 viewMatrix)
{
    
    float3 lightPos = (viewMatrix * float4(light.position, 1.0)).xyz;
    float3 lightDirection = (lightPos - vertexViewPos);
    float lightDistance = length(lightDirection);
    
    if (lightDistance < light.radius)
    {
        float3 normal = normalize(vertexNormal);
        lightDirection = normalize(lightDirection);
        
        float attenuation = calcSmoothAttenuation(lightDistance, light.radius);
        //float attenuation = calcInverseSquareAttenuation(lightDistance, light.radius);
        
        // Diffuse
        float3 matDiffuse = (0.2, 0.3, 0.4);
        float3 diffuseFactor = calcDiffuseReflection(light.color, normal, lightDirection);
        
        // Specular
        float shininess = 3;
        float3 specularFactor = calcSpecularReflection(light.color, normal, lightDirection, viewDirection, shininess);

        float3 result = light.intensity * light.color * attenuation * diffuseFactor * specularFactor;
        return result;
    }
    
    return 0;
}

static float3 calcSpotLight(SpotLight light, float3 vertexViewPos, float3 vertexNormal, float3 viewDirection, float4x4 viewMatrix)
{
    float3 lightPos = (viewMatrix * float4(light.position, 1.0)).xyz;
    float3 lightDirection = normalize(lightPos - vertexViewPos);
    float3 lightForward = light.directionViewS;
    float lightAngle = light.colorAndAngle.w * (pi/180);
    
    float cosAngle = dot(normalize(lightForward), lightDirection);
    float cosLightAngle = cos(lightAngle);
    if (cosAngle < cosLightAngle) {
        return 0;
    }
    float3 diffuseFactor = calcDiffuseReflection(light.colorAndAngle.xyz, normalize(vertexNormal), lightDirection);
    float attenuation = calcAngleAttenuation(lightForward, lightDirection, cos(lightAngle), 1);
    float3 result = light.intensity * light.colorAndAngle.xyz * attenuation * diffuseFactor;
    return result;
}

static float3 CalcDiffuseReflection(float3 vertexNormal, float3 lightDirection, float3 diffuseColor)
{
    float3 result = float3(0,0,0);
    return result;
}

vertex VertexOut VertexMain(VertexData in [[stage_in]],
                             constant FrameConstants &frameConst [[buffer(3)]],
                             constant EntityConstants &entityConst [[buffer(4)]])
{
    VertexOut output;

    output.vsVertexPosition = entityConst.modelViewMatrix * float4(in.position, 1.0);
    output.position = frameConst.projectionMatrix * output.vsVertexPosition;
    //output.color = in.color;
    output.color = float4(1.0,1.0,1.0,1.0);
    output.textCoords = in.textCoords;
    output.vsVertexNormal = entityConst.modelViewMatrix * float4(in.normal, 0.0);

    return output;
}

fragment float4 FragmentMain(VertexOut in [[stage_in]],
                              constant FrameConstants &frameConst [[buffer(2)]],
                              constant PointLight *pointLights [[buffer(4)]],
                              constant SpotLight *spotLights [[buffer(5)]],
                              texture2d<float, access::sample> textureMap [[texture(0)]],
                              sampler textureSampler [[sampler(0)]])
{
    float3 EyeDirectionViewSpace = normalize(frameConst.cameraPos - in.vsVertexPosition.xyz);
    
    float3 lighting = 0;

//    for (uint i = 0; i < frameConst.pointLightCount; ++i) {
//        lighting += calcPointLight(pointLights[i], in.vsVertexPosition.xyz, in.vsVertexNormal.xyz, EyeDirectionViewSpace, frameConst.viewMatrix);
//    }
    //SpotLight
    for (uint i = 0; i < frameConst.spotLightCount; ++i) {
        lighting += calcSpotLight(spotLights[i], in.vsVertexPosition.xyz, in.vsVertexNormal.xyz, EyeDirectionViewSpace, frameConst.viewMatrix);
    }

//    float4 result = float4(lighting * in.color.rgb, in.color.a);
//    result += float4(lighting * textureMap.sample(textureSampler, in.textCoords).rgb, 1);
//    return result;
    //return float4(lighting * textureMap.sample(textureSampler, in.textCoords.xy).rgb, 1);
    return float4(lighting * in.color.rgb, in.color.a);
    //return float4(in.color.rgb, in.color.a);
}
