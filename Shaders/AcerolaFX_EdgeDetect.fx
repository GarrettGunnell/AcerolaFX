#include "Includes/AcerolaFX_Common.fxh"
#include "Includes/AcerolaFX_TempTex1.fxh"

uniform float3 _EdgeColor <
    ui_label = "Edge Color";
    ui_tooltip = "Color of edges";
    ui_type = "color";
> = 0.0f;

uniform float _Alpha <
    ui_min = 0.0f; ui_max = 1.0f;
    ui_label = "Alpha";
    ui_type = "drag";
    ui_tooltip = "Adjust edge transparency.";
> = 1.0f;

uniform int _EdgeMode <
    ui_spacing = 5.0f;
    ui_type = "combo";
    ui_label = "Edge Mode";
    ui_items = "Depth\0"
                "Depth and Normals\0";
> = 1;

uniform float _DepthThreshold <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Depth Threshold";
    ui_type = "drag";
    ui_tooltip = "Adjust the threshold for depth differences to count as an edge.";
> = 0.1f;

uniform float _NormalThreshold <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Normal Threshold";
    ui_type = "drag";
    ui_tooltip = "Adjust the threshold for normal differences to count as an edge.";
> = 3.0f;

uniform int _DepthCutoff <
    ui_min = 0; ui_max = 1000;
    ui_category = "Depth Settings";
    ui_category_closed = true;
    ui_label = "Depth Cutoff";
    ui_type = "slider";
    ui_tooltip = "Distance at which depth is masked by the frame.";
> = 0;

uniform bool _UseFogFalloff <
    ui_category = "Depth Settings";
    ui_category_closed = true;
    ui_label = "Use Fog Falloff";
    ui_tooltip = "Enable to use the depth falloff logic below akin to fog.";
> = true;

uniform float _EdgeFalloff <
    ui_category = "Depth Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 0.01f;
    ui_label = "Falloff";
    ui_type = "slider";
    ui_tooltip = "Adjust rate at which the effect falls off at a distance.";
> = 0.0f;

uniform float _Offset <
    ui_category = "Depth Settings";
    ui_category_closed = true;
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Falloff Offset";
    ui_type = "slider";
    ui_tooltip = "Offset distance at which effect starts to falloff.";
> = 0.0f;

sampler2D Normals { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

texture2D AFX_EdgeDetectTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D EdgeDetect { Texture = AFX_EdgeDetectTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(EdgeDetect, uv).rgba; }

float4 PS_CalculateNormals(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float3 offset = float3(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, 0.0);
	float2 posCenter = uv;
	float2 posNorth  = posCenter - offset.zy;
	float2 posEast   = posCenter + offset.xz;

    float centerDepth = ReShade::GetLinearizedDepth(posCenter);

	float3 vertCenter = float3(posCenter - 0.5, 1) * centerDepth;
	float3 vertNorth  = float3(posNorth - 0.5,  1) * ReShade::GetLinearizedDepth(posNorth);
	float3 vertEast   = float3(posEast - 0.5,   1) * ReShade::GetLinearizedDepth(posEast);

	return float4(normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5, centerDepth);

}

float4 PS_EdgeDetect(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float2 offset = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float4 col = tex2D(Common::AcerolaBuffer, uv);

    float4 c  = tex2D(Normals, uv + float2( 0,  0) * offset);
    float4 w  = tex2D(Normals, uv + float2(-1,  0) * offset);
    float4 e  = tex2D(Normals, uv + float2( 1,  0) * offset);
    float4 n  = tex2D(Normals, uv + float2( 0, -1) * offset);
    float4 s  = tex2D(Normals, uv + float2( 0,  1) * offset);
    float4 nw = tex2D(Normals, uv + float2(-1, -1) * offset);
    float4 sw = tex2D(Normals, uv + float2( 1, -1) * offset);
    float4 ne = tex2D(Normals, uv + float2(-1,  1) * offset);
    float4 se = tex2D(Normals, uv + float2( 1,  1) * offset);
    
    float output = 0.0f;

    float depthSum = 0.0f;
    depthSum += abs(w.w - c.w);
    depthSum += abs(e.w - c.w);
    depthSum += abs(n.w - c.w);
    depthSum += abs(s.w - c.w);
    depthSum += abs(nw.w - c.w);
    depthSum += abs(sw.w - c.w);
    depthSum += abs(ne.w - c.w);
    depthSum += abs(se.w - c.w);

    if (depthSum > _DepthThreshold)
        output = 1.0f;

    float3 normalSum = 0.0f;
    if (_EdgeMode == 1) {
        normalSum += abs(w.rgb - c.rgb);
        normalSum += abs(e.rgb - c.rgb);
        normalSum += abs(n.rgb - c.rgb);
        normalSum += abs(s.rgb - c.rgb);
        normalSum += abs(nw.rgb - c.rgb);
        normalSum += abs(sw.rgb - c.rgb);
        normalSum += abs(ne.rgb - c.rgb);
        normalSum += abs(se.rgb - c.rgb);

        if (dot(normalSum, 1) > _NormalThreshold)
            output = 1.0f;
    }

    if (_EdgeFalloff > 0.0f && _UseFogFalloff) {
        float viewDistance = c.w * 1000;

        float falloffFactor = 0.0f;

        falloffFactor = (_EdgeFalloff / log(2)) * max(0.0f, viewDistance - _Offset);
        falloffFactor = exp2(-falloffFactor);

        output = lerp(0.0f, output, saturate(falloffFactor));
    }
    if (_DepthCutoff > 0.0f) {
        if (c.w * 1000 > _DepthCutoff)
            output = 0.0f;
    }

    return float4(lerp(col.rgb, lerp(col.rgb, _EdgeColor.rgb, saturate(output)), _Alpha), 1.0f);
}

technique AFX_EdgeDetect < ui_label = "Edge Detector"; ui_tooltip = "(LDR) Attempts to detect edges of the image."; > {
    pass {
        RenderTarget = AFXTemp1::AFX_RenderTex1;

        VertexShader = PostProcessVS;
        PixelShader = PS_CalculateNormals;
    }

    pass {
        RenderTarget = AFX_EdgeDetectTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EdgeDetect;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}