shader_type canvas_item;

// Fondo "synthwave" animado al estilo Hotline Miami

uniform vec4 cielo_arriba : source_color = vec4(0.08, 0.01, 0.16, 1.0);
uniform vec4 cielo_abajo : source_color = vec4(0.95, 0.18, 0.5, 1.0);
uniform vec4 color_grilla : source_color = vec4(0.25, 0.97, 1.0, 1.0);
uniform float horizonte = 0.62;
uniform float aspecto = 1.7778;

void fragment() {
	vec2 uv = UV;
	vec3 col;
	if (uv.y < horizonte) {
		float t = uv.y / horizonte;
		col = mix(cielo_arriba.rgb, cielo_abajo.rgb, pow(t, 1.8));
		// sol con franjas
		vec2 centro = vec2(0.5, horizonte - 0.03);
		float r = length((uv - centro) * vec2(aspecto, 1.0));
		float franjas = step(0.45, fract(uv.y * 38.0 - TIME * 0.6));
		float corte = uv.y > centro.y - 0.13 ? franjas : 1.0;
		vec3 sol = mix(vec3(1.0, 0.86, 0.3), vec3(1.0, 0.22, 0.55), smoothstep(centro.y - 0.26, centro.y, uv.y));
		col = mix(col, sol, (1.0 - smoothstep(0.255, 0.265, r)) * corte);
		col += vec3(1.0, 0.3, 0.6) * 0.25 * (1.0 - smoothstep(0.0, 0.5, r));
	} else {
		// piso: grilla en perspectiva que avanza hacia la cámara
		float p = uv.y - horizonte;
		float profundidad = 1.0 / max(p, 0.002);
		float gz = profundidad * 0.12 + TIME * 0.7;
		float gx = (uv.x - 0.5) * profundidad * 0.5;
		float dz = min(fract(gz), 1.0 - fract(gz));
		float dx = min(fract(gx), 1.0 - fract(gx));
		float lz = 1.0 - smoothstep(0.0, fwidth(gz) * 1.5, dz);
		float lx = 1.0 - smoothstep(0.0, fwidth(gx) * 1.5, dx);
		float linea = max(lz, lx) * smoothstep(0.0, 0.12, p);
		col = mix(vec3(0.06, 0.0, 0.11), color_grilla.rgb, linea);
		col += vec3(1.0, 0.2, 0.6) * (1.0 - smoothstep(0.0, 0.06, p)) * 0.8;
	}
	COLOR = vec4(col, 1.0);
}
