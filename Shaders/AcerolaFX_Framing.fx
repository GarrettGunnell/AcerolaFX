#include "AcerolaFX_Common.fxh"

uniform float3 _FrameColor <
    ui_type = "color";
    ui_label = "Frame Color";
> = 0.0f;

uniform int2 _Offset <
    ui_type = "drag";
    ui_label = "Position";
    ui_tooltip = "Positional offset from center of screen.";
> = 0;

uniform float _Theta <
    ui_min = -180.0f; ui_max = 180.0f;
    ui_label = "Rotation";
    ui_type = "drag";
    ui_tooltip = "Adjust rotation of the frame.";
> = 0;

uniform float _Alpha <
    ui_min = 0f; ui_max = 1.0f;
    ui_label = "Alpha";
    ui_type = "drag";
    ui_tooltip = "Adjust alpha of the frame.";
> = 1f;

uniform int _Left <
    ui_min = -BUFFER_WIDTH; ui_max = BUFFER_WIDTH;
    ui_category = "Frame Dimensions";
    ui_category_closed = true;
    ui_label = "Left";
    ui_type = "drag";
    ui_tooltip = "Adjust frame cutoff for left side of the screen.";
> = 0;

uniform int _Right <
    ui_min = -BUFFER_WIDTH; ui_max = BUFFER_WIDTH;
    ui_category = "Frame Dimensions";
    ui_category_closed = true;
    ui_label = "Right";
    ui_type = "drag";
    ui_tooltip = "Adjust frame cutoff for right side of the screen.";
> = 0;

uniform int _Top <
    ui_min = -BUFFER_HEIGHT; ui_max = BUFFER_HEIGHT;
    ui_category = "Frame Dimensions";
    ui_category_closed = true;
    ui_label = "Top";
    ui_type = "drag";
    ui_tooltip = "Adjust frame cutoff for top side of the screen.";
> = 0;

uniform int _Bottom <
    ui_min = -BUFFER_HEIGHT; ui_max = BUFFER_HEIGHT;
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

texture2D AFX_FramingTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D Framing { Texture = AFX_FramingTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Framing, uv).rgba; }

float4 PS_Framing(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = saturate(tex2D(Common::AcerolaBuffer, uv).rgba);
    int depth = ReShade::GetLinearizedDepth(uv) * 1000;

    float theta = radians(_Theta);
    float2x2 R = float2x2(float2(cos(theta), -sin(theta)), float2(sin(theta), cos (theta)));

    float2 minBounds = float2(_Left, _Top) + _Offset;
    float2 maxBounds = float2(BUFFER_WIDTH - _Right, BUFFER_HEIGHT - _Bottom) + _Offset;

    float2 offset = float2(BUFFER_WIDTH / 2, BUFFER_HEIGHT / 2) + _Offset;
    float2 rotatedPosition = mul(R, position.xy - offset) + offset;

    if ((any(rotatedPosition < minBounds) || any(maxBounds < rotatedPosition)) && _DepthCutoff < depth)
        return float4(lerp(col.xyz, _FrameColor, _Alpha), 1.0f);


    return col;
}

technique AFX_Framing < ui_label = "Framing"; ui_tooltip = "Overlay a frame for composition."; > {
    pass {
        RenderTarget = AFX_FramingTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_Framing;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}