shader_type spatial;

uniform int u_transition_mask;
uniform float min_height = 50.0;
uniform float max_height = 55.0;   // 根据实际最大高度调整

uniform float sea_height   = 0.0;   // 海水占比 (0~1)
uniform float grass_height = 0.1;   // 草地占比
uniform float snow_height  = 0.99;   // 雪线占比

const vec3 COLOR_SEA   = vec3(0.0, 0.2, 0.6);
const vec3 COLOR_GRASS = vec3(0.3, 0.7, 0.2);
const vec3 COLOR_EARTH = vec3(0.6, 0.4, 0.2);
const vec3 COLOR_SNOW  = vec3(0.95, 0.95, 0.95);

varying float v_dist;

// -------------------- 过渡相关函数（原样保留）--------------------
float get_transvoxel_secondary_factor(int idata) {
	int transition_mask = u_transition_mask & 0xff;
	int cell_border_mask = idata & 63;
	int vertex_border_mask = (idata >> 8) & 63;
	int m = transition_mask & cell_border_mask;
	float t = float(m != 0);
	t *= float((vertex_border_mask & ~transition_mask) == 0);
	return t;
}

vec3 get_transvoxel_position(vec3 vertex_pos, vec4 fdata) {
	int idata = floatBitsToInt(fdata.a);
	float secondary_factor = get_transvoxel_secondary_factor(idata);
	vec3 secondary_position = fdata.xyz;
	vec3 pos = mix(vertex_pos, secondary_position, secondary_factor);
	int itransition = (idata >> 16) & 0xff;
	float transition_cull = float(itransition == 0 || (itransition & u_transition_mask) != 0);
	pos *= transition_cull;
	return pos;
}
// -------------------------------------------------------------

void vertex() {
    vec3 final_pos = get_transvoxel_position(VERTEX, CUSTOM0);
    VERTEX = final_pos;
    vec3 world_pos = (MODEL_MATRIX * vec4(final_pos, 1.0)).xyz;
    v_dist = length(world_pos);
	//v_dist = length(final_pos);
}

void fragment() {
    float t = (v_dist - min_height) / (max_height - min_height);
    t = clamp(t, 0.0, 1.0);

    vec3 color;
    if (t <= sea_height) {
        color = COLOR_SEA;
    } else if (t < grass_height) {
        // 海水到草地平滑过渡
        float sub = (t - sea_height) / (grass_height - sea_height);
        color = COLOR_GRASS;
    } else if (t < snow_height) {
        // 草地到土地平滑过渡
        float sub = (t - grass_height) / (snow_height - grass_height);
        color = COLOR_EARTH;
    } else {
        // 雪线以上到雪
        float sub = clamp((t - snow_height) / (1.0 - snow_height), 0.0, 1.0);
        color = COLOR_SNOW;
    }

    ALBEDO = color;
}