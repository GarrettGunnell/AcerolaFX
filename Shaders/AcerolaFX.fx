#include "ColorCorrection.fxh"

technique AcerolaFX {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_ColorCorrect;
    }
}