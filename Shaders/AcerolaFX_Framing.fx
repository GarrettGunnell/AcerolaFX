#include "Includes/AcerolaFX_Framing.fxh"

#ifndef AFX_FRAME_COUNT
    #define AFX_FRAME_COUNT 0
#endif

AFX_FRAME_SHADOW_CLONE(AFX_Frame, "Framing", "Frame 1 Settings", _FrameShape, _FrameColor, _FrameAlpha, _FrameRadius, _FrameInvert, _FrameOffset, _FrameTheta, _FrameDepthCutoff, PS_Frame)

#if AFX_FRAME_COUNT > 0
    AFX_FRAME_SHADOW_CLONE(AFX_Frame2, "Frame 2", "Frame 2 Settings", _Frame2Shape, _Frame2Color, _Frame2Alpha, _Frame2Radius, _Frame2Invert, _Frame2Offset, _Frame2Theta, _Frame2DepthCutoff, PS_Frame2)
#endif

#if AFX_FRAME_COUNT > 1
    AFX_FRAME_SHADOW_CLONE(AFX_Frame3, "Frame 3", "Frame 3 Settings", _Frame3Shape, _Frame3Color, _Frame3Alpha, _Frame3Radius, _Frame3Invert, _Frame3Offset, _Frame3Theta, _Frame3DepthCutoff, PS_Frame3)
#endif

#if AFX_FRAME_COUNT > 2
    AFX_FRAME_SHADOW_CLONE(AFX_Frame4, "Frame 4", "Frame 4 Settings", _Frame4Shape, _Frame4Color, _Frame4Alpha, _Frame4Radius, _Frame4Invert, _Frame4Offset, _Frame4Theta, _Frame4DepthCutoff, PS_Frame4)
#endif

#if AFX_FRAME_COUNT > 3
    AFX_FRAME_SHADOW_CLONE(AFX_Frame5, "Frame 5", "Frame 5 Settings", _Frame5Shape, _Frame5Color, _Frame5Alpha, _Frame5Radius, _Frame5Invert, _Frame5Offset, _Frame5Theta, _Frame5DepthCutoff, PS_Frame5)
#endif

#if AFX_FRAME_COUNT > 4
    AFX_FRAME_SHADOW_CLONE(AFX_Frame6, "Frame 6", "Frame 6 Settings", _Frame6Shape, _Frame6Color, _Frame6Alpha, _Frame6Radius, _Frame6Invert, _Frame6Offset, _Frame6Theta, _Frame6DepthCutoff, PS_Frame6)
#endif

#if AFX_FRAME_COUNT > 5
    AFX_FRAME_SHADOW_CLONE(AFX_Frame7, "Frame 7", "Frame 7 Settings", _Frame7Shape, _Frame7Color, _Frame7Alpha, _Frame7Radius, _Frame7Invert, _Frame7Offset, _Frame7Theta, _Frame7DepthCutoff, PS_Frame7)
#endif

#if AFX_FRAME_COUNT > 6
    AFX_FRAME_SHADOW_CLONE(AFX_Frame8, "Frame 8", "Frame 8 Settings", _Frame8Shape, _Frame8Color, _Frame8Alpha, _Frame8Radius, _Frame8Invert, _Frame8Offset, _Frame8Theta, _Frame8DepthCutoff, PS_Frame8)
#endif

#if AFX_FRAME_COUNT > 7
    AFX_FRAME_SHADOW_CLONE(AFX_Frame9, "Frame 9", "Frame 9 Settings", _Frame9Shape, _Frame9Color, _Frame9Alpha, _Frame9Radius, _Frame9Invert, _Frame9Offset, _Frame9Theta, _Frame9DepthCutoff, PS_Frame9)
#endif

#if AFX_FRAME_COUNT > 8
    AFX_FRAME_SHADOW_CLONE(AFX_Frame9, "Frame 10", "Frame 10 Settings", _Frame10Shape, _Frame10Color, _Frame10Alpha, _Frame10Radius, _Frame10Invert, _Frame10Offset, _Frame10Theta, _Frame10DepthCutoff, PS_Frame10)
#endif