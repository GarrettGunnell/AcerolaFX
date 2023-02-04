#include "AcerolaFX_Common.fxh"
#include "AcerolaFX_TempTex1.fxh"

sampler2D Framing { Texture = AFXTemp1::AFX_RenderTex1; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(Framing, uv).rgba; }

bool inRect(float2 pos, float2 origin, float2 radius, float2x2 R) {
    float2 M = pos;
    float2 A = mul(R, float2(origin.x - radius.x, origin.y - radius.y) - origin) + origin;
    float2 B = mul(R, float2(origin.x + radius.x, origin.y - radius.y) - origin) + origin;
    float2 D = mul(R, float2(origin.x - radius.x, origin.y + radius.y) - origin) + origin;
    float2 AM = M - A;
    float2 AB = B - A;
    float2 AD = D - A;

    return (0 < dot(AM, AB) && dot(AM, AB) < dot(AB, AB)) && (0 < dot(AM, AD) && dot(AM, AD) < dot(AD, AD));
}

#define AFX_FRAME_SHADOW_CLONE(AFX_TECHNIQUE_NAME, AFX_TECHNIQUE_LABEL, AFX_VARIABLE_CATEGORY, AFX_FRAME_SHAPE, AFX_FRAME_COLOR, AFX_FRAME_ALPHA, AFX_FRAME_RADIUS, AFX_FRAME_INVERT, AFX_FRAME_OFFSET, AFX_FRAME_THETA, AFX_FRAME_DEPTH_CUTOFF, AFX_PS_NAME) \
\
uniform uint AFX_FRAME_SHAPE < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_type = "combo"; \
    ui_label = "Frame Shape"; \
    ui_tooltip = "Shape of the frame."; \
    ui_items = "Rectangle\0" \
               "Circle\0"; \
> = 0; \
\
uniform float3 AFX_FRAME_COLOR < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_type = "color"; \
    ui_label = "Frame Color"; \
> = 0.0f; \
\
uniform float AFX_FRAME_ALPHA < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = 0f; ui_max = 1.0f; \
    ui_label = "Alpha"; \
    ui_type = "drag"; \
    ui_tooltip = "Adjust alpha of the frame."; \
> = 1.0f; \
\
uniform float2 AFX_FRAME_RADIUS < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = 0f; ui_max = BUFFER_WIDTH; \
    ui_label = "Shape Dimensions"; \
    ui_type = "drag"; \
    ui_tooltip = "Adjust radius of circle frame shape."; \
> = 100.0f; \
\
uniform bool AFX_FRAME_INVERT < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_label = "Invert"; \
    ui_tooltip = "Invert the frame."; \
> = false; \
\
uniform int2 AFX_FRAME_OFFSET < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_type = "drag"; \
    ui_label = "Position"; \
    ui_tooltip = "Positional offset from center of screen."; \
> = 0; \
\
uniform float AFX_FRAME_THETA < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = -180.0f; ui_max = 180.0f; \
    ui_label = "Rotation"; \
    ui_type = "drag"; \
    ui_tooltip = "Adjust rotation of the frame."; \
> = 0; \
\
uniform int AFX_FRAME_DEPTH_CUTOFF < \
    ui_category = AFX_VARIABLE_CATEGORY; \
    ui_category_closed = true; \
    ui_min = 0; ui_max = 1000; \
    ui_label = "Depth Cutoff"; \
    ui_type = "slider"; \
    ui_tooltip = "Distance at which depth is masked by the frame."; \
> = 0; \
\
\
float4 AFX_PS_NAME(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { \
    float4 col = tex2D(Common::AcerolaBuffer, uv); \
    int depth = ReShade::GetLinearizedDepth(uv) * 1000; \
    float2 origin = float2(BUFFER_WIDTH / 2, BUFFER_HEIGHT / 2) + AFX_FRAME_OFFSET; \
    float theta = radians(AFX_FRAME_THETA); \
    float2x2 R = float2x2(float2(cos(theta), -sin(theta)), float2(sin(theta), cos (theta))); \
\
    float shape = 0.0f; \
    if (AFX_FRAME_SHAPE == 0) { \
        if (inRect(position.xy, origin, AFX_FRAME_RADIUS, R)) \
            shape = 1.0f; \
    }\
\
    if (AFX_FRAME_SHAPE == 1) { \
        float2 pos = mul(R, position.xy - origin) + origin; \
        shape = ((((pos.x - origin.x) * (pos.x - origin.x)) / (AFX_FRAME_RADIUS.x * AFX_FRAME_RADIUS.x)) + (((pos.y - origin.y) * (pos.y - origin.y)) / (AFX_FRAME_RADIUS.y * AFX_FRAME_RADIUS.y))); \
        shape = pow(saturate(shape), 300.0f); \
    } \
\
    shape = AFX_FRAME_INVERT ? 1 - shape : shape; \
    shape *= AFX_FRAME_DEPTH_CUTOFF < depth; \
    return float4(lerp(col.xyz, AFX_FRAME_COLOR, AFX_FRAME_ALPHA * shape), 1.0f); \
} \
\
technique AFX_TECHNIQUE_NAME < ui_label = AFX_TECHNIQUE_LABEL; ui_tooltip = "Overlay a frame for composition."; > { \
    pass { \
        RenderTarget = AFXTemp1::AFX_RenderTex1; \
\
        VertexShader = PostProcessVS; \
        PixelShader = AFX_PS_NAME; \
    } \
\
    pass EndPass { \
        RenderTarget = Common::AcerolaBufferTex; \
\
        VertexShader = PostProcessVS; \
        PixelShader = PS_EndPass; \
    } \
} \