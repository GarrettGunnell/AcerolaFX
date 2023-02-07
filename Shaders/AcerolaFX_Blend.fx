#include "Includes/AcerolaFX_Blend.fxh"

#ifndef AFX_BLEND_COUNT
    #define AFX_BLEND_COUNT 0
#endif

AFX_BLEND_SHADOW_CLONE(AFX_Blend, "Blend 1", "Blend 1 Settings", _BlendMode, _BlendColor, _ColorBlend, _BlendTexture, _TextureBlend, _TextureRes, _BlendStrength, _SampleSky, PS_Blend)

#if AFX_BLEND_COUNT > 0
    AFX_BLEND_SHADOW_CLONE(AFX_Blend2, "Blend 2", "Blend 2 Settings", _Blend2Mode, _Blend2Color, _Color2Blend, _BlendTexture2, _TextureBlend2, _TextureRes2, _Blend2Strength, _SampleSky2, PS_Blend2)
#endif

#if AFX_BLEND_COUNT > 1
    AFX_BLEND_SHADOW_CLONE(AFX_Blend3, "Blend 3", "Blend 3 Settings", _Blend3Mode, _Blend3Color, _Color3Blend, _BlendTexture3, _TextureBlend3, _TextureRes3, _Blend3Strength, _SampleSky3, PS_Blend3)
#endif

#if AFX_BLEND_COUNT > 2
    AFX_BLEND_SHADOW_CLONE(AFX_Blend4, "Blend 4", "Blend 4 Settings", _Blend4Mode, _Blend4Color, _Color4Blend, _BlendTexture4, _TextureBlend4, _TextureRes4, _Blend4Strength, _SampleSky4, PS_Blend4)
#endif

#if AFX_BLEND_COUNT > 3
    AFX_BLEND_SHADOW_CLONE(AFX_Blend5, "Blend 5", "Blend 5 Settings", _Blend5Mode, _Blend5Color, _Color5Blend, _BlendTexture5, _TextureBlend5, _TextureRes5, _Blend5Strength, _SampleSky5, PS_Blend5)
#endif

#if AFX_BLEND_COUNT > 4
    AFX_BLEND_SHADOW_CLONE(AFX_Blend6, "Blend 6", "Blend 6 Settings", _Blend6Mode, _Blend6Color, _Color6Blend, _BlendTexture6, _TextureBlend6, _TextureRes6, _Blend6Strength, _SampleSky6, PS_Blend6)
#endif

#if AFX_BLEND_COUNT > 5
    AFX_BLEND_SHADOW_CLONE(AFX_Blend7, "Blend 7", "Blend 7 Settings", _Blend7Mode, _Blend7Color, _Color7Blend, _BlendTexture7, _TextureBlend7, _TextureRes7, _Blend7Strength, _SampleSky7, PS_Blend7)
#endif

#if AFX_BLEND_COUNT > 6
    AFX_BLEND_SHADOW_CLONE(AFX_Blend8, "Blend 8", "Blend 8 Settings", _Blend8Mode, _Blend8Color, _Color8Blend, _BlendTexture8, _TextureBlend8, _TextureRes8, _Blend8Strength, _SampleSky8, PS_Blend8)
#endif

#if AFX_BLEND_COUNT > 7
    AFX_BLEND_SHADOW_CLONE(AFX_Blend9, "Blend 9", "Blend 9 Settings", _Blend9Mode, _Blend9Color, _Color9Blend, _BlendTexture9, _TextureBlend9, _TextureRes9, _Blend9Strength, _SampleSky9, PS_Blend9)
#endif

#if AFX_BLEND_COUNT > 8
    AFX_BLEND_SHADOW_CLONE(AFX_Blend10, "Blend 10", "Blend 10 Settings", _Blend10Mode, _Blend10Color, _Color10Blend, _BlendTexture10, _TextureBlend10, _TextureRes10, _Blend10Strength, _SampleSky10, PS_Blend10)
#endif
