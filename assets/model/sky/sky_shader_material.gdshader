shader_type sky;

// HDR天空纹理
group_uniforms sky_texture;
uniform sampler2D sky_hdr : source_color, hint_default_white, filter_linear_mipmap;

// 相机偏移参数
group_uniforms camera_offset;
uniform vec3 camera_position = vec3(0.0, 0.0, 0.0);
uniform float parallax_strength : hint_range(0.0, 2.0) = 0.5;
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);

// 旋转参数
group_uniforms rotation;
uniform float rotation_speed : hint_range(-2.0, 2.0) = 0.0;
uniform vec3 rotation_axis = vec3(0.0, 1.0, 0.0);

// 颜色调节
group_uniforms color_adjustment;
uniform float exposure : hint_range(0.0, 5.0) = 1.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform vec3 color_tint : source_color = vec3(1.0, 1.0, 1.0);

// 大气效果
group_uniforms atmosphere;
uniform float horizon_fade : hint_range(0.0, 10.0) = 1.0;
uniform vec3 horizon_color : source_color = vec3(1.0, 0.8, 0.6);
uniform float atmosphere_strength : hint_range(0.0, 1.0) = 0.2;

// 将3D方向转换为球面坐标UV
vec2 dir_to_spherical_uv(vec3 dir) {
    float phi = atan(dir.z, dir.x);
    float theta = acos(clamp(dir.y, -1.0, 1.0));

    vec2 uv;
    uv.x = (phi / PI + 1.0) * 0.5;
    uv.y = theta / PI;

    return uv;
}

// 旋转3D向量
vec3 rotate_vector(vec3 v, vec3 axis, float angle) {
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);
    vec3 k = normalize(axis);

    return v * cos_angle + cross(k, v) * sin_angle + k * dot(k, v) * (1.0 - cos_angle);
}

// HDR色调映射
vec3 tone_mapping(vec3 color) {
    // ACES色调映射
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;

    color *= exposure;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

// 颜色调节函数
vec3 adjust_color(vec3 color) {
    // 亮度调节
    color *= brightness;

    // 对比度调节
    color = (color - 0.5) * contrast + 0.5;

    // 饱和度调节
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(luminance), color, saturation);

    // 色调调节
    color *= color_tint;

    return color;
}

void sky() {
    // 获取当前像素的天空方向
    vec3 sky_dir = EYEDIR;

    // 应用时间相关的旋转
    float time_rotation = TIME * rotation_speed;
    sky_dir = rotate_vector(sky_dir, normalize(rotation_axis), time_rotation);

    // 基于相机位置计算视差偏移
    vec3 parallax_offset = camera_position * parallax_strength * 0.001;
    sky_dir += parallax_offset;
    sky_dir = normalize(sky_dir);

    // 转换为球面UV坐标
    vec2 sky_uv = dir_to_spherical_uv(sky_dir);

    // 应用UV缩放和偏移
    sky_uv = sky_uv * uv_scale + uv_offset;

    // 确保UV在有效范围内（平铺）
    sky_uv = fract(sky_uv);

    // 采样HDR天空纹理
    vec3 sky_color = texture(sky_hdr, sky_uv).rgb;

    // 计算地平线效果
    float horizon_factor = 1.0 - pow(abs(sky_dir.y), horizon_fade);
    vec3 atmosphere_effect = mix(sky_color, horizon_color, horizon_factor * atmosphere_strength);

    // 混合大气效果
    sky_color = mix(sky_color, atmosphere_effect, atmosphere_strength);

    // 应用颜色调节
    sky_color = adjust_color(sky_color);

    // HDR色调映射
    sky_color = tone_mapping(sky_color);

    // 输出最终颜色
    COLOR = sky_color;
}