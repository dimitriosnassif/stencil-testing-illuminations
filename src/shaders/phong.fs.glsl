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
    float theta = dot(-lightDir, spotDir);
    if (theta > cos(spotOpeningAngle)) {
        if (useDirect3D) {
            float phi = cos(spotOpeningAngle) - 0.01;
            float intensity = clamp((theta - phi) / (1.0 - phi), 0.0, 1.0);
            return intensity;
        } else {
            float epsilon = cos(spotOpeningAngle) - 0.01;
            float intensity = clamp((theta - epsilon) / (cos(spotOpeningAngle) - epsilon), 0.0, 1.0);
            return pow(intensity, spotExponent);
        }
    }
    return 0.0;
}

vec3 computeLight(in int lightIndex, in vec3 normal, in vec3 lightDir, in vec3 obsPos)
{
    vec3 ambient = lights[lightIndex].ambient * mat.ambient;
    
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = lights[lightIndex].diffuse * (diff * mat.diffuse);
    
    vec3 viewDir = normalize(obsPos);
    vec3 halfDir = normalize(lightDir + viewDir);
    float spec = 0.0;
    if (useBlinn) {
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
        result += computeLight(i, normal, attribIn.lightDir[i], attribIn.obsPos);
        if (useSpotlight) {
            result *= computeSpot(attribIn.spotDir[i], attribIn.lightDir[i], normal);
        }
    }
    
    result += lightModelAmbient * mat.ambient;
    
    FragColor = vec4(result, 1.0) * texture(textureSampler, attribIn.texCoords);
}
