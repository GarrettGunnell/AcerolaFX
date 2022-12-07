#pragma once

namespace AFXTemp4 {
    texture2D AFX_RenderTexHDR4 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
    sampler2D RenderTex { Texture = AFX_RenderTexHDR4; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
    sampler2D RenderTexLinear { Texture = AFX_RenderTexHDR4; };
    storage2D s_RenderTex { Texture = AFX_RenderTexHDR4; };
}