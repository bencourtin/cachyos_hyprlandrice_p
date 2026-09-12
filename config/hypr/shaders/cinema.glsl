// cinema — más pegada para pelis / juegos: saturación global, contraste alto,
// leve calidez y una bajada mínima de brillo.
precision highp float;

varying vec2 v_texcoord;
uniform sampler2D tex;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec3 c = texture2D(tex, v_texcoord).rgb;

    // saturación global
    vec3 gray = vec3(dot(c, LUMA));
    c = mix(gray, c, 1.18);

    // contraste
    c = (c - 0.5) * 1.13 + 0.5;

    // calidez + brillo
    c *= vec3(1.03, 1.00, 0.96);
    c *= 0.985;

    gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
