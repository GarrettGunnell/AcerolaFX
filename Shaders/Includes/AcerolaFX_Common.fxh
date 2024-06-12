#pragma once

#define AFX_PI 3.14159265358979323846f

namespace Common {
    texture2D AcerolaBufferTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
    sampler2D AcerolaBuffer { Texture = AcerolaBufferTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
    sampler2D AcerolaBufferLinear { Texture = AcerolaBufferTex; };
    storage2D s_AcerolaBuffer { Texture = AcerolaBufferTex; };

    sampler2D AcerolaBufferMirror { Texture = AcerolaBufferTex; AddressU = MIRROR; AddressV = MIRROR; AddressW = MIRROR; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
    sampler2D AcerolaBufferMirrorLinear { Texture = AcerolaBufferTex; AddressU = MIRROR; AddressV = MIRROR; AddressW = MIRROR; };
    sampler2D AcerolaBufferWrap { Texture = AcerolaBufferTex; AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
    sampler2D AcerolaBufferWrapLinear { Texture = AcerolaBufferTex; AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; };
    sampler2D AcerolaBufferRepeat { Texture = AcerolaBufferTex; AddressU = REPEAT; AddressV = REPEAT; AddressW = REPEAT; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
    sampler2D AcerolaBufferRepeatLinear { Texture = AcerolaBufferTex; AddressU = REPEAT; AddressV = REPEAT; AddressW = REPEAT; };
    sampler2D AcerolaBufferBorder { Texture = AcerolaBufferTex; AddressU = BORDER; AddressV = BORDER; AddressW = BORDER; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;};
    sampler2D AcerolaBufferBorderLinear { Texture = AcerolaBufferTex; AddressU = BORDER; AddressV = BORDER; AddressW = BORDER; };
    
    float Luminance(float3 color) {
        return max(0.00001f, dot(color, float3(0.2127f, 0.7152f, 0.0722f)));
    }

    float3 Map(float3 x, float3 inputStart, float3 inputEnd, float3 outputStart, float3 outputEnd) {
        float3 slope = (outputEnd - outputStart) / (inputEnd - inputStart);
        return outputStart + slope * (x - inputStart);
    }

    //https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/White-Balance-Node.html
    float3 WhiteBalance(float3 col, float temp, float tint) {
        float t1 = temp * 10.0f / 6.0f;
        float t2 = tint * 10.0f / 6.0f;

        float x = 0.31271 - t1 * (t1 < 0 ? 0.1 : 0.05);
        float standardIlluminantY = 2.87 * x - 3 * x * x - 0.27509507;
        float y = standardIlluminantY + t2 * 0.05;

        float3 w1 = float3(0.949237, 1.03542, 1.08728);

        float Y = 1;
        float X = Y * x / y;
        float Z = Y * (1 - x - y) / y;
        float L = 0.7328 * X + 0.4296 * Y - 0.1624 * Z;
        float M = -0.7036 * X + 1.6975 * Y + 0.0061 * Z;
        float S = 0.0030 * X + 0.0136 * Y + 0.9834 * Z;
        float3 w2 = float3(L, M, S);

        float3 balance = float3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);

        float3x3 LIN_2_LMS_MAT = float3x3(
            float3(3.90405e-1, 5.49941e-1, 8.92632e-3),
            float3(7.08416e-2, 9.63172e-1, 1.35775e-3),
            float3(2.31082e-2, 1.28021e-1, 9.36245e-1)
        );

        float3x3 LMS_2_LIN_MAT = float3x3(
            float3(2.85847e+0, -1.62879e+0, -2.48910e-2),
            float3(-2.10182e-1,  1.15820e+0,  3.24281e-4),
            float3(-4.18120e-2, -1.18169e-1,  1.06867e+0)
        );

        float3 lms = mul(LIN_2_LMS_MAT, col);
        lms *= balance;

        return mul(LMS_2_LIN_MAT, lms);
    }

    float3 convertRGB2XYZ(float3 col) {
        float3 xyz;
        xyz.x = dot(float3(0.4124564, 0.3575761, 0.1804375), col);
        xyz.y = dot(float3(0.2126729, 0.7151522, 0.0721750), col);
        xyz.z = dot(float3(0.0193339, 0.1191920, 0.9503041), col);

        return xyz;
    }

    float3 convertXYZ2Yxy(float3 col) {
        float inv = 1.0f / dot(col, 1.0f);

        return float3(col.y, col.x * inv, col.y * inv);
    }

    float3 convertRGB2Yxy(float3 col) {
        return convertXYZ2Yxy(convertRGB2XYZ(col));
    }

    float3 convertXYZ2RGB(float3 col) {
        float3 rgb;
        rgb.x = dot(float3( 3.2404542, -1.5371385, -0.4985314), col);
        rgb.y = dot(float3(-0.9692660,  1.8760108,  0.0415560), col);
        rgb.z = dot(float3( 0.0556434, -0.2040259,  1.0572252), col);

        return rgb;
    }

    float3 convertYxy2XYZ(float3 col) {
        float3 xyz;
        xyz.x = col.x * col.y / col.z;
        xyz.y = col.x;
        xyz.z = col.x * (1.0 - col.y - col.z) / col.z;

        return xyz;
    }

    float3 convertYxy2RGB(float3 col) {
        return convertXYZ2RGB(convertYxy2XYZ(col));
    }

    // Color conversions from https://gist.github.com/mattatz/44f081cac87e2f7c8980
    float3 rgb2xyz(float3 c) {
        float3 tmp;

        tmp.x = (c.r > 0.04045) ? pow(abs((c.r + 0.055) / 1.055), 2.4) : c.r / 12.92;
        tmp.y = (c.g > 0.04045) ? pow(abs((c.g + 0.055) / 1.055), 2.4) : c.g / 12.92,
        tmp.z = (c.b > 0.04045) ? pow(abs((c.b + 0.055) / 1.055), 2.4) : c.b / 12.92;
        
        const float3x3 mat = float3x3(
            0.4124, 0.3576, 0.1805,
            0.2126, 0.7152, 0.0722,
            0.0193, 0.1192, 0.9505 
        );

        return 100.0 * mul(tmp, mat);
    }

    float3 xyz2lab(float3 c) {
        float3 n = c / float3(95.047, 100, 108.883);
        float3 v;

        v.x = (n.x > 0.008856) ? pow(abs(n.x), 1.0 / 3.0) : (7.787 * n.x) + (16.0 / 116.0);
        v.y = (n.y > 0.008856) ? pow(abs(n.y), 1.0 / 3.0) : (7.787 * n.y) + (16.0 / 116.0);
        v.z = (n.z > 0.008856) ? pow(abs(n.z), 1.0 / 3.0) : (7.787 * n.z) + (16.0 / 116.0);

        return float3((116.0 * v.y) - 16.0, 500.0 * (v.x - v.y), 200.0 * (v.y - v.z));
    }

    float3 rgb2lab(float3 c) {
        float3 lab = xyz2lab(rgb2xyz(c));

        return float3(lab.x / 100.0f, 0.5 + 0.5 * (lab.y / 127.0), 0.5 + 0.5 * (lab.z / 127.0));
    }

    // Conversions from https://www.chilliant.com/rgb2hsv.html
    #define AFX_EPSILON 1e-10
    
    float3 RGBtoHCV(in float3 RGB) {
        // Based on work by Sam Hocevar and Emil Persson
        float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
        float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
        float C = Q.x - min(Q.w, Q.y);
        float H = abs((Q.w - Q.y) / (6 * C + AFX_EPSILON) + Q.z);
        return float3(H, C, Q.x);
    }

    float3 RGBtoHSL(in float3 RGB) {
        float3 HCV = RGBtoHCV(RGB);
        float L = HCV.z - HCV.y * 0.5;
        float S = HCV.y / (1 - abs(L * 2 - 1) + AFX_EPSILON);
        return float3(HCV.x, S, L);
    }

    float3 HUEtoRGB(in float H) {
        float R = abs(H * 6 - 3) - 1;
        float G = 2 - abs(H * 6 - 2);
        float B = 2 - abs(H * 6 - 4);
        return saturate(float3(R,G,B));
    }

    float3 HSLtoRGB(in float3 HSL) {
        float3 RGB = HUEtoRGB(HSL.x);
        float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;
        return (RGB - 0.5) * C + HSL.z;
    }
}

#if !defined(__RESHADE__) || __RESHADE__ < 30000
	#error "ReShade 3.0+ is required to use this header file"
#endif

#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
	#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
	#define RESHADE_DEPTH_INPUT_IS_REVERSED 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
	#define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC 0
#endif

#ifndef RESHADE_DEPTH_MULTIPLIER
	#define RESHADE_DEPTH_MULTIPLIER 1
#endif
#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
	#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif

// Above 1 expands coordinates, below 1 contracts and 1 is equal to no scaling on any axis
#ifndef RESHADE_DEPTH_INPUT_Y_SCALE
	#define RESHADE_DEPTH_INPUT_Y_SCALE 1
#endif
#ifndef RESHADE_DEPTH_INPUT_X_SCALE
	#define RESHADE_DEPTH_INPUT_X_SCALE 1
#endif
// An offset to add to the Y coordinate, (+) = move up, (-) = move down
#ifndef RESHADE_DEPTH_INPUT_Y_OFFSET
	#define RESHADE_DEPTH_INPUT_Y_OFFSET 0
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
	#define RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET 0
#endif
// An offset to add to the X coordinate, (+) = move right, (-) = move left
#ifndef RESHADE_DEPTH_INPUT_X_OFFSET
	#define RESHADE_DEPTH_INPUT_X_OFFSET 0
#endif
#ifndef RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
	#define RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET 0
#endif

#define BUFFER_PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define BUFFER_SCREEN_SIZE float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define BUFFER_ASPECT_RATIO (BUFFER_WIDTH * BUFFER_RCP_HEIGHT)

namespace ReShade
{
	float GetAspectRatio() { return BUFFER_WIDTH * BUFFER_RCP_HEIGHT; }
	float2 GetPixelSize() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
	float2 GetScreenSize() { return float2(BUFFER_WIDTH, BUFFER_HEIGHT); }
	#define AspectRatio GetAspectRatio()
	#define PixelSize GetPixelSize()
	#define ScreenSize GetScreenSize()

	// Global textures and samplers
	texture BackBufferTex : COLOR;
	texture DepthBufferTex : DEPTH;

	sampler BackBuffer { Texture = BackBufferTex; };
	sampler DepthBuffer { Texture = DepthBufferTex; };

	// Helper functions
	float GetLinearizedDepth(float2 texcoord)
	{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		texcoord.y = 1.0 - texcoord.y;
#endif
		texcoord.x /= RESHADE_DEPTH_INPUT_X_SCALE;
		texcoord.y /= RESHADE_DEPTH_INPUT_Y_SCALE;
#if RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
		texcoord.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
#else // Do not check RESHADE_DEPTH_INPUT_X_OFFSET, since it may be a decimal number, which the preprocessor cannot handle
		texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET / 2.000000001;
#endif
#if RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
		texcoord.y += RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
#else
		texcoord.y += RESHADE_DEPTH_INPUT_Y_OFFSET / 2.000000001;
#endif
		float depth = tex2Dlod(DepthBuffer, float4(texcoord, 0, 0)).x * RESHADE_DEPTH_MULTIPLIER;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		return depth;
	}

    float GetLinearizedDepth(float2 texcoord, float zoom)
	{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		texcoord.y = 1.0 - texcoord.y;
#endif
		texcoord.x /= RESHADE_DEPTH_INPUT_X_SCALE;
		texcoord.y /= RESHADE_DEPTH_INPUT_Y_SCALE;
#if RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
		texcoord.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
#else // Do not check RESHADE_DEPTH_INPUT_X_OFFSET, since it may be a decimal number, which the preprocessor cannot handle
		texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET / 2.000000001;
#endif
#if RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
		texcoord.y += RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
#else
		texcoord.y += RESHADE_DEPTH_INPUT_Y_OFFSET / 2.000000001;
#endif
		float depth = tex2Dlod(DepthBuffer, float4(texcoord * zoom, 0, 0)).x * RESHADE_DEPTH_MULTIPLIER;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		return depth;
	}

	float3 GetScreenSpaceNormal(float2 texcoord) {
		float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
		float2 posCenter = texcoord.xy;
		float2 posNorth  = posCenter - offset.zy;
		float2 posEast   = posCenter + offset.xz;

		float3 vertCenter = float3(posCenter - 0.5, 1) * GetLinearizedDepth(posCenter);
		float3 vertNorth  = float3(posNorth - 0.5,  1) * GetLinearizedDepth(posNorth);
		float3 vertEast   = float3(posEast - 0.5,   1) * GetLinearizedDepth(posEast);

		return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
	}
}

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	if (id == 2)
		texcoord.x = 2.0;
	else
		texcoord.x = 0.0;

	if (id == 1)
		texcoord.y = 2.0;
	else
		texcoord.y = 0.0;

	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}
