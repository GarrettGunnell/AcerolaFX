#pragma once

namespace AFXTemp3 {
    texture2D AFX_RenderTexHDR3 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
    sampler2D RenderTex { Texture = AFX_RenderTexHDR3; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
    sampler2D RenderTexLinear { Texture = AFX_RenderTexHDR3; };
    storage2D s_RenderTex { Texture = AFX_RenderTexHDR3; };
}