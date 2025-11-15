#include "helpers.hlsl"

#define SCREEN_DIMENSION (float2(BUFFER_WIDTH,BUFFER_HEIGHT))
#define BUFFER_PIXEL_SIZE (1.0f.xx / SCREEN_DIMENSION)
#define YRBUFFER_WIDTH (BUFFER_WIDTH - 168.0f)
#define YRBUFFER_HEIGHT (BUFFER_HEIGHT - 32.0f)
#define YRBUFFER_DIMENSION (float2(YRBUFFER_WIDTH,YRBUFFER_HEIGHT))
#define YRBUFFER_PIXEL_SIZE (1.0f.xx / YRBUFFER_DIMENSION)

#define WATER_WAVE_MAP "4141-normal.jpg"
#define WATER_TEXTURE_WIDTH 512
#define WATER_TEXTURE_HEIGHT 512

#define SKY_TEXTURE_NAME "sky.png"
#define SKY_TEXTURE_WIDTH 910
#define SKY_TEXTURE_HEIGHT 348

//color data from engine
texture water_depth : WATERDEPTH;
texture watertex : WATER;
texture backbuffertex : COLOR;
texture toptex : TOPMASK;
sampler depth_map { Texture = water_depth; };
sampler water { Texture = watertex; };
sampler backbuffer { Texture = backbuffertex; };
sampler topmask { Texture = toptex; };

//constant data from engine
uniform float2 topcrd < string source = "game_coords"; > = 0.0f.xx;
uniform float2 surface_offsets < string source = "surface_offset"; > = 0.0f.xx;
uniform float is_in_game < string source = "is_in_game"; > = 0.0f;
uniform float ms_timer < string source = "timer"; > = 0.0f;

//texture data from file
texture wave_texture < string source = WATER_WAVE_MAP; > { Width = WATER_TEXTURE_WIDTH; Height = WATER_TEXTURE_HEIGHT; };
sampler wave_sampler { Texture = wave_texture; AddressU = Wrap; AddressV = Wrap; };
texture sky_texture < string source = SKY_TEXTURE_NAME; > { Width = SKY_TEXTURE_WIDTH; Height = SKY_TEXTURE_HEIGHT; };
sampler sky_sampler { Texture = sky_texture; AddressU = Wrap; AddressV = Wrap; };

//customizable data
uniform float sigma < string ui_type = "slider";
	string ui_label = "Sigma";
	string ui_category = "Test Effect";
	float ui_min = 0.001f;
	float ui_max = 50.0f;
	float ui_step = 0.001f;
> = 24.0f;

//uniform float3 water_color < string ui_type = "color";
//	string ui_label = "Water color";
//	string ui_category = "Water Effect";
//> = float3(0.15625f, 0.15625f, 0.3515625f);

uniform float game_obj_cover_judge < string  ui_type = "slider";
    string ui_lable = "Object cover judge";
    string ui_category = "Water Effect";
	float ui_min = 0.0f;
	float ui_max = 1.732f;
> = 0.1f;

uniform float water_magnification < string ui_type = "slider";
	string ui_label = "Cloud Magnification";
	string ui_category = "Cloud";
	float ui_min = 0.0;
	float ui_max = 5.0;
	float ui_step = 0.001;
> = 1.0;

uniform float wave_speed_ratio < string ui_type = "slider";
	string ui_label = "Cloud Speed Factor";
	string ui_category = "Cloud";
	float ui_min = 1.0;
    float ui_max = 200000.0;
	float ui_step = 10.0;
> = 30000.0;

uniform float water_reflection_coeff < string ui_type = "slider";
    string ui_lable = "Water reflection Strength (Spec)";
    string ui_category = "Water Effect";
	float ui_min = 0.0f;
	float ui_max = 5.0f;
> = 1.0f;

uniform float water_diffuse_coeff < string ui_type = "slider";
    string ui_lable = "Water reflection Strength (Diff)";
    string ui_category = "Water Effect";
	float ui_min = 0.0f;
	float ui_max = 5.0f;
> = 1.0f;

