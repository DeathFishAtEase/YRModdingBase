sampler top_sampler : register(s11);
sampler shroud_sampler : register(s12);
sampler laser_sampler : register(s13);
sampler zbuffer : register(s14);
sampler distortion_sampler : register(s15);

uniform float4 engine_constants : register(c0);
uniform float4 window_dimension : register(c1);//laser only
uniform float4 anim_progress_paras : register(c1);//anim only
uniform float4 pixel_shader_paras : register(c2);//x = distortion value y = Remaining iterations
uniform float4 laser_xysegs_distort_xysegs : register(c5);
uniform float2 laser_frame_distort_frame : register(c6);
//zw = Sheet.Dimension.X Y

uniform float4 vertex_data[5] : register(c5);
uniform float4 distort_vdata[5] : register(c10);
uniform float distortion : register(c15);
//static const float distortion_width_ratio = 1.5;

//render target 1
struct VSOutput
{
    vector position : POSITION;//position
    float2 uv : TEXCOORD0;
    float3 coords : TEXCOORD1;//position + zvalue
};

float color2grayscale(float3 color)
{
    return saturate(3.0 * dot(color, float3(0.2126, 0.7152, 0.0722)));
    //return 0.1;
}

int buffer_value_convertion(vector value)
{
    //int rvalue = ceil(value.r * 31) * 32 * 64;
    //int gvalue = ceil(value.g * 63) * 32;
    //int bvalue = value.b * 31;

    return value.x * 65535;
}

float2 compute_uv(int frame, float2 uv, float2 sheet_dimension)
{
    int nline = frame / sheet_dimension.x;
    int nrow = frame - nline * sheet_dimension.x;
    float2 singleframe_dimension = 1.0f.xx / sheet_dimension;
    float2 inframe_offset = singleframe_dimension * uv;
    return float2(nrow, nline) * singleframe_dimension + inframe_offset;
}

//for animation only
float2 auto_compute_uv(float2 uv)
{
    return compute_uv(anim_progress_paras.x, uv, pixel_shader_paras.zw);
}

//for laser only
float2 laser_auto_compute_uv(float2 uv, bool distort = false)
{
    return compute_uv(distort ? laser_frame_distort_frame.y : laser_frame_distort_frame.x, uv, distort ? laser_xysegs_distort_xysegs.zw : laser_xysegs_distort_xysegs.xy);
}

float2 screenpos2bufferpos(float2 window_dimension, float2 coords_in_screen)
{
    float2 buffer_dimension = window_dimension.xy - float2(168.0f, 32.0f);
    float2 pixel_unit_screen = 1.0f.xx / (window_dimension.xy - 1.0f.xx);
    float2 pixel_unit_buffer = 1.0f.xx / (buffer_dimension.xy - 1.0f.xx);
    float2 pixel_number = coords_in_screen / pixel_unit_screen;
    return pixel_number * pixel_unit_buffer;
}

float2 bufferpos2screenpos(float2 window_dimension, float2 coords_in_buffer)
{
    float2 buffer_dimension = window_dimension.xy - float2(168.0f, 32.0f);
    float2 pixel_unit_screen = 1.0f.xx / (window_dimension.xy - 1.0f.xx);
    float2 pixel_unit_buffer = 1.0f.xx / (buffer_dimension.xy - 1.0f.xx);
    float2 pixel_number = coords_in_buffer / pixel_unit_buffer;
    return pixel_number * pixel_unit_screen;
}

//VSOutput vmain(in vector coords : POSITION0, in float2 uv : TEXCOORD0)
//{
//    VSOutput output;
    
//    output.position = vector((coords.xy - float2(0.5, 0.5)) * float2(2.0, -2.0), 0.0, 1.0);
//    output.coords = coords.xyz;
//    output.uv = uv.yx;
//    return output;
//}

VSOutput vmain(in int vertexid : TEXCOORD0)
{
    VSOutput output;
    
    float2 coords = distortion == 0.0f ? vertex_data[vertexid].xy : distort_vdata[vertexid].xy;
    float2 uv = distortion == 0.0f ? vertex_data[vertexid].zw : distort_vdata[vertexid].zw;
    float z = distortion == 0.0f ? vertex_data[4][vertexid] : distort_vdata[4][vertexid];
    
    output.position = vector((coords.xy - float2(0.5, 0.5)) * float2(2.0, -2.0), 0.0, 1.0);
    output.coords = float3(coords, z);
    output.uv = uv.yx;
    
    return output;
}

