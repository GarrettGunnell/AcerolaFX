#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform int _KernelSize <
    ui_min = 1; ui_max = 10;
    ui_type = "slider";
    ui_label = "Kernel Size";
    ui_tooltip = "Size of the blur kernel";
> = 2;

uniform float _Sigma <
    ui_min = 0.0; ui_max = 5.0f;
    ui_type = "slider";
    ui_label = "Blur Strength";
    ui_tooltip = "Sigma of the gaussian function (used for Gaussian blur)";
> = 2.0f;

uniform float _SigmaScale <
    ui_min = 0.0; ui_max = 5.0f;
    ui_type = "slider";
    ui_label = "Deviation Scale";
    ui_tooltip = "scale between the two gaussian blurs";
> = 1.6f;

uniform float _Tau <
    ui_min = 0.0; ui_max = 1.1f;
    ui_type = "slider";
    ui_label = "Detail";
> = 1.0f;

uniform float _Threshold <
    ui_min = 0.001; ui_max = 0.1f;
    ui_type = "slider";
    ui_label = "Threshold";
> = 0.005f;

uniform bool _ViewDog <
    ui_label = "View DoG";
    ui_tooltip = "View difference of gaussians preprocess";
> = false;

uniform bool _ViewUncompressed <
    ui_label = "View Uncompressed";
    ui_tooltip = "View uncompressed edge direction data";
> = false;

uniform int _EdgeThreshold <
    ui_min = 0; ui_max = 64;
    ui_type = "slider";
    ui_label = "Edge Threshold";
    ui_tooltip = "how many pixels in an 8x8 grid need to be detected as an edge for an edge to be filled in.";
> = 8;

uniform bool _Edges <
    ui_label = "Draw Edges";
    ui_tooltip = "draw ASCII edges";
> = true;

uniform bool _Fill <
    ui_label = "Draw Fill";
    ui_tooltip = "fill screen with ASCII characters";
> = true;

float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * AFX_PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

texture2D AFX_ASCIIEdgesLUT < source = "edgesASCII.png"; > { Width = 40; Height = 8; };
sampler2D EdgesASCII { Texture = AFX_ASCIIEdgesLUT; AddressU = REPEAT; AddressV = REPEAT; };


texture2D AFX_ASCIIFillLUT < source = "fillASCII.png"; > { Width = 80; Height = 8; };
sampler2D FillASCII { Texture = AFX_ASCIIFillLUT; AddressU = REPEAT; AddressV = REPEAT; };

