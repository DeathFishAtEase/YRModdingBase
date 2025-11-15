static const float Epsilon = 1e-10;
static const float pi = 3.1415926536;

//颜色计算灰度
float color2grayscale(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
    //return 0.1;
}

//由于zbuffer/abuffer大小和窗口不一样，因此在采样对应abuffer时需要变换屏幕坐标
//将一个像素在游戏窗口中的相对坐标转换为此像素在ZBuffer、ABuffer、扭曲贴图渲染目标（均为宽-168，高-32）的相对坐标
//window_dimension为窗口大小
float2 screenpos2bufferpos(float2 window_dimension, float2 coords_in_screen)
{
    float2 buffer_dimension = window_dimension.xy - float2(168.0f, 32.0f);
    float2 pixel_unit_screen = 1.0f.xx / (window_dimension.xy - 1.0f.xx);
    float2 pixel_unit_buffer = 1.0f.xx / (buffer_dimension.xy - 1.0f.xx);
    float2 pixel_number = coords_in_screen / pixel_unit_screen;
    return pixel_number * pixel_unit_buffer;
}

//与screenpos2bufferpos相反
//window_dimension为窗口大小
float2 bufferpos2screenpos(float2 window_dimension, float2 coords_in_buffer)
{
    float2 buffer_dimension = window_dimension.xy - float2(168.0f, 32.0f);
    float2 pixel_unit_screen = 1.0f.xx / (window_dimension.xy - 1.0f.xx);
    float2 pixel_unit_buffer = 1.0f.xx / (buffer_dimension.xy - 1.0f.xx);
    float2 pixel_number = coords_in_buffer / pixel_unit_buffer;
    return pixel_number * pixel_unit_screen;
}

//游戏中直接将z/abuffer的16位的颜色值拷贝入贴图内，而shader中变为0~1的颜色分量，因此需要进行转换得到原16位值
int buffer_value_convertion(vector value)
{ /*
    int rvalue = ceil(value.r * 31) * 32 * 64;
    int gvalue = ceil(value.g * 63) * 32;
    int bvalue = value.b * 31;*/

    return /*rvalue + gvalue + bvalue*/value.x * 65535;
}

float3 RGBtoHCV(in float3 RGB)
{
    // Based on work by Sam Hocevar and Emil Persson
    float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0 / 3.0) : float4(RGB.gb, 0.0, -1.0 / 3.0);
    float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
    return float3(H, C, Q.x);
}

float3 RGBtoHSV(in float3 RGB)
{
    float3 HCV = RGBtoHCV(RGB);
    float S = HCV.y / (HCV.z + Epsilon);
    return float3(HCV.x, S, HCV.z);
}

float3 HUEtoRGB(in float H)
{
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    return saturate(float3(R, G, B));
}

float3 HSVtoRGB(in float3 HSV)
{
    float3 RGB = HUEtoRGB(HSV.x);
    return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

#include "noise.hlsl"