uniform float water_spec_coeff < string ui_type = "slider";
	string ui_label = "Water spec coeff";
	string ui_category = "Water Effect";
	float ui_min = 0.0f;
    float ui_max = 3.0f;
	float ui_step = 0.001f;
> = 1.0f;

uniform float3 water_reflection_color < string ui_type = "color";
	string ui_label = "Water light color (Spec)";
	string ui_category = "Water Effect";
> = float3(1.0f, 1.0f, 1.0f);

uniform float maximum_land_coeff < string ui_type = "slider";
	string ui_label = "Maximum Land Color Partition";
	string ui_category = "Water Effect";
	float ui_min = 0.0f;
    float ui_max = 1.0f;
	float ui_step = 0.001f;
> = 0.6f;

uniform float3 land_color < string ui_type = "color";
	string ui_label = "Land Color";
	string ui_category = "Water Effect";
> = float3(0.6f, 0.38f, 0.12f);

uniform float3 deep_ocean_color < string ui_type = "color";
	string ui_label = "deep_ocean_color";
	string ui_category = "Water Effect";
> = float3(0.05f, 0.05f, 0.3f);

//extra render targets
texture show_water { Width = YRBUFFER_WIDTH ; Height = YRBUFFER_HEIGHT; Format = RGBA8; };
texture final_picked_water { Width = YRBUFFER_WIDTH ; Height = YRBUFFER_HEIGHT; Format = RGBA8; };
texture water_alpha { Width = YRBUFFER_WIDTH; Height = YRBUFFER_HEIGHT; Format = RGBA8; };
texture show_surface { Width = YRBUFFER_WIDTH; Height = YRBUFFER_HEIGHT; Format = RGBA8; };
texture ratio_texture { Width = YRBUFFER_WIDTH; Height = YRBUFFER_HEIGHT; Format = RGBA8; };
sampler water_samp { Texture = show_water; };
sampler final_water_samp { Texture = final_picked_water; };
sampler water_alpha_samp { Texture = water_alpha; };
sampler show_surf { Texture = show_surface; AddressU = Wrap; AddressV = Wrap; };
sampler ratio { Texture = ratio_texture; AddressU = Wrap; AddressV = Wrap; };

float3 unpack_norm(float3 clr)
{
    clr.xy = clr.xy * 2.0f - 1.0f.xx;
    return clr;
}

float3 pack_norm(float3 nrm)
{
    nrm.xy = nrm.xy * 0.5f + 0.5f.xx;
    return nrm;
}

float gaussian_distribution(float2 c)
{
    const float pi = 3.141592653589793268f;
    const float first_part = (0.5f / pi / pow(sigma, 2.0f));
    
    float second_part = exp(-dot(c, c) * 0.5f / pow(sigma, 2.0f));
    return first_part * second_part;
};

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

float triangle_interpolation(float2 a, float2 b, float2 c, float2 p, float valuea, float valueb, float valuec)
{
    float alph = (-(p.x - b.x) * (c.y - b.y) + (p.y - b.y) * (c.x - b.x)) / (-(a.x - b.x) * (c.y * c.y) + (a.y - b.y) * (c.x - b.x));
    float beta = (-(p.x - c.x) * (a.y - c.y) + (p.y - c.y) * (a.x - c.x)) / (-(b.x - c.x) * (a.y - c.y) + (b.y - c.y) * (a.x - c.x));
    float gamma = 1 - alph - beta;
    
    return valuea * alph + valueb * beta + valuec * gamma;
}

vector ratioCalPS(in float2 texcoord : TEXCOORD) : SV_Target
{
    float3 color_orig = tex2D(water_samp, texcoord).rgb;
    float3 color_depth = tex2D(depth_map, texcoord + YRBUFFER_PIXEL_SIZE * surface_offsets).rgb;
    
    if(any(color_orig))
        return vector((length(color_depth) / length(color_orig)).xxx, 1.0f);
    
    return 1.0f.xxxx;
}

