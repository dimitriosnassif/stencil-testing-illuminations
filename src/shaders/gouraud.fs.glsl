#version 330 core

in ATTRIB_VS_OUT
{
    vec2 texCoords;
    vec3 color;
} attribIn;

uniform sampler2D textureSampler;

out vec4 FragColor;

void main()
{
    vec4 texColor = texture(textureSampler, attribIn.texCoords);
    FragColor = vec4(attribIn.color, 1.0) * texColor;
}