vector pmain(in VSOutput input) : COLOR0
{
    float zvalue = input.coords.z;
    const float intensity = engine_constants.x;
    //const float displacement = engine_constants.y;
    //const float distortion_width_ratio = engine_constants.z;
    float2 zcoord = input.coords.xy * float2(window_dimension.x / (window_dimension.x - 168), window_dimension.y / (window_dimension.y - 32));
    
    vector zcolor = tex2D(zbuffer, zcoord);
    //int rvalue = ceil(zcolor.r * 31) * 32 * 64;
    //int gvalue = ceil(zcolor.g * 63) * 32;
    //int bvalue = zcolor.b * 31;
    float topmask = tex2D(top_sampler, input.coords.xy).r;
    float zbuffer_val = buffer_value_convertion(zcolor);
    vector aval = tex2D(shroud_sampler, zcoord);
    float faval = buffer_value_convertion(aval);
    
    if (zbuffer_val < zvalue || topmask)
        discard;
    
    if (input.coords.x >= 1 - 168.0 / window_dimension.x ||
        input.coords.y >= 1 - 32.0 / window_dimension.y)
        discard;
    //float u = (input.uv.x - floor(input.uv.x)) * (1 - (input.uv.x - floor(input.uv.x)));
    //float v = (input.uv.y - floor(input.uv.y)) * (1 - (input.uv.y - floor(input.uv.y)));
    //return vector(saturate((u + v) / 2), 0, 0, 1);
    vector texturecolor = tex2D(laser_sampler, laser_auto_compute_uv(input.uv));
    return vector(saturate(intensity * texturecolor.rgb * faval / 127.0), texturecolor.a * intensity);
    //return 1.0f.xxxx;
}

vector dmain(in VSOutput input) : COLOR0
{
    float2 zbuffer_uv = input.coords.xy;
    float zvalue = input.coords.z;
    const float intensity = engine_constants.x;
    const float displacement = engine_constants.y;
    
    vector zcolor = tex2D(zbuffer, zbuffer_uv);
    
    float zbuffer_val = buffer_value_convertion(zcolor);
    float2 topcrd = input.coords.xy / float2(window_dimension.x / (window_dimension.x - 168), window_dimension.y / (window_dimension.y - 32));
    float topmask = tex2D(top_sampler, topcrd).r;
    if (zbuffer_val < zvalue || topmask)
        discard;
    
    float2 displacement_vec = displacement.xx / window_dimension.xy;
    vector distort = tex2D(distortion_sampler, laser_auto_compute_uv(input.uv, true));
    distort.xy = float2(0.5f, 0.5f) + intensity * displacement_vec * (distort.xy - float2(0.5, 0.5));
    //return vector(0.5, 0.5, 1, 1);
    return distort;
}

//VSOutput avmain(in vector coords : POSITION0, in float2 uv : TEXCOORD0)
//{
//    VSOutput output;
    
//    //float2 window_dimension = engine_constants.zw;
//    output.coords = coords.xyz;
    
//    //coords.x *= (window_dimension.x / (window_dimension.x - 168));
//    //coords.y *= (window_dimension.y / (window_dimension.y - 32));
    
//    output.position = vector((coords.xy - float2(0.5, 0.5)) * float2(2.0, -2.0), 0.0, 1.0);;
//    output.uv = uv;
//    return output;
//}

VSOutput avmain(in int vertexid : TEXCOORD0)
{
    /*
    0---1
    |   |
    2---3
*/
    //decoding constants
    float4 dimension = engine_constants;
    float2 canvaz_dimension = window_dimension.xy;
    float topz = window_dimension.z;
    float bottomz = window_dimension.w;
    
    VSOutput output;
    
    output.uv.x = (vertexid == 1 || vertexid == 3) ? 1.0 : 0.0;
    output.uv.y = (vertexid == 2 || vertexid == 3) ? 1.0 : 0.0;
    
    float2 base_coords = float2(dimension.x / canvaz_dimension.x, dimension.y / canvaz_dimension.y);
    float2 offsets = float2(dimension.z / canvaz_dimension.x, dimension.w / canvaz_dimension.y);
    float2 coords = base_coords + output.uv * offsets;
    
    output.position = vector((coords.xy - float2(0.5, 0.5)) * float2(2.0, -2.0), 0.0, 1.0);
    output.coords.xy = coords;
    output.coords.z = (vertexid == 0 || vertexid == 1) ? topz : bottomz;
    
    return output;
}

vector admain(in VSOutput input) : COLOR0
{
    float zvalue = input.coords.z;
    float2 window_dimension = engine_constants.zw;
    float transparency = engine_constants.y;
    
    float2 zcoord = input.coords.xy * float2(window_dimension.x / (window_dimension.x - 168), window_dimension.y / (window_dimension.y - 32));
    vector zcolor = tex2D(zbuffer, input.coords.xy);
    //int rvalue = ceil(zcolor.r * 31) * 32 * 64;
    //int gvalue = ceil(zcolor.g * 63) * 32;
    //int bvalue = zcolor.b * 31;
    
    float zbuffer_val = buffer_value_convertion(zcolor);
    float topmask = tex2D(top_sampler, input.coords.xy).r;
    if (zbuffer_val < zvalue || topmask)
        discard;
    
    float2 displacement_vec = pixel_shader_paras.xx / window_dimension.xy;
    vector distort = tex2D(distortion_sampler, auto_compute_uv(input.uv));
    distort.xy = float2(0.5, 0.5) + displacement_vec * transparency / 100.0 * (distort.xy - float2(0.5, 0.5));
    return distort;
}

