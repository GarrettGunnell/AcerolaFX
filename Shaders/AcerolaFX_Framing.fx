#include "AcerolaFX_Common.fxh"

uniform float3 _FrameColor <
    ui_type = "color";
    ui_label = "Frame Color";
> = 0.0f;

uniform int _Left <
    ui_min = 0; ui_max = BUFFER_WIDTH;
    ui_category = "Frame Dimensions";
    ui_category_closed = true;
    ui_label = "Left";
    ui_type = "drag";
    ui_tooltip = "Adjust frame cutoff for left side of the screen.";
> = 0;

uniform int _Right <
    ui_min = 0; ui_max = BUFFER_WIDTH;
    ui_category = "Frame Dimensions";
    ui_category_closed = true;
    ui_label = "Right";
    ui_type = "drag";
    ui_tooltip = "Adjust frame cutoff for right side of the screen.";
> = 0;

uniform int _Top <
    ui_min = 0; ui_max = BUFFER_HEIGHT;
    ui_category = "Frame Dimensions";
    ui_category_closed = true;
    ui_label = "Top";
    ui_type = "drag";
    ui_tooltip = "Adjust frame cutoff for top side of the screen.";
> = 0;

uniform int _Bottom <
    ui_min = 0; ui_max = BUFFER_HEIGHT;
    ui_category = "Frame Dimensions";
    ui_category_closed = true;
    ui_label = "Bottom";
    ui_type = "drag";
    ui_tooltip = "Adjust frame cutoff for bottom side of the screen.";
> = 0;

uniform int _DepthCutoff <
    ui_min = 0; ui_max = 1000;
    ui_category = "Depth";
    ui_category_closed = true;
    ui_label = "Depth Cutoff";
    ui_type = "slider";
    ui_tooltip = "Distance at which depth is masked by the frame.";
> = 0;

texture2D FramingTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Framing { Texture = FramingTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Framing, uv).rgba; }

float4 PS_Framing(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv).rgba);
    int depth = ReShade::GetLinearizedDepth(uv) * 1000;
    float2 minBounds = float2(_Left, _Top);
    float2 maxBounds = float2(BUFFER_WIDTH - _Right, BUFFER_HEIGHT - _Bottom);

    if ((any(position.xy < minBounds) || any(maxBounds < position.xy)) && _DepthCutoff < depth)
        return float4(_FrameColor, 1.0f);


    return col;
}

technique AFX_Framing < ui_label = "Framing"; ui_tooltip = "Overlay a frame for composition."; > {
    pass {
        RenderTarget = FramingTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Framing;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}