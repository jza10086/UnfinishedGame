shader_type spatial;

// 渲染设置
render_mode unshaded,blend_mix, cull_disabled, depth_draw_opaque, skip_vertex_transform;

// 三角形参数
uniform float triangle_width : hint_range(0.1, 2.0) = 1.0;
uniform float triangle_height : hint_range(0.1, 2.0) = 1.0;
uniform vec4 triangle_center_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 triangle_edge_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);

// 三角形分区颜色设置
uniform bool use_separate_edge_colors = false;
uniform vec4 triangle_bottom_edge_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);  // 底边颜色
uniform vec4 triangle_left_edge_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);   // 左腰颜色
uniform vec4 triangle_right_edge_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);  // 右腰颜色

// 3D特有参数
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform bool use_world_coordinates = true;

// 渐变效果
uniform float gradient_strength : hint_range(0.0, 1.0) = 0.5;
uniform bool gradient_from_edge = true; // true=从边缘到中心，false=从中心到边缘
uniform float gradient_center_size : hint_range(0.0, 1.0) = 0.3; // 中心区域大小
uniform float gradient_sharpness : hint_range(0.0001, 5.0) = 1.0; // 渐变锐利度
uniform float gradient_offset : hint_range(0.0, 1.0) = 0.0; // 渐变偏移

// 三角形位置和方向
uniform float rotation : hint_range(0.0, 360.0) = 0.0;
uniform vec2 position_offset = vec2(0.0, 0.0);

// 重复模式
uniform float repeat_x : hint_range(0.01, 10.0) = 1.0;
uniform float repeat_y : hint_range(0.01, 10.0) = 1.0;

// 动画参数
uniform float speed : hint_range(-5.0, 5.0) = 0.0;
uniform vec2 move_direction = vec2(1.0, 0.0);

// UV重复效果
uniform float uv_scale_x : hint_range(-10.0, 10.0) = 1.0;
uniform float uv_scale_y : hint_range(-10.0, 10.0) = 1.0;

// 旋转函数
vec2 rotate(vec2 uv, float angle) {
    float rad = radians(angle);
    float cosAngle = cos(rad);
    float sinAngle = sin(rad);

    mat2 rotMatrix = mat2(vec2(cosAngle, -sinAngle), vec2(sinAngle, cosAngle));
    return rotMatrix * (uv - 0.5) + 0.5;
}

// 简化的三角形检测函数
bool is_in_triangle(vec2 p, float width, float height) {
    // 将坐标系调整到以底边中心为原点
    p.y += height * 0.5; // 向上移动，使底边在y=0

    // 检查是否在三角形内部
    // 底边范围检查
    if (p.y < 0.0 || p.y > height) {
        return false;
    }

    // 计算在当前高度的三角形宽度
    float current_width = width * (1.0 - p.y / height);

    // 检查是否在当前高度的宽度范围内
    return abs(p.x) <= current_width * 0.5;
}

// 计算点到直线的距离
float distance_to_line(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    vec2 ap = p - a;
    float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    vec2 closest = a + t * ab;
    return length(p - closest);
}

// 计算三角形内部渐变（基于到三条边的最短距离）
float triangle_gradient(vec2 p, float width, float height) {
    // 调整坐标系，使底边在y=0
    p.y += height * 0.5;

    // 定义等腰三角形的三个顶点
    vec2 top = vec2(0.0, height);           // 顶点
    vec2 bottom_left = vec2(-width * 0.5, 0.0);  // 左下角
    vec2 bottom_right = vec2(width * 0.5, 0.0);  // 右下角

    // 计算到三条边的距离
    float dist_to_left_edge = distance_to_line(p, top, bottom_left);
    float dist_to_right_edge = distance_to_line(p, top, bottom_right);
    float dist_to_bottom_edge = distance_to_line(p, bottom_left, bottom_right);

    // 取到最近边的距离
    float min_dist_to_edge = min(min(dist_to_left_edge, dist_to_right_edge), dist_to_bottom_edge);

    // 计算三角形的内切圆半径作为归一化因子
    // 对于等腰三角形，内切圆半径 = 面积 / 半周长
    float area = 0.5 * width * height;
    float perimeter = width + 2.0 * sqrt(pow(width * 0.5, 2.0) + pow(height, 2.0));
    float inradius = area / (perimeter * 0.5);

    // 归一化距离（0.0 = 边缘，1.0 = 中心）
    float normalized_dist = clamp(min_dist_to_edge / inradius, 0.0, 1.0);

    // 应用中心区域大小调整
    // gradient_center_size控制中心区域的大小
    normalized_dist = (normalized_dist - gradient_center_size) / (1.0 - gradient_center_size);
    normalized_dist = clamp(normalized_dist, 0.0, 1.0);

    // 应用渐变偏移
    normalized_dist = clamp(normalized_dist + gradient_offset, 0.0, 1.0);

    // 应用锐利度调整
    // gradient_sharpness > 1.0 使渐变更锐利，< 1.0 使渐变更平滑
    normalized_dist = pow(normalized_dist, gradient_sharpness);

    if (gradient_from_edge) {
        return normalized_dist; // 从边缘到中心
    } else {
        return 1.0 - normalized_dist; // 从中心到边缘
    }
}

