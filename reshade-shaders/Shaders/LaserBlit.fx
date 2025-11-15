#include "ReshadeUIK.fxh"
#include "ReshadeK.fxh"

texture DistortTex : DISTORT;
sampler Distort
{
    Texture = DistortTex;
};

uniform bool currently_in_game <
    string source = "is_in_game";
>;

float color2grayscale(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
    //return 0.1;
}

vector pmain(float2 texcoord : TEXCOORD) : COLOR
{
    vector orig_color = tex2D(ReShade::BackBuffer, texcoord);
    float top = tex2D(ReShade::TopMask, texcoord).r;
    
    if (!currently_in_game)
        return saturate(orig_color);
    
    if (top == 0.0f && 
        texcoord.x < BUFFER_PIXEL_SIZE.x * (BUFFER_WIDTH - 168) &&
        texcoord.y < BUFFER_PIXEL_SIZE.y * (BUFFER_HEIGHT - 32))
    {
        float2 zcoord = texcoord * float2(float(BUFFER_WIDTH) / (BUFFER_WIDTH - 168), float(BUFFER_HEIGHT) / (BUFFER_HEIGHT - 32));
        float2 bump = tex2D(Distort, zcoord).xy;
        
        //if (!any(ceil(255.0 * bump) - float2(128.0, 128.0)) || !any(floor(255.0 * bump) - float2(128.0, 128.0)))
        //    bump = float2(0.5, 0.5);
        
        float2 final_uv = texcoord + (2.0 * bump - float2(1.0, 1.0));
        //float2 final_color_uv = final_uv * float2(float(BUFFER_WIDTH - 168) / (BUFFER_WIDTH), float(BUFFER_HEIGHT - 32) / (BUFFER_HEIGHT));
        orig_color = tex2D(ReShade::BackBuffer, final_uv);
        return saturate(vector(orig_color.rgb, 1.0f));
    }
    
    return saturate(orig_color);
}

technique BlitLaser
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = pmain;
    }
}