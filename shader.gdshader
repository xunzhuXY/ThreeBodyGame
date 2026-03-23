shader_type spatial;

// 过渡掩码（来自体素工具）
uniform int u_transition_mask;

// 高度范围（需要在脚本中传入）
uniform float min_height = 50.0;
uniform float max_height = 60.5;

// 颜色分段阈值（0~1）
uniform float sea_height = 0.0;   // 低于此值为海水
uniform float grass_height = 0.5; // 海水到草地之间为草地
uniform float snow_height = 0.9;  // 草地到雪线之间为土地，高于雪线为雪

// 颜色定义
const vec3 COLOR_SEA   = vec3(0.0, 0.2, 0.6);   // 深海蓝
const vec3 COLOR_GRASS = vec3(0.3, 0.7, 0.2);   // 草绿
const vec3 COLOR_EARTH = vec3(0.6, 0.4, 0.2);   // 土黄/棕色
const vec3 COLOR_SNOW  = vec3(0.95, 0.95, 0.95); // 雪白

// 从顶点着色器传递过来的距离（世界空间到原点的长度）
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
	// 应用过渡位置调整
	vec3 final_pos = get_transvoxel_position(VERTEX, CUSTOM0);
	VERTEX = final_pos;

	// 计算世界空间距离（假设星球中心在世界原点）
	vec3 world_pos = (MODEL_MATRIX * vec4(final_pos, 1.0)).xyz;
	v_dist = length(world_pos);
}

void fragment() {
	// 归一化高度（0~1）
	float t = (v_dist - min_height) / (max_height - min_height);
	t = clamp(t, 0.0, 1.0);

	// 根据 t 分段上色
	vec3 color;
	if (t < sea_height) {
		color = COLOR_SEA;
	} else if (t < grass_height) {
		// 海水到草地之间平滑过渡
		float sub = (t - sea_height) / (grass_height - sea_height);
		color = mix(COLOR_SEA, COLOR_GRASS, sub);
	} else if (t < snow_height) {
		// 草地到雪线之间用土地色过渡
		float sub = (t - grass_height) / (snow_height - grass_height);
		color = mix(COLOR_GRASS, COLOR_EARTH, sub);
	} else {
		// 雪线以上用雪，并轻微混合一点土地
		float sub = clamp((t - snow_height) / (1.0 - snow_height), 0.0, 1.0);
		color = mix(COLOR_EARTH, COLOR_SNOW, sub);
	}

	ALBEDO = color;
	// 如果想增加一点立体感，可以适当提高粗糙度
	ROUGHNESS = 0.7;
	METALLIC = 0.0;
}