// 计算三角形分区颜色
vec4 calculate_triangle_color(vec2 p, float width, float height) {
    vec4 base_center_color = triangle_center_color;
    vec4 base_edge_color = triangle_edge_color;

    // 如果启用分区颜色，则根据位置选择不同的边缘颜色
    if (use_separate_edge_colors) {
        // 调整坐标系，使底边在y=0
        vec2 adjusted_p = p;
        adjusted_p.y += height * 0.5;

        // 定义等腰三角形的三个顶点
        vec2 top = vec2(0.0, height);
        vec2 bottom_left = vec2(-width * 0.5, 0.0);
        vec2 bottom_right = vec2(width * 0.5, 0.0);

        // 计算到三条边的距离
        float dist_to_left_edge = distance_to_line(adjusted_p, top, bottom_left);
        float dist_to_right_edge = distance_to_line(adjusted_p, top, bottom_right);
        float dist_to_bottom_edge = distance_to_line(adjusted_p, bottom_left, bottom_right);

        // 找到最近的边，决定使用哪种边缘颜色
        float min_dist = min(min(dist_to_left_edge, dist_to_right_edge), dist_to_bottom_edge);

        if (min_dist == dist_to_left_edge) {
            base_edge_color = triangle_left_edge_color;
        } else if (min_dist == dist_to_right_edge) {
            base_edge_color = triangle_right_edge_color;
        } else {
            base_edge_color = triangle_bottom_edge_color;
        }
    }

    // 应用原有的渐变逻辑
    float gradient_factor = 1.0;
    if (gradient_strength > 0.0) {
        gradient_factor = triangle_gradient(p, width, height);
        gradient_factor = mix(1.0, gradient_factor, gradient_strength);
    }

    // 基于渐变因子混合中心色和边缘色
    if (gradient_from_edge) {
        return mix(base_edge_color, base_center_color, gradient_factor);
    } else {
        return mix(base_center_color, base_edge_color, gradient_factor);
    }
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
        // 使用局部坐标系
        vec4 local_pos = inverse(MODEL_MATRIX) * vec4(world_position, 1.0);

        // 提取缩放信息来补偿缩放对纹理的影响
        vec3 scale = vec3(
            length(MODEL_MATRIX[0].xyz),
            length(MODEL_MATRIX[1].xyz),
            length(MODEL_MATRIX[2].xyz)
        );

        // 使用xz平面，并补偿缩放
        uv = local_pos.xz * vec2(scale.x, scale.z);
    } else {
        uv = world_uv;
    }

    // 应用UV重复缩放
    uv.x *= uv_scale_x;
    uv.y *= uv_scale_y;

    // 添加动画偏移
    if (abs(speed) > 0.0001) {
        uv += TIME * speed * normalize(move_direction);
    }

    // 添加位置偏移
    uv += position_offset;

    // 应用旋转
    if (abs(rotation) > 0.0001) {
        uv = rotate(uv, rotation);
    }

    // 应用重复模式
    vec2 repeated_uv = fract(uv * vec2(repeat_x, repeat_y)) - 0.5;

    // 检查是否在三角形内部
    bool in_triangle = is_in_triangle(repeated_uv, triangle_width, triangle_height);
    float triangle_mask = in_triangle ? 1.0 : 0.0;

    // 计算最终颜色
    vec4 final_color = background_color;

    if (triangle_mask > 0.5) {
        // 使用新的三角形颜色计算函数
        vec4 triangle_color = calculate_triangle_color(repeated_uv, triangle_width, triangle_height);
        final_color = triangle_color;
    }

    // 应用总体透明度
    final_color.a *= alpha;

    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
}