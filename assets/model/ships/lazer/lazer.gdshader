// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode unshaded,blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float beam_width : hint_range(0.00, 10.0) = 0.5;
uniform float beam_width_coeff : hint_range(0.0,10.0) = 1.0;


uniform vec4 albedo1 : source_color;
uniform sampler2D texture_albedo1 : source_color, filter_linear_mipmap, repeat_enable;

uniform float alpha1 : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D texture_alpha1 : filter_linear_mipmap, repeat_enable;
uniform bool use_alpha1_texture = false;
uniform bool invert_alpha1_texture = false;

uniform bool use_albedo2_blend = false;

group_uniforms Albedo2;
uniform vec4 albedo2 : source_color;
uniform sampler2D texture_albedo2 : source_color, filter_linear_mipmap, repeat_enable;

uniform float alpha2 : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D texture_alpha2 : filter_linear_mipmap, repeat_enable;
uniform bool use_alpha2_texture = false;
uniform bool invert_alpha2_texture = false;
group_uniforms;




void vertex() {


    VERTEX.x *= beam_width * beam_width_coeff;  // X轴按宽度缩放
    VERTEX.z *= -beam_width * beam_width_coeff;  // Z轴按宽度缩放

    // --- 手动计算Billboard和旋转 ---
    vec3 y_axis = vec3(0,1,0);

    // 使用INV_VIEW_MATRIX来获得相机方向
    vec3 x_axis = normalize(cross(y_axis, INV_VIEW_MATRIX[2].xyz));
    vec3 z_axis = normalize(cross(x_axis, y_axis));

    // 应用旋转矩阵
    mat3 rotation_matrix = mat3(x_axis, y_axis, z_axis);
    VERTEX = rotation_matrix * VERTEX;

}
void fragment() {
	vec2 base_uv = UV;
	vec4 albedo1_tex = texture(texture_albedo1, base_uv);
	vec4 albedo2_tex = texture(texture_albedo2, base_uv);

	// 计算第一个albedo的alpha值
	float alpha1_factor = alpha1;
	if (use_alpha1_texture) {
		vec4 alpha1_tex = texture(texture_alpha1, base_uv);
		float alpha1_value = alpha1_tex.r;
		if (invert_alpha1_texture) {
			alpha1_value = 1.0 - alpha1_value;
		}
		alpha1_factor *= alpha1_value;
	}

	// 计算第二个albedo的alpha值
	float alpha2_factor = alpha2;
	if (use_alpha2_texture) {
		vec4 alpha2_tex = texture(texture_alpha2, base_uv);
		float alpha2_value = alpha2_tex.r;
		if (invert_alpha2_texture) {
			alpha2_value = 1.0 - alpha2_value;
		}
		alpha2_factor *= alpha2_value;
	}

	// 分别计算两个albedo与各自alpha的混合结果
	vec3 albedo_color1 = albedo1.rgb * albedo1_tex.rgb;
	vec3 albedo_color2 = albedo2.rgb * albedo2_tex.rgb;

	// 根据各自的alpha值调整颜色强度
	albedo_color1 *= alpha1_factor;
	albedo_color2 *= alpha2_factor;

	// 最终混合两个颜色
	vec3 final_albedo;
	if (use_albedo2_blend) {
		// 使用加法混合或者可以选择其他混合模式
		final_albedo = albedo_color1 + albedo_color2;
	} else {
		// 只使用第一个albedo
		final_albedo = albedo_color1;
	}

	ALBEDO = final_albedo;

	// 计算最终的alpha值
	float final_alpha = albedo1.a * albedo1_tex.a;
	if (use_albedo2_blend) {
		// 当使用混合时，使用两个alpha的最大值
		final_alpha = max(alpha1_factor, alpha2_factor);
	} else {
		final_alpha *= alpha1_factor;
	}

	ALPHA = final_alpha;
}
