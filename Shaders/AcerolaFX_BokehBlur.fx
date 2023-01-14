#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform float _FocalPlaneDistance <
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Focal Plane";
    ui_type = "slider";
    ui_tooltip = "Adjust distance at which detail is sharp.";
> = 40.0f;

uniform float _FocusRange <
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Focus Range";
    ui_type = "slider";
    ui_tooltip = "Adjust range at which detail is sharp around the focal plane.";
> = 20.0f;

uniform int _KernelSize <
    ui_category = "Kernel Settings";
    ui_category_closed = true;
    ui_min = 1; ui_max = 13;
    ui_label = "Kernel Size";
    ui_type = "slider";
    ui_tooltip = "Size of bokeh kernel";
> = 6;

uniform int _Theta <
    ui_category = "Kernel Settings";
    ui_category_closed = true;
    ui_min = -180; ui_max = 180;
    ui_label = "Kernel Rotation";
    ui_type = "slider";
    ui_tooltip = "Rotation of kernel in first blur pass.";
> = 0;

uniform int _Theta2 <
    ui_category = "Kernel Settings";
    ui_category_closed = true;
    ui_min = -180; ui_max = 180;
    ui_label = "Kernel Rotation 2";
    ui_type = "slider";
    ui_tooltip = "Rotation of kernel in second blur pass.";
> = 90;

uniform int _Theta3 <
    ui_category = "Kernel Settings";
    ui_category_closed = true;
    ui_min = -180; ui_max = 180;
    ui_label = "Kernel Rotation 3";
    ui_type = "slider";
    ui_tooltip = "Rotation of kernel in third blur pass.";
> = 0;

uniform int _Theta4 <
    ui_category = "Kernel Settings";
    ui_category_closed = true;
    ui_min = -180; ui_max = 180;
    ui_label = "Kernel Rotation 4";
    ui_type = "slider";
    ui_tooltip = "Rotation of kernel in fourth blur pass.";
> = 90;

uniform bool _Fill <
    ui_category = "Kernel Settings";
    ui_category_closed = true;
    ui_label = "Fill";
    ui_tooltip = "Attempt to fill in undersampling of kernel.";
> = true;

uniform float _Strength <
    ui_min = 0.0f; ui_max = 3.0f;
    ui_label = "Strength";
    ui_type = "drag";
    ui_tooltip = "Adjust strength of the depth of field.";
> = 1.0f;

texture2D AFX_CoC { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG8; };
sampler2D CoC { Texture = AFX_CoC; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};

