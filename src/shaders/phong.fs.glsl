#version 330 core

in ATTRIB_VS_OUT
{
    vec2 texCoords;
    vec3 normal;
    vec3 lightDir[3];
    vec3 spotDir[3];
    vec3 obsPos;
} attribIn;

struct Material
{
    vec3 emission;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct UniversalLight
{
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 position;
    vec3 spotDirection;
};

layout (std140) uniform LightingBlock
{
    Material mat;
    UniversalLight lights[3];
    vec3 lightModelAmbient;
    bool useBlinn;
    bool useSpotlight;
    bool useDirect3D;
    float spotExponent;
    float spotOpeningAngle;
};

uniform sampler2D textureSampler;

out vec4 FragColor;

float computeSpot(in vec3 spotDir, in vec3 lightDir, in vec3 normal)
{
    float intensity = 0.0;
    float cosGamma = dot(lightDir, spotDir);
    float cosDelta = cos(radians(spotOpeningAngle));
    if (useDirect3D) {
        float cosThetaInner = cosDelta;
        float cosThetaOuter = pow(cosDelta, 1.01 + spotExponent / 2);
        intensity = smoothstep(cosThetaOuter, cosThetaInner, cosGamma);
    } else if (dot(spotDir, normal) >= 0.0) {
        if (cosGamma > cosDelta) {
            intensity = pow(cosGamma, spotExponent);
        }
    }
    return intensity;
}

vec3 computeLight(in int lightIndex, in vec3 normal, in vec3 lightDir, in vec3 obsPos)
{
    vec3 ambient = lights[lightIndex].ambient * mat.ambient;
    
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = lights[lightIndex].diffuse * (diff * mat.diffuse);
    
    vec3 viewDir = normalize(obsPos);
    float spec = 0.0;
    if (useBlinn) {
        vec3 halfDir = normalize(lightDir + viewDir);
        spec = pow(max(dot(normal, halfDir), 0.0), mat.shininess);
    } else {
        vec3 reflectDir = reflect(-lightDir, normal);
        spec = pow(max(dot(viewDir, reflectDir), 0.0), mat.shininess);
    }
    vec3 specular = lights[lightIndex].specular * (spec * mat.specular);

    return ambient + diffuse + specular;
}

void main() 
{
    vec3 normal = normalize(attribIn.normal);
    vec3 result = mat.emission;

    for (int i = 0; i < 3; i++) {
        vec3 lightContribution = computeLight(i, normal, attribIn.lightDir[i], attribIn.obsPos);

        if (useSpotlight) {
            float spotIntensity = computeSpot(attribIn.spotDir[i], attribIn.lightDir[i], normal);
            lightContribution *= spotIntensity;
        }

        result += lightContribution;
    }

    result += lightModelAmbient * mat.ambient;

    FragColor = vec4(result, 1.0) * texture(textureSampler, attribIn.texCoords);
}
