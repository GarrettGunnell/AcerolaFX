#include "AcerolaFX_Common.fxh"

uniform float3 _EdgeColor <
    ui_label = "Edge Color";
    ui_tooltip = "Color of edges";
    ui_type = "color";
> = 0.0f;

uniform bool _UseDepth <
    ui_label = "Use Depth";
    ui_tooltip = "Use depth values to determine edges.";
> = true;

uniform float _DepthThreshold <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Depth Threshold";
    ui_type = "drag";
    ui_tooltip = "Adjust the threshold for depth differences to count as an edge.";
> = 0.1f;

uniform bool _UseNormals <
    ui_label = "Use Normals";
    ui_tooltip = "Use normals to determine edges.";
> = true;

uniform float _NormalThreshold <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Normal Threshold";
    ui_type = "drag";
    ui_tooltip = "Adjust the threshold for normal differences to count as an edge.";
> = 1.0f;

texture2D NormalsTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Normals { Texture = NormalsTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

texture2D EdgeDetectTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D EdgeDetect { Texture = EdgeDetectTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
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
    if (_UseDepth) {
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
    }

    float3 normalSum = 0.0f;
    if (_UseNormals) {
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

    return float4(lerp(col.rgb, _EdgeColor.rgb, output), 1.0f);
}

technique AFX_EdgeDetect < ui_label = "Edge Detector"; ui_tooltip = "(LDR) Attempts to detect edges of the image."; > {
    pass {
        RenderTarget = NormalsTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_CalculateNormals;
    }

    pass {
        RenderTarget = EdgeDetectTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EdgeDetect;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}