vector apmain(in VSOutput input) : COLOR0
{
    //input.uv = input.uv.yx;
    float2 window_dimension = engine_constants.zw;
    float3 coords = input.coords;
    float zvalue = input.coords.z;
    
    float2 zcoord = coords.xy * float2(window_dimension.x / (window_dimension.x - 168), window_dimension.y / (window_dimension.y - 32));
    vector zcolor = tex2D(zbuffer, zcoord);
    //int rvalue = ceil(zcolor.r * 31) * 32 * 64;
    //int gvalue = ceil(zcolor.g * 63) * 32;
    //int bvalue = zcolor.b * 31;
    
    float zbuffer_val = buffer_value_convertion(zcolor);
    vector aval = tex2D(shroud_sampler, zcoord);
    float faval = buffer_value_convertion(aval);
    //clamp(ceil(aval.r * 31) * 64 * 32 + ceil(aval.g * 63) * 32 + aval.b * 31, 0.0f, 254.0f);
    
    float topmask = tex2D(top_sampler, input.coords.xy).r;
    if (zbuffer_val < zvalue || topmask)
        discard;
    
    if (coords.x >= 1 - 168.0 / window_dimension.x ||
        coords.y >= 1 - 32.0 / window_dimension.y)
        discard;
   
    vector color = tex2D(laser_sampler, auto_compute_uv(input.uv));
    return vector(faval / 127.0 * color.rgb * engine_constants.x / 1000.0, color.a * engine_constants.y / 100.0);
}

struct fillervs_output
{
    vector position : POSITION;
    //float2 texcoord : TEXCOORD0;
};

fillervs_output filler_vs(in int vertexid : TEXCOORD0)
{
    fillervs_output output;
    
    output.position.x = (vertexid == 0 || vertexid == 2) ? -1.0f : 1.0f;
    output.position.y = (vertexid == 0 || vertexid == 1) ? -1.0f : 1.0f;
    output.position.zw = 1.0f.xx;
    //output.texcoord
    
    return output;
}

vector filler_main() : COLOR0
{
    return vector(0.5f.xx, 1.0f.xx);
}

    //just a description
struct state_parameters
{
    float alphalevel;
    float opacity;
    float current_frame;
    float duration;
};
    
uniform float2 fx_screen_dimension : register(c0);
uniform float4 fx_state : register(c1);
uniform float3 fx_center_pos : register(c2);
uniform float4 fx_vertex_data[4] : register(c3);

VSOutput particle_vs(in int vertexid : TEXCOORD0)
{
    VSOutput output;
    float2 canvaz = fx_screen_dimension;
    //float3 center = fx_center_pos;
    float4 vertex_data = fx_vertex_data[vertexid];
    
    vertex_data.xy /= canvaz;
    output.coords = vertex_data.xyz;
    output.position = vector((output.coords.xy - float2(0.5f, 0.5f)) * float2(2.0f, -2.0f), 0.0, 1.0);
    output.uv.x = (vertexid == 0 || vertexid == 2) ? 0.0f : 1.0f;
    output.uv.y = (vertexid == 0 || vertexid == 1) ? 0.0f : 1.0f;
    
    return output;
}

vector particle_main(in VSOutput input) : COLOR0
{
    float2 canvaz = fx_screen_dimension;
    float2 screen_buffer_uv = screenpos2bufferpos(canvaz, input.coords.xy);
    float zval = buffer_value_convertion(tex2D(zbuffer, screen_buffer_uv));
    float aval = buffer_value_convertion(tex2D(shroud_sampler, screen_buffer_uv));
    float topval = tex2D(top_sampler, input.coords.xy).r;
    float light_effector = fx_state.x / 1000.0f;
    float opacity = fx_state.y / 100.0f;
    
    if (zval < input.coords.z || topval != 0.0f)
        discard;
    
    if (input.coords.x >= 1.0f - 168.0f / canvaz.x ||
        input.coords.y >= 1.0f - 32.0f / canvaz.y)
        discard;
    
    vector color = tex2D(laser_sampler, input.uv);
    
    return vector(color.rgb * light_effector * aval / 127.0f, color.a * opacity);
}

vector particle_dmain(in VSOutput input) : COLOR0
{
    float2 canvaz = fx_screen_dimension;
    float2 screen_buffer_uv = input.coords.xy; //input.coords.xy / float2(canvaz.x / (canvaz.x - 168), canvaz.y / (canvaz.y - 32));
    float zval = buffer_value_convertion(tex2D(zbuffer, screen_buffer_uv));
    float aval = buffer_value_convertion(tex2D(shroud_sampler, screen_buffer_uv));
    float topval = tex2D(top_sampler, bufferpos2screenpos(canvaz + float2(168.0f, 32.0f), input.coords.xy)).r;
    
    if (zval < input.coords.z || topval)
        discard;
    
    //if (input.coords.x >= 1 - 168.0 / canvaz.x ||
    //    input.coords.y >= 1 - 32.0 / canvaz.y)
    //    discard;
    
    vector color = tex2D(laser_sampler, input.uv);
    
    return vector(color.rgb, 1.0f);
}