vector showPS(in float2 texcoord : TEXCOORD) : SV_Target
{
    static const float2 cell_dimension = float2(30.0f, 15.0f);
    static const float2 water_dimension = YRBUFFER_DIMENSION;
    static const float2 water_pixel_sz = YRBUFFER_PIXEL_SIZE;
    static const float2 pixel_step = float2(10.0f, 5.0f);
    
    float total_weight = 0.0f;
    float total_alpha = 0.0f;
    
    for (float x = -30.0f; x <= 30.0f; x += pixel_step.x)
    {
        for (float y = -15.0f; y <= 15.0f; y += pixel_step.y)
        {
            float2 offset = float2(x, y);
            float2 current_texcrd = texcoord + offset * water_pixel_sz;
            if (current_texcrd.x < 0.0f || current_texcrd.x > 1.0f || current_texcrd.y < 0.0f || current_texcrd.y > 1.0f)
                continue;
            
            float weight = gaussian_distribution(offset);
            float alpha = tex2Dlod(ratio, vector(current_texcrd, 0.0f.xx)).r;
            total_weight += weight;
            total_alpha += weight * alpha;
        }
    }

    return vector((total_alpha / total_weight).xxx, 1.0f);
}

//vector waterpickPS(float2 texcoord : TEXCOORD) : SV_Target
//{
//    vector orig_color = tex2D(water, texcoord);
//    vector back_color = tex2D(backbuffer, bufferpos2screenpos(SCREEN_DIMENSION, texcoord));
//    float dis = distance(orig_color.rgb, water_color);
//    float hue_dis = abs(RGBtoHSV(water_color).r - RGBtoHSV(orig_color.rgb).r);
    
//    if (dis < allowed_eu_distance && any(orig_color.rgb) && hue_dis < allowed_phase_distance)
//        return lerp(orig_color, 0.0f.xxxx, dis / allowed_eu_distance * hue_dis / allowed_phase_distance);

//    return 0.0f.xxxx;
//}

vector finalwaterpickPS(float2 texcoord : TEXCOORD) : SV_Target
{
    vector orig_color = tex2D(water_samp, texcoord);
    vector back_color = tex2D(backbuffer, bufferpos2screenpos(SCREEN_DIMENSION, texcoord));
    float cover_dis = distance(orig_color.rgb, back_color.rgb);
    
    if (any(orig_color.rgb) && cover_dis < game_obj_cover_judge)
        return tex2D(water, texcoord);
    return 0.0f.xxxx;
}

vector waterblurPS(float2 texcoord : TEXCOORD) : SV_Target
{
    float2 pix_size = YRBUFFER_PIXEL_SIZE;
    float total_weight = 0.0f;
    float total_alpha = 0.0f;
    
    [loop]
    for (int y = -10; y <= 10; y += 2)
    {
        [loop]
        for (int x = -10; x <= 10; x += 2)
        {
            float weight = gaussian_distribution(float2(x, y));
            float alpha = tex2Dlod(final_water_samp, vector(texcoord + pix_size * float2(x, y), 0.0f.xx)).a;
            total_weight += weight;
            total_alpha += alpha * weight;
        }
    }

    return vector((total_alpha / total_weight).xxx, 1.0f);
}

float3 wave_sample(float2 texcoord)
{
    float2 pixel_coords = texcoord / YRBUFFER_PIXEL_SIZE;
    float2 cld_off = float2(1.0f, 1.0f / sqrt(3.0f)) * (ms_timer / wave_speed_ratio);
    float2 cld_off2 = cld_off * float2(0.85f, -0.44f) * 1.63f;
    float2 cld_off3 = cld_off * float2(-0.72f, -0.43f) * 0.55f;
    float2 cld_off4 = cld_off * float2(-0.37f, 0.99f) * 2.61f;
    
    float2 cld_dimension = float2(WATER_TEXTURE_WIDTH, WATER_TEXTURE_HEIGHT / 2.0f);
    
    float2 cldcoord = pixel_coords / cld_dimension + cld_off;
    float2 cldcoord2 = pixel_coords / cld_dimension + cld_off2;
    float2 cldcoord3 = pixel_coords / cld_dimension + cld_off3;
    float2 cldcoord4 = pixel_coords / cld_dimension + cld_off4;
    
    float2 top_crd = topcrd / cld_dimension;
	
    cldcoord += top_crd;
    cldcoord /= water_magnification;
    cldcoord2 += top_crd;
    cldcoord2 /= water_magnification * 0.74f;
    cldcoord3 += top_crd;
    cldcoord3 /= water_magnification * 1.43f;
    cldcoord4 += top_crd;
    cldcoord4 /= water_magnification * 2.35f;
    
    float3 norm1 = tex2D(wave_sampler, cldcoord).rgb;
    float3 norm2 = tex2D(wave_sampler, cldcoord2).rgb;
    float3 norm3 = tex2D(wave_sampler, cldcoord3).rgb;
    float3 norm4 = tex2D(wave_sampler, cldcoord4).rgb;
    
    return unpack_norm(norm1) + unpack_norm(norm2) + unpack_norm(norm3) + unpack_norm(norm4);
}

