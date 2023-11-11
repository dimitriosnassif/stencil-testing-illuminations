#version 330 core

layout (location = 0) in vec3 position;
layout (location = 2) in vec3 normal;

uniform mat4 mvp;
uniform float haloFactor;

void main()
{
    vec3 newPos = position + (normalize(normal) * haloFactor);
    gl_Position = mvp * vec4(newPos, 1.0);
}
