#version 330 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in ATTRIB_OUT
{
    vec3 position;
    vec2 texCoords;
} attribIn[];

out ATTRIB_VS_OUT
{
    vec2 texCoords;
    vec3 color;
} attribOut;

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


void main() {
    vec3 side1 = attribIn[1].position - attribIn[0].position;
    vec3 side2 = attribIn[2].position - attribIn[0].position;
    vec3 faceNormal = normalize(cross(side1, side2));
    vec3 transformedNormal = normalize(normalMatrix * faceNormal);

    vec3 resultColor = vec3(0.0, 0.0, 0.0);
    vec3 viewPos = attribIn[0].position;

    for (int i = 0; i < 3; i++) {
        vec3 lightDir = normalize(lights[i].position - attribIn[0].position);

        vec3 lightContribution = computeLight(i, transformedNormal, lightDir, viewPos);

        if (useSpotlight) {
            float spotIntensity = computeSpot(lights[i].spotDirection, lightDir, transformedNormal);
            lightContribution *= spotIntensity;
        }

        resultColor += lightContribution;
    }

    resultColor += lightModelAmbient * mat.ambient;

    for (int i = 0; i < 3; i++) {
        attribOut.texCoords = attribIn[i].texCoords;
        attribOut.color = resultColor;
        gl_Position = gl_in[i].gl_Position;
        EmitVertex();
    }
    EndPrimitive();
}
