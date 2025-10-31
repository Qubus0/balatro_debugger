shader_type canvas_item;
// based on https://godotshaders.com/shader/balatro-fire-shader/ (cc0)

uniform sampler2D noise_tex : hint_default_white, repeat_enable;
uniform vec4 bottom_color : source_color = vec4(0.0, 0.7, 1.0, 1.0);
uniform vec4 middle_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform vec4 top_color : source_color = vec4(1.0, 0.03, 0.001, 1.0);
uniform float fire_alpha : hint_range(0.0, 1.0) = 1.0;

// wether the shader scrolls on its own by time or needs to scroll via external script
uniform bool external_scroll = false;
uniform float fire_speed = .2;
uniform float fire_offset_y;

uniform float fire_aperture : hint_range(0.0, 2.5) = 0.22;
//uniform float end : hint_range(.0, 1.) = 0.6;
uniform float edge_fade : hint_range(.0, .5) = 0.35;

uniform float pixel_size : hint_range(0.001, 0.1) = 0.02;


vec4 tri_color_mix(vec4 color1, vec4 color2, vec4 color3, float pos) {
    pos = clamp(pos, 0.0, 1.0);
    if (pos < 0.5) {
        return mix(color1, color2, pos * 2.0);
    } else {
        return mix(color2, color3, (pos - 0.5) * 2.0);
    }
}

void fragment() {
    // Scale UVs to make the noise more visible
    //vec2 base_uv = UV * 1.0;
	vec2 base_uv = floor(UV / pixel_size) * pixel_size;

    // Create two layers of noise with different speeds

	vec2 shifted_uv1 = base_uv;
	vec2 shifted_uv2 = base_uv;
	if (external_scroll) {
		 shifted_uv1 += vec2(0.0, fire_offset_y);
		 shifted_uv2 += vec2(0.0, fire_offset_y) * 1.5;
	} else {
	     shifted_uv1 += TIME * vec2(.0, fire_speed);
	     shifted_uv2 += TIME * vec2(.0, fire_speed) * 1.5;
	}

    // Sample noise texture twice
    float fire_noise1 = texture(noise_tex, fract(shifted_uv1)).r;
    float fire_noise2 = texture(noise_tex, fract(shifted_uv2)).r;

    // Combine the noise samples
    float combined_noise = (fire_noise1 + fire_noise2) * 0.5;

    // Calculate fire shape
    //float noise = UV.y * (((UV.y + fire_aperture) * combined_noise - fire_aperture) * 75.0);

	// Horizontal attenuation for noise (stronger in center, weaker at sides)
	float center_dist = abs(UV.x - 0.5);
	float edge_attenuation = smoothstep(0.55, edge_fade, center_dist);
	float noise = UV.y * (((UV.y + fire_aperture) * combined_noise * edge_attenuation - fire_aperture) * 75.0);
	if (fire_aperture >= 2.) {
		noise = 0.;
	}

    // Add movement
    //noise += sin(UV.y * 10.0 + TIME * 2.0) * 0.1;

    // Calculate gradient position and mix three colors
    float gradient_pos = clamp(noise * 0.08, 0.3, 2.0);
	//vec4 smoth_mid_color = smoothstep(top_color, middle_color, vec4(1));
    vec4 fire_color = tri_color_mix(bottom_color, middle_color, top_color, gradient_pos);

	// Determine how far we are above or below the "end" threshold
	//float fade = smoothstep(end - 0.1, end + 0.1, UV.y); // Adjust 0.05 for gradient softness

	// If we're below the end threshold, show only the bottom_color
	//vec4 final_color = mix(fire_color, COLOR, fade);

    // Set final color and alpha
	COLOR = fire_color;
    COLOR.a = clamp(noise, 0.0, 1.0) * fire_alpha;

    // If below the "end" threshold, output a flat color
    //if (UV.y > end) {
        ////COLOR.a = fire_alpha;
        //COLOR.a = 0.;
    //}
}