#pragma once

namespace DownScale {
    texture2D HalfTex {
        Width = BUFFER_WIDTH / 2;
        Height = BUFFER_HEIGHT / 2;

        Format = RGBA16F;
    }; sampler2D Half { Texture = HalfTex; };
    storage2D s_Half { Texture = HalfTex; };

    texture2D QuarterTex {
        Width = BUFFER_WIDTH / 4;
        Height = BUFFER_HEIGHT / 4;

        Format = RGBA16F;
    }; sampler2D Quarter { Texture = QuarterTex; };
    
    texture2D EighthTex {
        Width = BUFFER_WIDTH / 8;
        Height = BUFFER_HEIGHT / 8;

        Format = RGBA16F;
    }; sampler2D Eighth { Texture = EighthTex; };
    
    texture2D SixteenthTex {
        Width = BUFFER_WIDTH / 16;
        Height = BUFFER_HEIGHT / 16;

        Format = RGBA16F;
    }; sampler2D Sixteenth { Texture = SixteenthTex; };
    
    texture2D ThirtySecondthTex {
        Width = BUFFER_WIDTH / 32;
        Height = BUFFER_HEIGHT / 32;

        Format = RGBA16F;
    }; sampler2D ThirtySecondth { Texture = ThirtySecondthTex; };
    
    texture2D SixtyFourthTex {
        Width = BUFFER_WIDTH / 64;
        Height = BUFFER_HEIGHT / 64;

        Format = RGBA16F;
    }; sampler2D SixtyFourth { Texture = SixtyFourthTex; };
    
    texture2D OneTwentyEighthTex {
        Width = BUFFER_WIDTH / 128;
        Height = BUFFER_HEIGHT / 128;

        Format = RGBA16F;
    }; sampler2D OneTwentyEighth { Texture = OneTwentyEighthTex; };
    
    texture2D TwoFiftySixthTex {
        Width = BUFFER_WIDTH / 256;
        Height = BUFFER_HEIGHT / 256;

        Format = RGBA16F;
    }; sampler2D TwoFiftySixth { Texture = TwoFiftySixthTex; };
    
}