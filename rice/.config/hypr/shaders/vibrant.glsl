// vibrant — realce sutil para uso diario. Vibrance (sube más los tonos poco
// saturados, respeta rojos/pieles ya saturados) + un toque de contraste.
// Perfil por defecto (se aplica al iniciar, ver autostart.lua).
precision highp float;

varying vec2 v_texcoord;
uniform sampler2D tex;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec3 c = texture2D(tex, v_texcoord).rgb;

    // vibrance: el boost es mayor cuanto menos saturado está el pixel
    float mx  = max(c.r, max(c.g, c.b));
    float mn  = min(c.r, min(c.g, c.b));
    float sat = mx - mn;
    float amt = 0.33;
    vec3  gray = vec3(dot(c, LUMA));
    c = mix(gray, c, 1.0 + amt * (1.0 - sat));

    // contraste leve alrededor del gris medio
    c = (c - 0.5) * 1.035 + 0.5;

    gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