vector blendPS(in float2 texcoord : TEXCOORD) : SV_Target
{
    static const float2 buffer_bound = YRBUFFER_DIMENSION / SCREEN_DIMENSION;
    static const float3 game_look = float3(1.0f.xx, sqrt(2.0f) / sqrt(3.0f));
    static const float3 sunlight = float3(0.0f, 0.0f, -sqrt(3.0f));
    
    float2 bufferpos = screenpos2bufferpos(SCREEN_DIMENSION, texcoord);
    vector orig_color = tex2D(backbuffer, texcoord);
    float top = tex2D(topmask, texcoord).r;
    vector water_data = tex2D(final_water_samp, bufferpos);
    vector alpha_data = tex2D(water_alpha_samp, bufferpos);
    
    if (is_in_game == 0.0f || top != 0.0f || !any(water_data))
        return orig_color;
    
    if (texcoord.x < buffer_bound.x && texcoord.y < buffer_bound.y)
    {
        float3 normal = wave_sample(bufferpos + YRBUFFER_PIXEL_SIZE * surface_offsets);
        normal.xy = float2(normal.y - normal.x, normal.x + normal.y) / sqrt(2.0f);
        
        normal = normalize(normal);
        float3 reflected_light = reflect(sunlight, normal);
        float spec_color_coeff = pow(max(dot(normalize(reflected_light), normalize(game_look)), 0.0f), water_reflection_coeff);
       
        float depth_alpha = tex2D(show_surf, bufferpos).r;
        orig_color.rgb = lerp(orig_color.rgb, land_color, depth_alpha * maximum_land_coeff);
        orig_color.rgb *= lerp(deep_ocean_color, 1.0f.xxx, depth_alpha);
        orig_color.rgb *= water_diffuse_coeff * max(dot(normal, normalize(-sunlight)), 0.0f);
        orig_color.rgb += water_spec_coeff * tex2D(sky_sampler, bufferpos * float2(0.5f, 1.0f)).rgb * spec_color_coeff * alpha_data.r;
        
        return orig_color;
    }
    
    return orig_color;
}

vector show_waterPS(float2 texcoord : TEXCOORD) : COLOR
{
    return tex2D(water, texcoord + YRBUFFER_PIXEL_SIZE * surface_offsets);
}

technique ShowWaterDepthMap
{
    pass
    {
        PixelShader = show_waterPS;
        VertexShader = PostProcessVS;
        RenderTarget = show_water;
    }
    pass 
    {
        PixelShader = finalwaterpickPS;
        VertexShader = PostProcessVS;
        RenderTarget = final_picked_water;
    }

    pass 
    {
        PixelShader = waterblurPS;
        VertexShader = PostProcessVS;
        RenderTarget = water_alpha;
    }

    pass
    {
        PixelShader = ratioCalPS;
        VertexShader = PostProcessVS;
        RenderTarget = ratio_texture;
    }

    pass
    {
        PixelShader = showPS;
        VertexShader = PostProcessVS;
        RenderTarget = show_surface;
    }

    pass
    {
        PixelShader = blendPS;
        VertexShader = PostProcessVS;
    }
}