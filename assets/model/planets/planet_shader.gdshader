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

// --- 顶点着色器 ---
// 通常，对于简单的PBR材质，我们不需要修改顶点着色器的默认行为
// void vertex() {
//     // 可以修改VERTEX, NORMAL, UV等
// }

// --- 片段着色器 ---
void fragment() {
    // 从贴图采样或使用uniform值
    vec4 albedo_tex = texture(base_color_texture, UV);
    ALBEDO = base_color.rgb * albedo_tex.rgb; // 混合基础色和贴图颜色

    float metallic_val = metallic * texture(metallic_texture, UV).r; // 通常金属度贴图的红色通道
    METALLIC = metallic_val;

    float roughness_val = roughness * texture(roughness_texture, UV).r; // 通常粗糙度贴图的红色通道
    ROUGHNESS = roughness_val;

    // Blender的原理化BSDF中的高光实际上是“Specular Tint”和“Sheen”等更复杂的参数，
    // 这里我们简化为通过粗糙度控制的标准PBR高光。
    // 如果需要更精确的“高光”控制（非金属的镜面反射强度），
    // 可以使用SPECULAR uniform (float, 0.0 to 1.0, default 0.5 for dielectrics)
    // SPECULAR = 0.5; // 默认值，对于非金属材质，控制菲涅尔反射的基础强度

    vec3 emission_tex_color = texture(emission_texture, UV).rgb;
    EMISSION = emission_color * emission_tex_color * emission_energy;

    // 法线贴图
    if (NORMAL_MAP_DEPTH > 0.0) { // 检查是否有法线贴图
        vec3 normal_tex = texture(normal_map, UV).rgb;
        NORMAL_MAP = normal_tex;
        NORMAL_MAP_DEPTH = normal_scale;
    }

    // AO贴图
    AO = texture(ao_texture, UV).r;
    AO_LIGHT_AFFECT = ao_light_affect;

    // 透明度 (如果需要)
    // ALPHA = base_color.a * albedo_tex.a;
    // 如果需要透明效果，render_mode 需要包含 blend_mix, depth_draw_alpha_prepass 等
    // 并且 ALPHA_SCISSOR_THRESHOLD 或 ALPHA_HASH_SCALE 可能需要设置
}

// --- 光照着色器 (可选) ---
// 对于大多数PBR效果，Godot的内置光照处理已经足够好。
// 如果你需要非常特殊的光照交互，可以自定义light()函数。
// void light() {
//     // DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT_DIRECTION), 0.0, 1.0) * LIGHT_COLOR * ATTENUATION;
//     // SPECULAR_LIGHT += ...
// }