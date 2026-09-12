// reading — modo papel: cálido, poco contraste y algo desaturado para lecturas
// largas. No reemplaza el filtro de luz azul (ese sigue en DarkLight.sh /
// hyprsunset); suma en comodidad y se puede apilar con él.
precision highp float;

varying vec2 v_texcoord;
uniform sampler2D tex;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec3 c = texture2D(tex, v_texcoord).rgb;

    // desaturar un poco
    vec3 gray = vec3(dot(c, LUMA));
    c = mix(gray, c, 0.82);

    // aplanar contraste
    c = (c - 0.5) * 0.92 + 0.5;

    // tinte cálido tipo sepia claro
    c *= vec3(1.09, 0.99, 0.86);

    gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
