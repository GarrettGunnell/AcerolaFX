#include "Fog.fxh"
#include "ColorCorrection.fxh"

technique AcerolaFX {
    pass Fog {
        VertexShader = PostProcessVS;
        PixelShader = PS_DistanceFog;
    }

    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_ColorCorrect;
    }
}