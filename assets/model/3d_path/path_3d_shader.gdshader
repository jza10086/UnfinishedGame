shader_type spatial;

// 渲染设置
render_mode unshaded,blend_mix, cull_disabled, depth_draw_opaque, skip_vertex_transform;

// 条纹参数
uniform float stripe_count : hint_range(0.0, 100.0) = 10.0;
uniform float stripe_width : hint_range(0.0, 10.0) = 0.5;
uniform vec4 color1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// 3D特有参数
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform bool use_world_coordinates = true;

// 条纹方向和动画
uniform float rotation : hint_range(0.0, 360.0) = 0.0;
uniform float speed : hint_range(-5.0, 5.0) = 0.0;
uniform float offset : hint_range(-2.0, 2.0) = 0.0;

// UV偏移（像素绝对值）
uniform float uv_offset_x : hint_range(-100.0, 100.0) = 0.0;
uniform float uv_offset_y : hint_range(-100.0, 100.0) = 0.0;

// 条纹两端渐变强度（专门控制color1条纹两端的渐隐效果）
uniform float stripe_fade : hint_range(0.0, 1.0) = 0.0;

// 垂直路径方向渐隐效果
uniform float vertical_fade_strength : hint_range(0.0, 1.0) = 0.0;
uniform float vertical_fade_top : hint_range(0.0, 1.0) = 0.2;
uniform float vertical_fade_bottom : hint_range(0.0, 1.0) = 0.2;

// UV重复效果（基于局部坐标系，纹理跟随物体旋转和位移，不受缩放影响）
uniform float uv_scale_x : hint_range(0.0, 10.0) = 1.0;
uniform float uv_scale_y : hint_range(0.0, 10.0) = 1.0;

// 全局UV缩放（统一缩放所有UV坐标）
uniform float global_uv_scale : hint_range(0.01, 10.0) = 1.0;

// 旋转函数
vec2 rotate(vec2 uv, float angle) {
    float rad = radians(angle);
    float cosAngle = cos(rad);
    float sinAngle = sin(rad);

    mat2 rotMatrix = mat2(vec2(cosAngle, -sinAngle), vec2(sinAngle, cosAngle));
    return rotMatrix * (uv - 0.5) + 0.5;
}

varying vec2 world_uv;
varying vec3 world_position;

void vertex() {
    // 计算真实的世界空间位置
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_uv = UV;

    // 手动变换顶点到裁剪空间
    POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
}

void fragment() {
    vec2 uv;

    // 选择使用世界坐标还是UV坐标
    if (use_world_coordinates) {
        // 使用局部坐标系，物体旋转和位移时纹理跟随移动，但不受缩放影响
        // 获取局部空间位置（相对于物体原点）
        vec4 local_pos = inverse(MODEL_MATRIX) * vec4(world_position, 1.0);

        // 提取缩放信息来补偿缩放对纹理的影响
        vec3 scale = vec3(
            length(MODEL_MATRIX[0].xyz),  // X轴缩放
            length(MODEL_MATRIX[1].xyz),  // Y轴缩放
            length(MODEL_MATRIX[2].xyz)   // Z轴缩放
        );

        // 使用xz平面，并补偿缩放
        uv = local_pos.xz * vec2(scale.x, scale.z);
    } else {
        uv = world_uv;
    }

    // 应用全局UV缩放
    uv *= global_uv_scale;

    // 应用UV重复缩放（独立控制X和Y方向）
    uv.x *= uv_scale_x;
    uv.y *= uv_scale_y;

    // 应用UV偏移（像素绝对值）
    uv.x += uv_offset_x * 0.01; // 转换为合适的单位
    uv.y += uv_offset_y * 0.01;

    // 应用旋转
    if (abs(rotation - 0.0) > 0.0001) {
        uv = rotate(uv, rotation);
    }

    // 计算条纹位置（沿Y轴，路径长度方向）
    float stripe_pos = uv.y * stripe_count;

    // 添加时间动画
    if (abs(speed - 0.0) > 0.0001) {
        stripe_pos += TIME * -speed * stripe_count;
    }

    // 添加偏移
    stripe_pos += offset * stripe_count;

    // 计算条纹模式
    float stripe_pattern = fract(stripe_pos);

    // 应用条纹宽度
    float stripe_mask = step(stripe_width, stripe_pattern);

    // 混合颜色
    vec4 final_color = mix(color1, color2, stripe_mask);

    // 应用color1条纹两端渐变效果（独立的渐变控制）
    if (stripe_fade > 0.0) {
        // 重新计算未平滑的条纹位置，确保正确识别color1条纹
        float raw_stripe_pattern = fract(stripe_pos);

        // 判断当前是否在color1条纹内（使用原始的step函数判断）
        bool is_color1_stripe = raw_stripe_pattern < stripe_width;

        if (is_color1_stripe) {
            // 计算在color1条纹内的相对位置 (0.0 到 1.0)
            float color1_local_pos = raw_stripe_pattern / stripe_width;

            // 计算距离条纹中心的距离
            float distance_from_center = abs(color1_local_pos - 0.5);

            // 计算渐变因子：中心为1.0，两端根据stripe_fade参数渐变到0.0
            float fade_factor = 1.0 - smoothstep(0.5 - stripe_fade * 0.5, 0.5, distance_from_center);

            // 只修改透明度，避免颜色混合问题
            final_color.a *= fade_factor;
        }
    }

    // 应用垂直路径方向渐隐效果
    if (vertical_fade_strength > 0.0) {
        // 获取垂直方向的UV坐标（路径宽度方向，通常是X轴）
        float vertical_pos = uv.x;

        // 标准化到0-1范围（假设UV范围是-0.5到0.5）
        vertical_pos = (vertical_pos + 0.5);

        // 计算渐隐因子
        float vertical_fade_factor = 1.0;

        // 顶部渐隐（UV.x接近1.0的区域）
        if (vertical_fade_top > 0.0) {
            float top_fade = smoothstep(1.0 - vertical_fade_top, 1.0, vertical_pos);
            vertical_fade_factor *= (1.0 - top_fade * vertical_fade_strength);
        }

        // 底部渐隐（UV.x接近0.0的区域）
        if (vertical_fade_bottom > 0.0) {
            float bottom_fade = smoothstep(0.0, vertical_fade_bottom, vertical_pos);
            vertical_fade_factor *= bottom_fade * (1.0 - vertical_fade_strength) + vertical_fade_strength;
        }

        // 应用垂直渐隐效果到透明度
        final_color.a *= vertical_fade_factor;
    }

    final_color.a *= alpha;

    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
}