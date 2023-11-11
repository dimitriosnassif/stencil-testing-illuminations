#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texCoords;
layout (location = 2) in vec3 normal;

out ATTRIB_VS_OUT
{
    vec2 texCoords;
    vec3 color;
} attribOut;

uniform mat4 mvp;
uniform mat4 view;
uniform mat4 modelView;
uniform mat3 normalMatrix;

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

float computeSpot(in vec3 spotDir, in vec3 lightDir, in vec3 normal)
{
    float cosSpotAngle = dot(-lightDir, normalize(spotDir));
    if (cosSpotAngle > cos(spotOpeningAngle * 0.5))
    {
        return pow(cosSpotAngle, spotExponent);
    }
    else
    {
        return 0.0;
    }
}

vec3 computeLight(in int lightIndex, in vec3 normal, in vec3 lightDir, in vec3 obsPos)
{
    vec3 N = normalize(normal);
    vec3 L = normalize(lights[lightIndex].position - vertexPos);
    vec3 V = normalize(-vertexPos);
    vec3 R = reflect(-L, N);
    vec3 H = normalize(L + V);

    vec3 ambient = lights[lightIndex].ambient * mat.ambient;

    float diff = max(dot(N, L), 0.0);
    vec3 diffuse = lights[lightIndex].diffuse * (diff * mat.diffuse);

    float spec = 0.0;
    if (useBlinn)
    {
        spec = pow(max(dot(N, H), 0.0), mat.shininess);
    }
    else
    {
        spec = pow(max(dot(R, V), 0.0), mat.shininess);
    }
    vec3 specular = lights[lightIndex].specular * (spec * mat.specular);

    float spotEffect = useSpotlight ? computeSpot(lights[lightIndex].spotDirection, L, N) : 1.0;

    vec3 lightColor = (ambient + (diffuse + specular) * spotEffect);

    return lightColor;
}

void main()
{
    vec4 viewPos = modelView * vec4(position, 1.0);
    vec3 norm = normalize(normalMatrix * normal);

    vec3 lightAccumulation = mat.emission + lightModelAmbient * mat.ambient;

    for (int i = 0; i < 3; ++i)
    {
        lightAccumulation += computeLight(i, norm, viewPos.xyz);
    }

    attribOut.texCoords = texCoords;
    attribOut.color = lightAccumulation;

    gl_Position = mvp * vec4(position, 1.0);
}
