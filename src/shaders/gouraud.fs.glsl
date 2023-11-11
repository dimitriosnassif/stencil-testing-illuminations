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
    vec4 textureColor = texture(textureSampler, attribIn.texCoords);
    vec3 finalColor = attribIn.color * textureColor.rgb;

    FragColor = vec4(finalColor, 1.0);
}