texture2D AFX_QuarterColor { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D QuarterColor { Texture = AFX_QuarterColor; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D QuarterColorLinear { Texture = AFX_QuarterColor; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_NearBlur { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D NearBlur { Texture = AFX_NearBlur; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D NearBlurLinear { Texture = AFX_NearBlur; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_FarBlur { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D FarBlur { Texture = AFX_FarBlur; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D FarBlurLinear { Texture = AFX_FarBlur; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_NearFill { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D NearFill { Texture = AFX_NearFill; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D NearFillLinear { Texture = AFX_NearFill; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_FarFill { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D FarFill { Texture = AFX_FarFill; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D FarFillLinear { Texture = AFX_FarFill; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_NearBlend { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D NearBlend { Texture = AFX_NearBlend; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D NearBlendLinear { Texture = AFX_NearBlend; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_FarBlend { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D FarBlend { Texture = AFX_FarBlend; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D FarBlendLinear { Texture = AFX_FarBlend; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_QuarterCoC { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RG8; };
sampler2D QuarterCoC { Texture = AFX_QuarterCoC; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D QuarterCoCLinear { Texture = AFX_QuarterCoC; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_QuarterFarColor { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D QuarterFarColor { Texture = AFX_QuarterFarColor; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D QuarterFarColorLinear { Texture = AFX_QuarterFarColor; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_NearCoCBlur { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = R8; };
sampler2D NearCoCBlur { Texture = AFX_NearCoCBlur; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D NearCoCBlurLinear { Texture = AFX_NearCoCBlur; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

texture2D AFX_QuarterPing { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16; };
sampler2D QuarterPing { Texture = AFX_QuarterPing; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
sampler2D QuarterPingLinear { Texture = AFX_QuarterPing; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};

sampler2D Bokeh { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_Bokeh { Texture = AFXTemp1::AFX_RenderTex1; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Bokeh, uv).rgba; }

static const float2 offsets[] =
{
	2.0f * float2(1.000000f, 0.000000f),
	2.0f * float2(0.707107f, 0.707107f),
	2.0f * float2(-0.000000f, 1.000000f),
	2.0f * float2(-0.707107f, 0.707107f),
	2.0f * float2(-1.000000f, -0.000000f),
	2.0f * float2(-0.707106f, -0.707107f),
	2.0f * float2(0.000000f, -1.000000f),
	2.0f * float2(0.707107f, -0.707107f),
	
	4.0f * float2(1.000000f, 0.000000f),
	4.0f * float2(0.923880f, 0.382683f),
	4.0f * float2(0.707107f, 0.707107f),
	4.0f * float2(0.382683f, 0.923880f),
	4.0f * float2(-0.000000f, 1.000000f),
	4.0f * float2(-0.382684f, 0.923879f),
	4.0f * float2(-0.707107f, 0.707107f),
	4.0f * float2(-0.923880f, 0.382683f),
	4.0f * float2(-1.000000f, -0.000000f),
	4.0f * float2(-0.923879f, -0.382684f),
	4.0f * float2(-0.707106f, -0.707107f),
	4.0f * float2(-0.382683f, -0.923880f),
	4.0f * float2(0.000000f, -1.000000f),
	4.0f * float2(0.382684f, -0.923879f),
	4.0f * float2(0.707107f, -0.707107f),
	4.0f * float2(0.923880f, -0.382683f),

	6.0f * float2(1.000000f, 0.000000f),
	6.0f * float2(0.965926f, 0.258819f),
	6.0f * float2(0.866025f, 0.500000f),
	6.0f * float2(0.707107f, 0.707107f),
	6.0f * float2(0.500000f, 0.866026f),
	6.0f * float2(0.258819f, 0.965926f),
	6.0f * float2(-0.000000f, 1.000000f),
	6.0f * float2(-0.258819f, 0.965926f),
	6.0f * float2(-0.500000f, 0.866025f),
	6.0f * float2(-0.707107f, 0.707107f),
	6.0f * float2(-0.866026f, 0.500000f),
	6.0f * float2(-0.965926f, 0.258819f),
	6.0f * float2(-1.000000f, -0.000000f),
	6.0f * float2(-0.965926f, -0.258820f),
	6.0f * float2(-0.866025f, -0.500000f),
	6.0f * float2(-0.707106f, -0.707107f),
	6.0f * float2(-0.499999f, -0.866026f),
	6.0f * float2(-0.258819f, -0.965926f),
	6.0f * float2(0.000000f, -1.000000f),
	6.0f * float2(0.258819f, -0.965926f),
	6.0f * float2(0.500000f, -0.866025f),
	6.0f * float2(0.707107f, -0.707107f),
	6.0f * float2(0.866026f, -0.499999f),
	6.0f * float2(0.965926f, -0.258818f),
};

float DepthNDCToView(float depth_ndc) {
    float zNear = 1.0f;
    float zFar = 1000.0f;

    float2 projParams = float2(zFar / (zNear - zFar), zNear * zFar / (zNear - zFar));

    return -projParams.y / (depth_ndc + projParams.x);
}

float4 PS_CoC(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float nearBegin = max(0.0f, _FocalPlaneDistance - _FocusRange);
    float nearEnd = _FocalPlaneDistance;
    float farBegin = _FocalPlaneDistance;
    float farEnd = _FocalPlaneDistance + _FocusRange;
    
    float depth = -DepthNDCToView(tex2D(ReShade::DepthBuffer, uv).r);

    float nearCOC = 0.0f;
    if (depth < nearEnd)
        nearCOC = 1.0f / (nearBegin - nearEnd) * depth + -nearEnd / (nearBegin - nearEnd);
    else if (depth < nearBegin)
        nearCOC = 1.0f;

    float farCOC = 1.0f;
    if (depth < farBegin)
        farCOC = 0.0f;
    else if (depth < farEnd)
        farCOC = 1.0f / (farEnd - farBegin) * depth + -farBegin / (farEnd - farBegin);
    
    return saturate(float4(nearCOC, farCOC, 0.0f, 1.0f));
}

float4 PS_DownscaleColor(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return float4(tex2D(Common::AcerolaBufferLinear, uv).rgb, 1.0f);
}

float4 PS_DownscaleCoC(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return tex2D(CoC, uv + float2(-0.25f, -0.25f) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT));
}

float4 PS_DownscaleFarColor(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 pixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    float2 coc = tex2D(CoC, uv + float2(-0.25f, -0.25f) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rg;

    float2 texCoord00 = uv + float2(-0.25f, -0.25f) * pixelSize;
	float2 texCoord10 = uv + float2( 0.25f, -0.25f) * pixelSize;
	float2 texCoord01 = uv + float2(-0.25f,  0.25f) * pixelSize;
	float2 texCoord11 = uv + float2( 0.25f,  0.25f) * pixelSize;

    float cocFar00 = tex2D(CoC, texCoord00).g;
    float cocFar10 = tex2D(CoC, texCoord10).g;
    float cocFar01 = tex2D(CoC, texCoord01).g;
    float cocFar11 = tex2D(CoC, texCoord11).g;

    float weight00 = 1000.0f;
	float4 colorMulCOCFar = weight00 * tex2D(Common::AcerolaBuffer, texCoord00);
	float weightsSum = weight00;
	
	float weight10 = 1.0f / (abs(cocFar00 - cocFar10) + 0.001f);
	colorMulCOCFar += weight10 * tex2D(Common::AcerolaBuffer, texCoord10);
	weightsSum += weight10;
	
	float weight01 = 1.0f / (abs(cocFar00 - cocFar01) + 0.001f);
	colorMulCOCFar += weight01 * tex2D(Common::AcerolaBuffer, texCoord01);
	weightsSum += weight01;
	
	float weight11 = 1.0f / (abs(cocFar00 - cocFar11) + 0.001f);
	colorMulCOCFar += weight11 * tex2D(Common::AcerolaBuffer, texCoord11);
	weightsSum += weight11;

	colorMulCOCFar /= weightsSum;
	colorMulCOCFar *= coc.g;

    return float4(colorMulCOCFar.rgb, 1.0f);
}

float2 PS_MaxCoCX(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float cocMax = tex2D(QuarterCoC, uv).r;
    
    for (int x = -6; x <= 6; ++x) {
        if (x == 0) continue;
        cocMax = max(cocMax, tex2D(QuarterCoC, uv + float2(x, 0) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).r);
    }
    return cocMax;
}

float PS_MaxCoCY(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float cocMax = tex2D(QuarterPing, uv).r;
    
    for (int y = -6; y <= 6; ++y) {
        if (y == 0) continue;
        cocMax = max(cocMax, tex2D(QuarterPing, uv + float2(0, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).r);
    }
    return cocMax;
}

float2 PS_BlurCoCX(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float coc = tex2D(NearCoCBlur, uv).r;
    
    for (int x = -6; x <= 6; ++x) {
        if (x == 0) continue;
        coc += tex2D(NearCoCBlur, uv + float2(x, 0) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).r;
    }

    return coc / 13;
}

float PS_BlurCoCY(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float coc = tex2D(QuarterPing, uv).r;
    
    for (int y = -6; y <= 6; ++y) {
        if (y == 0) continue;
        coc += tex2D(QuarterPing, uv + float2(0, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).r;
    }
    
    return coc / 13;
}

float4 Near(float2 uv, int rotation, sampler2D source) {
    int kernelSize = _KernelSize;
    float kernelScale = _Strength >= 0.25f ? _Strength : 0.25f;
    float cocNearBlurred = tex2D(NearCoCBlur, uv).r;
    
    float4 base = tex2D(source, uv);
    float4 col = base;

    float theta = radians(_Theta);
    float2x2 R = float2x2(float2(cos(theta), -sin(theta)), float2(sin(theta), cos (theta)));

    [loop]
    for (int x = -kernelSize; x <= kernelSize; ++x) {
        if (x == 0) continue;
        float2 offset = kernelScale * mul(R, float2(x, 0)) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
        col += tex2D(source, uv + offset);
    }
    
    if (cocNearBlurred > 0.0f) {
        return col / (_KernelSize * 2 + 1);
    } else {
        return base;
    }
}

float4 PS_NearBlurX(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Near(uv, _Theta, QuarterColorLinear);
}

float4 PS_NearBlurY(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Near(uv, _Theta, QuarterPingLinear);
}

float4 PS_NearBlurX2(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Near(uv, _Theta3, QuarterColorLinear);
}

float4 PS_NearBlurY2(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Near(uv, _Theta4, QuarterPingLinear);
}

float4 Far(float2 uv, int rotation, sampler2D source) {
    int kernelSize = _KernelSize;
    float kernelScale = _Strength >= 0.25f ? _Strength : 0.25f;
    
    float4 col = tex2D(source, uv);
    float weightsSum = tex2D(QuarterCoC, uv).y;

    float theta = radians(rotation);
    float2x2 R = float2x2(float2(cos(theta), -sin(theta)), float2(sin(theta), cos (theta)));

    [loop]
    for (int x = -kernelSize; x <= kernelSize; ++x) {
        if (x == 0) continue;
        float2 offset = kernelScale * mul(R, float2(x, 0)) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

        col += tex2D(source, uv + offset);
        weightsSum += tex2D(QuarterCoCLinear, uv + offset).g;
    }

    if (tex2D(QuarterCoC, uv).g > 0.1f) {
        return col / max(0.01f, weightsSum);
    } else {
        return 0.0f;
    }
}

float4 PS_FarBlurX(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Far(uv, _Theta, QuarterFarColorLinear);
}

float4 PS_FarBlurY(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Far(uv, _Theta2, QuarterPingLinear);
}

float4 PS_FarBlurX2(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Far(uv, _Theta3, QuarterFarColorLinear);
}

float4 PS_FarBlurY2(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return Far(uv, _Theta4, QuarterPingLinear);
}

float4 PS_CompositeNearKernel(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 n1 = tex2D(NearBlur, uv);
    float4 n2 = tex2D(NearFill, uv);
    return min(n1, n2);
}

float4 PS_CompositeFarKernel(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 f1 = tex2D(FarBlur, uv);
    float4 f2 = tex2D(FarFill, uv);
    return min(f1, f2);
}

float4 PS_NearFill(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float cocNearBlurred = tex2D(NearCoCBlur, uv).r;
    
    float4 col = tex2D(NearBlendLinear, uv);
    if (cocNearBlurred > 0.0f && _Fill) {
        [unroll]
        for (int x = -1; x <= -1; ++x) {
            [unroll]
            for (int y = -1; y <= -1; ++y) {
                col = max(col, tex2D(NearBlendLinear, uv + float2(x, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)));
            }
        }
    }

    return col;
}

float4 PS_FarFill(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float farCoC = tex2D(QuarterCoC, uv).g;
    
    float4 col = tex2D(FarBlendLinear, uv);
    if (farCoC > 0.0f && _Fill) {
        [unroll]
        for (int x = -1; x <= -1; ++x) {
            [unroll]
            for (int y = -1; y <= -1; ++y) {
                col = max(col, tex2D(FarBlendLinear, uv + float2(x, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)));
            }
        }
    }

    return col;
}

float4 PS_Composite(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 pixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float blend = _Strength >= 0.25f ? 1.0f : 4.0f * _Strength;

    float4 result = tex2D(Common::AcerolaBuffer, uv);

    float2 uv00 = uv;
    float2 uv10 = uv + float2(pixelSize.x, 0.0f);
    float2 uv01 = uv + float2(0.0f, pixelSize.y);
    float2 uv11 = uv + float2(pixelSize.x, pixelSize.y);

    float cocFar = tex2D(CoC, uv).g;
    float4 cocsFar_x4 = tex2DgatherG(QuarterCoC, uv00).wzxy;
    float4 cocsFarDiffs = abs(cocFar.xxxx - cocsFar_x4);

    float4 dofFar00 = tex2D(FarFillLinear, uv00);
    float4 dofFar10 = tex2D(FarFillLinear, uv10);
    float4 dofFar01 = tex2D(FarFillLinear, uv01);
    float4 dofFar11 = tex2D(FarFillLinear, uv11);


    float2 imageCoord = uv / pixelSize;
    float2 fractional = frac(imageCoord);
    float a = (1.0f - fractional.x) * (1.0f - fractional.y);
    float b = fractional.x * (1.0f - fractional.y);
    float c = (1.0f - fractional.x) * fractional.y;
    float d = fractional.x * fractional.y;

    float4 dofFar = 0.0f;
    float weightsSum = 0.0f;

    float weight00 = a / (cocsFarDiffs.x + 0.001f);
    dofFar += weight00 * dofFar00;
    weightsSum += weight00;

    float weight10 = b / (cocsFarDiffs.y + 0.001f);
    dofFar += weight10 * dofFar10;
    weightsSum += weight10;

    float weight01 = c / (cocsFarDiffs.z + 0.001f);
    dofFar += weight01 * dofFar01;
    weightsSum += weight01;

    float weight11 = d / (cocsFarDiffs.w + 0.001f);
    dofFar += weight11 * dofFar11;
    weightsSum += weight11;

    dofFar /= weightsSum;

    result = lerp(result, dofFar, blend * cocFar);

    float cocNear = tex2D(NearCoCBlurLinear, uv).r;
    float4 dofNear = tex2D(NearFillLinear, uv);

    result = lerp(result, dofNear, blend * cocNear);

    return result;
}

technique AFX_BokehBlur < ui_label = "Bokeh Blur"; ui_tooltip = "Simulate camera focusing."; > {
    pass {
        RenderTarget = AFX_CoC;

        VertexShader = PostProcessVS;
        PixelShader = PS_CoC;
    }

    pass {
        RenderTarget = AFX_QuarterColor;

        VertexShader = PostProcessVS;
        PixelShader = PS_DownscaleColor;
    }

    pass {
        RenderTarget = AFX_QuarterCoC;

        VertexShader = PostProcessVS;
        PixelShader = PS_DownscaleCoC;
    }

    pass {
        RenderTarget = AFX_QuarterFarColor;

        VertexShader = PostProcessVS;
        PixelShader = PS_DownscaleFarColor;
    }

    pass {
        RenderTarget = AFX_QuarterPing;

        VertexShader = PostProcessVS;
        PixelShader = PS_MaxCoCX;
    }

    pass {
        RenderTarget = AFX_NearCoCBlur;

        VertexShader = PostProcessVS;
        PixelShader = PS_MaxCoCY;
    }

    pass {
        RenderTarget = AFX_QuarterPing;

        VertexShader = PostProcessVS;
        PixelShader = PS_BlurCoCX;
    }

    pass {
        RenderTarget = AFX_NearCoCBlur;

        VertexShader = PostProcessVS;
        PixelShader = PS_BlurCoCY;
    }

    pass {
        RenderTarget = AFX_QuarterPing;

        VertexShader = PostProcessVS;
        PixelShader = PS_NearBlurX;
    }

    pass {
        RenderTarget = AFX_NearBlur;

        VertexShader = PostProcessVS;
        PixelShader = PS_NearBlurY;
    }

    pass {
        RenderTarget = AFX_QuarterPing;

        VertexShader = PostProcessVS;
        PixelShader = PS_FarBlurX;
    }

    pass {
        RenderTarget = AFX_FarBlur;

        VertexShader = PostProcessVS;
        PixelShader = PS_FarBlurY;
    }

    pass {
        RenderTarget = AFX_QuarterPing;

        VertexShader = PostProcessVS;
        PixelShader = PS_NearBlurX2;
    }

    pass {
        RenderTarget = AFX_NearFill;

        VertexShader = PostProcessVS;
        PixelShader = PS_NearBlurY2;
    }

    pass {
        RenderTarget = AFX_QuarterPing;

        VertexShader = PostProcessVS;
        PixelShader = PS_FarBlurX2;
    }

    pass {
        RenderTarget = AFX_FarFill;

        VertexShader = PostProcessVS;
        PixelShader = PS_FarBlurY2;
    }

    pass {
        RenderTarget = AFX_NearBlend;

        VertexShader = PostProcessVS;
        PixelShader = PS_CompositeNearKernel;
    }

    pass {
        RenderTarget = AFX_FarBlend;

        VertexShader = PostProcessVS;
        PixelShader = PS_CompositeFarKernel;
    }

    pass {
        RenderTarget = AFX_NearFill;

        VertexShader = PostProcessVS;
        PixelShader = PS_NearFill;
    }

    pass {
        RenderTarget = AFX_FarFill;

        VertexShader = PostProcessVS;
        PixelShader = PS_FarFill;
    }

    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_Composite;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}