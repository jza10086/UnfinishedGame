shader_type spatial; // 声明为3D Shader
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx; // 常用的PBR渲染模式

// --- Uniforms (暴露给编辑器的属性) ---

// 基础色
uniform vec4 base_color : source_color = vec4(0.8, 0.8, 0.8, 1.0); // 基础颜色，默认为灰色
uniform sampler2D base_color_texture : source_color, filter_linear_mipmap, repeat_enable; // 基础色贴图

// 金属度
uniform float metallic : hint_range(0.0, 1.0) = 0.0; // 金属度，0为电介质，1为金属
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap, repeat_enable; // 金属度贴图 (通常使用R通道)

// 粗糙度 (控制高光)
uniform float roughness : hint_range(0.0, 1.0) = 0.5; // 粗糙度，0为光滑，1为粗糙
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap, repeat_enable; // 粗糙度贴图 (通常使用R通道)

// 自发光
uniform vec3 emission_color : source_color = vec3(0.0, 0.0, 0.0); // 自发光颜色
uniform float emission_energy : hint_range(0.0, 100.0) = 1.0; // 自发光强度
uniform sampler2D emission_texture : hint_default_black, filter_linear_mipmap, repeat_enable; // 自发光贴图

// 法线贴图 (可选，但PBR常用)
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-1.0, 1.0) = 1.0;

// 环境光遮蔽 (AO) (可选)
uniform sampler2D ao_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float ao_light_affect : hint_range(0.0, 1.0) = 0.0; // AO对直接光和间接光的影响程度

// 透明度
uniform float alpha : hint_range(0.0, 1.0) = 1.0; // 透明度，0为完全透明，1为不透明
uniform sampler2D alpha_texture : hint_default_white, filter_linear_mipmap, repeat_enable; // 透明度贴图 (通常使用R通道或A通道)

// --- 片段着色器 ---
void fragment() {
    // 从贴图采样或使用uniform值
    vec4 albedo_tex = texture(base_color_texture, UV);
    ALBEDO = base_color.rgb * albedo_tex.rgb; // 混合基础色和贴图颜色

    float metallic_val = metallic * texture(metallic_texture, UV).r; // 通常金属度贴图的红色通道
    METALLIC = metallic_val;

    float roughness_val = roughness * texture(roughness_texture, UV).r; // 通常粗糙度贴图的红色通道
    ROUGHNESS = roughness_val;

    vec3 emission_tex_color = texture(emission_texture, UV).rgb;
    EMISSION = emission_color * emission_tex_color * emission_energy;

    // 法线贴图
    // Check if a normal map texture is actually assigned before trying to use it.
    // Godot 4.x does not have a direct NORMAL_MAP_DEPTH > 0.0 check like in Godot 3.x for built-in outputs.
    // Instead, you'd typically check if the texture uniform itself is valid or use a boolean uniform.
    // For simplicity here, we'll assume if a normal_map is provided, it's intended to be used.
    // A more robust check might involve a separate boolean uniform `use_normal_map`.
    vec3 normal_tex = texture(normal_map, UV).rgb;
    if (length(normal_tex) > 0.001) { // A simple check if the texture is not entirely black (or unassigned)
        NORMAL_MAP = normal_tex;
        NORMAL_MAP_DEPTH = normal_scale;
    }


    // AO贴图
    AO = texture(ao_texture, UV).r;
    AO_LIGHT_AFFECT = ao_light_affect;

    // 透明度处理
    float alpha_tex_val = texture(alpha_texture, UV).r; //  假设透明度信息在R通道
    // 如果你的透明度贴图使用Alpha通道，可以改为: float alpha_tex_val = texture(alpha_texture, UV).a;
    ALPHA = base_color.a * albedo_tex.a * alpha * alpha_tex_val;
}