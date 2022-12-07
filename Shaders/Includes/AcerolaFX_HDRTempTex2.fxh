#pragma once

namespace AFXTemp2 {
    texture2D AFX_RenderTex2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
    sampler2D RenderTex { Texture = AFX_RenderTex2; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
    sampler2D RenderTexLinear { Texture = AFX_RenderTex2; };
    storage2D s_RenderTex { Texture = AFX_RenderTex2; };
}