texture2D AFX_LuminanceAsciiTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
sampler2D Luminance { Texture = AFX_LuminanceAsciiTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

texture2D AFX_DownscaleLuminanceAsciiTex { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = R16F; };
sampler2D LuminanceDownscale { Texture = AFX_DownscaleLuminanceAsciiTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

texture2D AFX_AsciiPingTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler2D AsciiPing { Texture = AFX_AsciiPingTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

texture2D AFX_AsciiDogTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
sampler2D DoG { Texture = AFX_AsciiDogTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

texture2D AFX_AsciiSobelTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler2D Sobel { Texture = AFX_AsciiSobelTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

sampler2D ASCII { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_ASCII { Texture = AFXTemp1::AFX_RenderTex1; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(ASCII, uv).rgba; }

float PS_Luminance(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Common::Luminance(saturate(tex2D(Common::AcerolaBuffer, uv).rgb));
}

float4 PS_HorizontalBlur(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float2 blur = 0;
    float2 kernelSum = 0;

    for (int x = -_KernelSize; x <= _KernelSize; ++x) {
        float2 luminance = tex2D(Luminance, uv + float2(x, 0) * texelSize).r;
        float2 gauss = float2(gaussian(_Sigma, x), gaussian(_Sigma * _SigmaScale, x));

        blur += luminance * gauss;
        kernelSum += gauss;
    }

    blur /= kernelSum;

    return float4(blur, 0, 0);
}

float PS_VerticalBlurAndDifference(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float2 blur = 0;
    float2 kernelSum = 0;

    for (int y = -_KernelSize; y <= _KernelSize; ++y) {
        float2 luminance = tex2D(AsciiPing, uv + float2(0, y) * texelSize).rg;
        float2 gauss = float2(gaussian(_Sigma, y), gaussian(_Sigma * _SigmaScale, y));

        blur += luminance * gauss;
        kernelSum += gauss;
    }

    blur /= kernelSum;

    float D = (blur.x - _Tau * blur.y);

    D = (D >= _Threshold) ? 1 : 0;

    return D;
}

float4 PS_HorizontalSobel(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float lum1 = tex2D(DoG, uv - float2(1, 0) * texelSize).r;
    float lum2 = tex2D(DoG, uv).r;
    float lum3 = tex2D(DoG, uv + float2(1, 0) * texelSize).r;

    float Gx = 3 * lum1 + 0 * lum2 + -3 * lum3;
    float Gy = 3 + lum1 + 10 * lum2 + 3 * lum3;

    return float4(Gx, Gy, 0, 0);
}

float2 PS_VerticalSobel(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 texelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float2 grad1 = tex2D(AsciiPing, uv - float2(0, 1) * texelSize).rg;
    float2 grad2 = tex2D(AsciiPing, uv).rg;
    float2 grad3 = tex2D(AsciiPing, uv + float2(0, 1) * texelSize).rg;

    float Gx = 3 * grad1.x + 10 * grad2.x + 3 * grad3.x;
    float Gy = 3 * grad1.y + 0 * grad2.y + -3 * grad3.y;

    float2 G = float2(Gx, Gy);
    G = normalize(G);

    float magnitude = length(float2(Gx, Gy));
    float theta = atan2(G.y, G.x);

    // if ((-3.0f * PI / 5.0f) < theta && theta < (-2.0 * PI / 5)) theta = 1;
    // else theta = 0;
    return float2(theta, 1 - isnan(theta));
}

groupshared int edgeCount[64];
void CS_RenderASCII(uint3 tid : SV_DISPATCHTHREADID, uint3 gid : SV_GROUPTHREADID) {
    float grid = ((gid.y == 0) + (gid.x == 0)) * 0.25f;

    float2 sobel = tex2Dfetch(Sobel, tid.xy).rg;

    float theta = sobel.r;
    float absTheta = abs(theta) / AFX_PI;

    int direction = -1;

    if (any(sobel.g)) {
        if ((0.0f <= absTheta) && (absTheta < 0.05f)) direction = 0; // VERTICAL
        else if ((0.9f < absTheta) && (absTheta <= 1.0f)) direction = 0;
        else if ((0.45f < absTheta) && (absTheta < 0.55f)) direction = 1; // HORIZONTAL
        else if (0.05f < absTheta && absTheta < 0.45f) direction = sign(theta) > 0 ? 3 : 2; // DIAGONAL 1
        else if (0.55f < absTheta && absTheta < 0.9f) direction = sign(theta) > 0 ? 2 : 3; // DIAGONAL 2
    }

    // Set group thread bucket to direction
    edgeCount[gid.x + gid.y * 8] = direction;

    barrier();

    int commonEdgeIndex = -1;
    if ((gid.x == 0) && (gid.y == 0)) {
        uint buckets[4] = {0, 0, 0, 0};

        // Count up directions in tile
        for (int i = 0; i < 64; ++i) {
            buckets[edgeCount[i]] += 1;
        }

        uint maxValue = 0;

        // Scan for most common edge direction (max)
        for (int j = 0; j < 4; ++j) {
            if (buckets[j] > maxValue) {
                commonEdgeIndex = j;
                maxValue = buckets[j];
            }
        }

        // Discard edge info if not enough edge pixels in tile
        if (maxValue < _EdgeThreshold) commonEdgeIndex = -1;

        edgeCount[0] = commonEdgeIndex;
    }

    barrier();

    commonEdgeIndex = _ViewUncompressed ? direction : edgeCount[0];

    float4 quantizedEdge = (commonEdgeIndex + 1) * 8;

    float3 ascii = 0;

    if (saturate(commonEdgeIndex + 1) && _Edges) {
        float2 localUV;
        localUV.x = ((tid.x % 8)) + quantizedEdge.x;
        localUV.y = 8 - (tid.y % 8);

        ascii = tex2Dfetch(EdgesASCII, localUV).r;
    } else if (_Fill) {
        uint2 luminanceID = tid.xy / 8;

        float luminance = (tex2Dfetch(LuminanceDownscale, luminanceID).r);

        luminance = max(0, (floor(luminance * 10) - 1)) / 10.0f;
        
        float2 localUV;
        localUV.x = ((tid.x % 8)) + luminance * 80;
        localUV.y = (tid.y % 8);

        ascii = tex2Dfetch(FillASCII, localUV).r;
    }

    float3 debugEdge = 0;
    if (commonEdgeIndex == 0) debugEdge = float3(1, 0, 0);
    if (commonEdgeIndex == 1) debugEdge = float3(0, 1, 0);
    if (commonEdgeIndex == 2) debugEdge = float3(0, 1, 1);
    if (commonEdgeIndex == 3) debugEdge = float3(1, 1, 0);

    if (_ViewDog) ascii = tex2Dfetch(DoG, tid.xy).r;

    tex2Dstore(s_ASCII, tid.xy, float4(ascii, 1.0f));
}

technique AFX_ASCII < ui_label = "ASCII"; > {
    pass {
        RenderTarget = AFX_LuminanceAsciiTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Luminance;
    }

        pass {
        RenderTarget = AFX_DownscaleLuminanceAsciiTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Luminance;
    }
    
    pass {
        RenderTarget = AFX_AsciiPingTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_HorizontalBlur;
    }

    pass {
        RenderTarget = AFX_AsciiDogTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_VerticalBlurAndDifference;
    }

    pass {
        RenderTarget = AFX_AsciiPingTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_HorizontalSobel;
    }

    pass {
        RenderTarget = AFX_AsciiSobelTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_VerticalSobel;
    }

    pass {
        ComputeShader = CS_RenderASCII<8, 8>;
        DispatchSizeX = BUFFER_WIDTH / 8;
        DispatchSizeY = BUFFER_HEIGHT / 8;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}