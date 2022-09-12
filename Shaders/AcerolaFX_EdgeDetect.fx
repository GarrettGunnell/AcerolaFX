#include "AcerolaFX_Common.fxh"

uniform bool _UseDepth <
    ui_label = "Use Depth";
    ui_tooltip = "Use depth values to determine edges.";
> = true;

uniform float _DepthThreshold <
    ui_min = 0.0f; ui_max = 5.0f;
    ui_label = "Depth Threshold";
    ui_type = "drag";
    ui_tooltip = "Adjust the threshold for depth differences to count as an edge.";
> = 1.0f;

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

texture2D NormalsTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Normals { Texture = NormalsTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };

texture2D EdgeDetectTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D EdgeDetect { Texture = EdgeDetectTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(EdgeDetect, uv).rgba; }

float4 PS_CalculateNormals(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return 1.0f;
}

float4 PS_EdgeDetect(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    return 1.0f;
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