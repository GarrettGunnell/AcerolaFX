#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

#ifndef AFX_HORIZONTAL_SORT
 #define AFX_HORIZONTAL_SORT 0
#endif

uniform float _LowThreshold <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_min = 0.0f; ui_max = 0.5f;
    ui_label = "Low Threshold";
    ui_type = "slider";
    ui_tooltip = "Adjust the threshold at which dark pixels are omitted from the mask.";
> = 0.4f;

uniform float _HighThreshold <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_min = 0.5f; ui_max = 1.0f;
    ui_label = "High Threshold";
    ui_type = "slider";
    ui_tooltip = "Adjust the threshold at which bright pixels are omitted from the mask.";
> = 0.72f;

uniform bool _InvertMask <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_label = "Invert Mask";
    ui_tooltip = "Invert sorting mask.";
> = false;

uniform float _MaskRandomOffset <
    ui_category_closed = true;
    ui_category = "Mask Settings";
    ui_min = -0.01f; ui_max = 0.01f;
    ui_label = "Random Offset";
    ui_type = "drag";
    ui_tooltip = "Adjust the random offset of each segment to reduce uniformity.";
> = 0.0f;

//uniform float _FrameTime < source = "frametime"; >;

sampler2D PixelSort { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(PixelSort, uv).rgba; }

float hash(uint n) {
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
    return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
}

void CS_CreateMask(uint3 id : SV_DispatchThreadID) {
    float2 pixelSize = float2(BUFFER_RCP_HEIGHT, BUFFER_RCP_WIDTH);

    #if AFX_HORIZONTAL_SORT == 0
    uint seed = id.x * BUFFER_WIDTH;
    #else
    uint seed = id.y * BUFFER_HEIGHT;
    #endif

    float rand = hash(seed) * _MaskRandomOffset;

    float2 uv = id.xy / float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    #if AFX_HORIZONTAL_SORT == 0
    uv.y += rand;
    #else
    uv.x += rand;
    #endif

    float4 col = saturate(tex2Dlod(Common::AcerolaBuffer, float4(uv, 0, 0)));

    float l = Common::Luminance(col.rgb);

    int result = 1;
    if (l < _LowThreshold || _HighThreshold < l)
        result = 0;
    
    tex2Dstore(AFXTemp1::s_RenderTex, id.xy, _InvertMask ? 1 - result : result);
}


technique AFX_PixelSort < ui_label = "Pixel Sort"; ui_tooltip = "(EXTREMELY HIGH PERFORMANCE COST) Sort the game pixels."; > {
    pass {
        ComputeShader = CS_CreateMask<8, 8>;
        DispatchSizeX = BUFFER_WIDTH / 8;
        DispatchSizeY = BUFFER_HEIGHT / 8;
    }


    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}