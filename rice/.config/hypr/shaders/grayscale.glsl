// grayscale — desaturado total con un pelín de contraste para que no quede
// lavado. Foco / detox visual.
precision highp float;

varying vec2 v_texcoord;
uniform sampler2D tex;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec3 c = texture2D(tex, v_texcoord).rgb;
    float g = dot(c, LUMA);
    g = (g - 0.5) * 1.05 + 0.5;
    gl_FragColor = vec4(vec3(clamp(g, 0.0, 1.0)), 1.0);
}
