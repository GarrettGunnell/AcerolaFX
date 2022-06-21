#include "ReShade.fxh"
#include "Common.fxh"

uniform float _EffectRadius <
    ui_min = 0.01f; ui_max = 100.0f;
    ui_label = "Effect Radius";
    ui_type = "drag";
    ui_tooltip = "Modify radius of sampling.";
> = 0.5f;

uniform float _RadiusMultiplier <
    ui_min = 0.01f; ui_max = 5.0f;
    ui_label = "Radius Multiplier";
    ui_type = "drag";
    ui_tooltip = "Modify sampling radius multiplier.";
> = 1.457f;

uniform float _EffectFalloffRange <
    ui_min = 0.01f; ui_max = 5.0f;
    ui_label = "Falloff Range";
    ui_type = "drag";
    ui_tooltip = "Distant samples contribute less.";
> = 0.615f;

uniform float _SampleDistributionPower <
    ui_min = 0.01f; ui_max = 10.0f;
    ui_label = "Sample Distribution Power";
    ui_type = "drag";
    ui_tooltip = "Small crevices more important that big surfaces."; 
> = 2.0f;

uniform float _ThinOccluderCompensation <
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Thin Occluder Compensation";
    ui_type = "drag";
> = 0.0f;

uniform float _FinalValuePower <
    ui_min = 0.01f; ui_max = 5.0f;
    ui_label = "Final Value Power";
    ui_type = "drag";
    ui_tooltip = "Modfy the final ambient occlusion value exponent";
> = 2.2f;

uniform float _MipSamplingOffset <
    ui_min = 0.0f; ui_max = 10.0f;
    ui_label = "Mip Sampling Offset";
    ui_type = "drag";
    ui_tooltip = "Trades between performance and quality";
> = 3.30f;

texture2D AOTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D AO { Texture = AOTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { return tex2D(AO, uv).rgba; }

texture2D OutDepths0Tex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; }; 
sampler2D OutDepths0 { Texture = OutDepths0Tex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_OutDepths0 { Texture = OutDepths0Tex; };

texture2D OutDepths1Tex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = R32F; }; 
sampler2D OutDepths1 { Texture = OutDepths1Tex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_OutDepths1 { Texture = OutDepths1Tex; };

texture2D OutDepths2Tex { Width = BUFFER_WIDTH / 4; Height = BUFFER_HEIGHT / 4; Format = R32F; }; 
sampler2D OutDepths2 { Texture = OutDepths2Tex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_OutDepths2 { Texture = OutDepths2Tex; };

texture2D OutDepths3Tex { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = R32F; }; 
sampler2D OutDepths3 { Texture = OutDepths3Tex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_OutDepths3 { Texture = OutDepths3Tex; };

texture2D OutDepths4Tex { Width = BUFFER_WIDTH / 16; Height = BUFFER_HEIGHT / 16; Format = R32F; }; 
sampler2D OutDepths4 { Texture = OutDepths4Tex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_OutDepths4 { Texture = OutDepths4Tex; };

texture2D OutEdgesTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; }; 
sampler2D OutEdges { Texture = OutEdgesTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_OutEdges { Texture = OutEdgesTex; };

texture2D OutWorkingAOTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; }; 
sampler2D OutWorkingAO { Texture = OutWorkingAOTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_OutWorkingAO { Texture = OutWorkingAOTex; };

texture2D AOOutputTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D AOOutput { Texture = AOOutputTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; };
storage2D s_AOOutput { Texture = AOOutputTex; };

#ifndef DENOISE_PASSES
    #define DENOISE_PASSES (0)
#endif

#if DENOISE_PASSES == 0
    #define DENOISE_BLUR (1e4f)
#else
    #define DENOISE_BLUR (1.2f)
#endif

#define CLIP_FAR (1000.0f)
#define CLIP_NEAR (1.0f)

#define NUM_THREADS_X (8)
#define NUM_THREADS_Y (8)

#define XE_HILBERT_LEVEL (6U)
#define XE_HILBERT_WIDTH (1U << XE_HILBERT_LEVEL)
#define XE_HILBERT_AREA (XE_HILBERT_WIDTH * XE_HILBERT_WIDTH)

#define PI (3.1415926535897932384626433832795)
#define HALF_PI (1.5707963267948966192313216916398)

uint HilbertIndex(uint2 pos) {
    uint index = 0U;

    for (uint curLevel = XE_HILBERT_WIDTH / 2U; curLevel > 0U; curLevel /= 2U) {
        uint regionX = (pos.x & curLevel) > 0U;
        uint regionY = (pos.y & curLevel) > 0U;

        index += curLevel * curLevel * ((3U * regionX) ^ regionY);
        if (regionY == 0U) {
            if (regionX == 1U) {
                pos.x = uint((XE_HILBERT_WIDTH - 1U)) - pos.x;
                pos.y = uint((XE_HILBERT_WIDTH - 1U)) - pos.y;
            }

            uint temp = pos.x;
            pos.x = pos.y;
            pos.y = temp;
        }
    }

    return index;
}

float2 SpatioTemporalNoise(uint2 pixCoord, uint temporalIndex) {
    float2 noise;
    uint index = HilbertIndex(pixCoord);
    index += 288 * (temporalIndex % 64);
    return float2(frac(0.5 + index * float2(0.75487766624669276005, 0.5698402909980532659114)));
}

float DepthMIPFilter(float depth0, float depth1, float depth2, float depth3) {
    float maxDepth = max(max(depth0, depth1), max(depth2, depth3));

    const float depthRangeScaleFactor = 0.75f;
    const float effectRadius = depthRangeScaleFactor * _EffectRadius * _RadiusMultiplier;
    const float falloffRange = _EffectFalloffRange * effectRadius;
    const float falloffFrom = effectRadius * (1.0f - _EffectFalloffRange);
    const float falloffMul = -1.0f / falloffRange;
    const float falloffAdd = falloffFrom / falloffRange + 1.0f;

    float weight0 = saturate((maxDepth - depth0) * falloffMul + falloffAdd);
    float weight1 = saturate((maxDepth - depth1) * falloffMul + falloffAdd);
    float weight2 = saturate((maxDepth - depth2) * falloffMul + falloffAdd);
    float weight3 = saturate((maxDepth - depth3) * falloffMul + falloffAdd);

    float weightSum = weight0 + weight1 + weight2 + weight3;
    return (weight0 * depth0 + weight1 * depth1 + weight2 * depth2 + weight3 * depth3) / weightSum;
}

float3x3 RotFromToMatrix(float3 from, float3 to) {
    const float e = dot(from, to);
    const float f = abs(e);

    const float3 v = cross(from, to);
    const float h = (1.0)/(1.0 + e);
    const float hvx = h * v.x;
    const float hvz = h * v.z;
    const float hvxy = hvx * v.y;
    const float hvxz = hvx * v.z;
    const float hvyz = hvz * v.y;

    float3x3 mtx;
    mtx[0][0] = e + hvx * v.x;
    mtx[0][1] = hvxy - v.z;
    mtx[0][2] = hvxz + v.y;

    mtx[1][0] = hvxy + v.z;
    mtx[1][1] = e + h * v.y * v.y;
    mtx[1][2] = hvyz - v.x;

    mtx[2][0] = hvxz - v.y;
    mtx[2][1] = hvyz + v.x;
    mtx[2][2] = e + hvz * v.z;

    return mtx;
}

float ScreenSpaceToViewSpaceDepth(float depth) {
    float depthLinearizeMul = (CLIP_FAR * CLIP_NEAR) / (CLIP_FAR - CLIP_NEAR);
    float depthLinearizeAdd = CLIP_FAR / (CLIP_FAR - CLIP_NEAR);

    if (depthLinearizeMul * depthLinearizeAdd < 0)
        depthLinearizeAdd = -depthLinearizeAdd;

    return depthLinearizeMul / (depthLinearizeAdd - depth);
}

float ClampDepth(float depth) {
    return clamp(depth, 0.0, 3.402823466e+38);
}

groupshared float g_scratchDepths[64];
void CS_PrefilterDepths(uint3 tid : SV_DISPATCHTHREADID, uint3 gtid : SV_GROUPTHREADID) {
    // MIP 0
    const uint2 baseCoord = tid.xy;
    const uint2 pixCoord = baseCoord * 2;
    const float2 viewportPixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float4 depths4 = tex2DgatherR(ReShade::DepthBuffer, float2(pixCoord * viewportPixelSize), int2(1, 1));

    float depth0 = ClampDepth(ScreenSpaceToViewSpaceDepth(depths4.w));
    float depth1 = ClampDepth(ScreenSpaceToViewSpaceDepth(depths4.z));
    float depth2 = ClampDepth(ScreenSpaceToViewSpaceDepth(depths4.x));
    float depth3 = ClampDepth(ScreenSpaceToViewSpaceDepth(depths4.y));

    tex2Dstore(s_OutDepths0, pixCoord + uint2(0, 0), depth0);
    tex2Dstore(s_OutDepths0, pixCoord + uint2(1, 0), depth1);
    tex2Dstore(s_OutDepths0, pixCoord + uint2(0, 1), depth2);
    tex2Dstore(s_OutDepths0, pixCoord + uint2(1, 1), depth3);

    // MIP 1
    float dm1 = DepthMIPFilter(depth0, depth1, depth2, depth3);
    tex2Dstore(s_OutDepths1, baseCoord, dm1);
    g_scratchDepths[gtid.x + gtid.y * 8] = dm1;

    barrier();

    // MIP 2
    [branch]
    if (all((gtid.xy % 2) == 0)) {
        float inTL = g_scratchDepths[(gtid.x + 0) + (gtid.y + 0) * 8];
        float inTR = g_scratchDepths[(gtid.x + 1) + (gtid.y + 0) * 8];
        float inBL = g_scratchDepths[(gtid.x + 0) + (gtid.y + 1) * 8];
        float inBR = g_scratchDepths[(gtid.x + 1) + (gtid.y + 1) * 8];

        float dm2 = DepthMIPFilter(inTL, inTR, inBL, inBR);
        tex2Dstore(s_OutDepths2, baseCoord / 2, dm2);
        g_scratchDepths[gtid.x + gtid.y * 8] = dm2;
    }

    barrier();

    // MIP 3
    [branch]
    if (all((gtid.xy % 4) == 0)) {
        float inTL = g_scratchDepths[(gtid.x + 0) + (gtid.y + 0) * 8];
        float inTR = g_scratchDepths[(gtid.x + 2) + (gtid.y + 0) * 8];
        float inBL = g_scratchDepths[(gtid.x + 0) + (gtid.y + 2) * 8];
        float inBR = g_scratchDepths[(gtid.x + 2) + (gtid.y + 2) * 8];

        float dm3 = DepthMIPFilter(inTL, inTR, inBL, inBR);
        tex2Dstore(s_OutDepths3, baseCoord / 4, dm3);
        g_scratchDepths[gtid.x + gtid.y * 8] = dm3;
    }

    barrier();
    
    // MIP 4
    [branch]
    if (all((gtid.xy % 8) == 0)) {
        float inTL = g_scratchDepths[(gtid.x + 0) + (gtid.y + 0) * 8];
        float inTR = g_scratchDepths[(gtid.x + 4) + (gtid.y + 0) * 8];
        float inBL = g_scratchDepths[(gtid.x + 0) + (gtid.y + 4) * 8];
        float inBR = g_scratchDepths[(gtid.x + 4) + (gtid.y + 4) * 8];

        float dm4 = DepthMIPFilter(inTL, inTR, inBL, inBR);
        tex2Dstore(s_OutDepths4, baseCoord / 8, dm4);
    }
}

float4 CalculateEdges(const float centerZ, const float leftZ, const float rightZ, const float topZ, const float bottomZ) {
    float4 edgesLRTB = float4(leftZ, rightZ, topZ, bottomZ) - centerZ;

    float slopeLR = (edgesLRTB.y - edgesLRTB.x) * 0.5f;
    float slopeTB = (edgesLRTB.w - edgesLRTB.z) * 0.5f;
    float4 edgesLRTBSlopeAdjusted = edgesLRTB + float4(slopeLR, -slopeLR, slopeTB, -slopeTB);
    edgesLRTB = min(abs(edgesLRTB), abs(edgesLRTBSlopeAdjusted));

    return float4(saturate((1.25 - edgesLRTB / (centerZ * 0.011))));
}

float4 PackEdges(float4 edges) {
    edges = round( saturate( edges ) * 2.9 );
    return dot( edges, float4( 64.0 / 255.0, 16.0 / 255.0, 4.0 / 255.0, 1.0 / 255.0 ) ) ;
}

float3 ComputeViewspacePosition(const float2 screenPos, const float viewspaceDepth) {
    float3 pos;

    pos.xy = screenPos.xy * viewspaceDepth;
    pos.z = viewspaceDepth;

    return pos;
}

float4 R8G8B8A8_UNORM_to_FLOAT4(uint packedInput)
{
    float4 unpackedOutput;
    unpackedOutput.x = (packedInput & 0x000000ff) / 255.0f;
    unpackedOutput.y = (((packedInput >> 8) & 0x000000ff)) / 255.0f;
    unpackedOutput.z = (((packedInput >> 16) & 0x000000ff)) / 255.0f;
    unpackedOutput.w = (packedInput >> 24) / 255.0f;
    return unpackedOutput;
}

void DecodeVisibilityBentNormal(const uint packedValue, out float visibility, out float3 bentNormal) {
    float4 decoded = R8G8B8A8_UNORM_to_FLOAT4(packedValue);
    bentNormal = decoded.xyz * 2.0f - 1.0f;
    visibility = decoded.w;
}

uint FLOAT4_to_R8G8B8A8_UNORM(float4 unpackedInput)
{
    return ((uint(saturate(unpackedInput.x) * 255.0f + 0.5f)) |
            (uint(saturate(unpackedInput.y) * 255.0f + 0.5f) << 8) |
            (uint(saturate(unpackedInput.z) * 255.0f + 0.5f) << 16) |
            (uint(saturate(unpackedInput.w) * 255.0f + 0.5f) << 24));
}

uint EncodeVisibilityBentNormal(float visibility, float3 bentNormal) {
    return FLOAT4_to_R8G8B8A8_UNORM(float4(bentNormal * 0.5f + 0.5f, visibility));
}

void OutputWorkingTerm(uint2 pixCoord, float visibility, float3 bentNormal) {
    visibility = saturate(visibility / 1.5f);
    tex2Dstore(s_OutWorkingAO, pixCoord, EncodeVisibilityBentNormal(visibility, bentNormal));
}

float3 CalculateNormal(float4 edgesLRTB, float3 pixCenterPos, float3 pixLPos, float3 pixRPos, float3 pixTPos, float3 pixBPos) {
    float4 acceptedNormals  = saturate(float4(edgesLRTB.x * edgesLRTB.z, edgesLRTB.z * edgesLRTB.y, edgesLRTB.y * edgesLRTB.w, edgesLRTB.w * edgesLRTB.x) + 0.01);

    pixLPos = normalize(pixLPos - pixCenterPos);
    pixRPos = normalize(pixRPos - pixCenterPos);
    pixTPos = normalize(pixTPos - pixCenterPos);
    pixBPos = normalize(pixBPos - pixCenterPos);

    float3 pixelNormal =  acceptedNormals.x * cross(pixLPos, pixTPos) +
                          acceptedNormals.y * cross(pixTPos, pixRPos) +
                          acceptedNormals.z * cross(pixRPos, pixBPos) +
                          acceptedNormals.w * cross(pixBPos, pixLPos);
    
    return normalize(pixelNormal);
}

float FastSqrt(float x) {
    return (float)(asfloat(0x1fbd1df5 + (asint(x) >> 1))); 
}

float FastACos(float inX) {
    float x = abs(inX); 
    float res = -0.156583 * x + HALF_PI; 
    res *= FastSqrt(1.0 - x); 
    return (inX >= 0) ? res : PI - res; 
}

void CS_MainPass(uint3 tid : SV_DISPATCHTHREADID) {
    const float2 viewportPixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    float2 normalizedScreenPos = (tid.xy + 0.5f) * viewportPixelSize;

    float4 valuesUL = tex2DgatherR(OutDepths0, float2(tid.xy * viewportPixelSize));
    float4 valuesBR = tex2DgatherR(OutDepths0, float2(tid.xy * viewportPixelSize), int2(1, 1));

    float viewspaceZ = valuesUL.y;

    float pixLZ = valuesUL.x;
    float pixTZ = valuesUL.z;
    float pixRZ = valuesUL.z;
    float pixBZ = valuesUL.x;
    
    float4 edgesLRTB = CalculateEdges(viewspaceZ, pixLZ, pixRZ, pixTZ, pixBZ);
    tex2Dstore(s_OutEdges, tid.xy, PackEdges(edgesLRTB));

    float3 center = ComputeViewspacePosition(normalizedScreenPos, viewspaceZ);
    float3 left   = ComputeViewspacePosition(normalizedScreenPos + float2(-1,  0) * viewportPixelSize, pixLZ);
    float3 right  = ComputeViewspacePosition(normalizedScreenPos + float2( 1,  0) * viewportPixelSize, pixRZ);
    float3 top    = ComputeViewspacePosition(normalizedScreenPos + float2( 0, -1) * viewportPixelSize, pixTZ);
    float3 bottom = ComputeViewspacePosition(normalizedScreenPos + float2( 0,  1) * viewportPixelSize, pixBZ);
    
    float3 viewspaceNormal = CalculateNormal(edgesLRTB, center, left, right, top, bottom);
    //tex2Dstore(s_OutEdges, tid.xy, float4(viewspaceNormal, 1.0f));
    viewspaceZ *= 0.99999;

    const float3 viewVec = normalize(-center);

    const float effectRadius = _EffectRadius * _RadiusMultiplier;
    const float sampleDistributionPower = _SampleDistributionPower;
    const float thinOccluderCompensation = _ThinOccluderCompensation;
    const float falloffRange = _EffectFalloffRange * effectRadius;

    const float falloffFrom = effectRadius * (1.0f - _EffectFalloffRange);

    const float falloffMul = -1.0f / falloffRange;
    const float falloffAdd = falloffFrom / falloffRange + 1.0f;

    float visibility = 0.0f;
    float3 bentNormal = 0;

    float2 localNoise = SpatioTemporalNoise(tid.xy, 0);

    const float noiseSlice = localNoise.x;
    const float noiseSample = localNoise.y;

    const float pixelTooCloseThreshold = 1.3f;
    const float2 pixelDirRBViewspaceSizeAtCenterZ = viewspaceZ * viewportPixelSize;
    float screenspaceRadius = effectRadius / pixelDirRBViewspaceSizeAtCenterZ.x;
    
    visibility += saturate((10.0f - screenspaceRadius) / 100.0f) * 0.5f;

    const float minS = pixelTooCloseThreshold / screenspaceRadius;

    const int sliceCount = 9;
    const int stepsPerSlice = 3;

    [unroll]
    for (int slice = 0; slice < sliceCount; ++slice) {
        float sliceK = (slice + noiseSlice) / sliceCount;
        
        float phi = sliceK * PI;
        float cosPhi = cos(phi);
        float sinPhi = sin(phi);
        float2 omega = float2(cosPhi, -sinPhi);

        omega *= screenspaceRadius;

        float3 directionVec = float3(cosPhi, sinPhi, 0);
        float3 orthoDirectionVec = directionVec - (dot(directionVec, viewVec) * viewVec);

        float3 axisVec = normalize(cross(orthoDirectionVec, viewVec));
        float3 projectedNormalVec = viewspaceNormal - axisVec * dot(viewspaceNormal, axisVec);

        float signNorm = (float)sign(dot(orthoDirectionVec, projectedNormalVec));

        float projectedNormalVecLength = length(projectedNormalVec);
        float cosNorm = (float)saturate(dot(projectedNormalVec, viewVec) / projectedNormalVecLength);

        float n = signNorm * FastACos(cosNorm);

        const float lowHorizonCos0 = cos(n + HALF_PI);
        const float lowHorizonCos1 = cos(n - HALF_PI);

        float horizonCos0 = lowHorizonCos0;
        float horizonCos1 = lowHorizonCos1;
        
        [unroll]
        for (int step = 0; step < stepsPerSlice; ++step) {
            const float stepBaseNoise = (float)(slice + step * stepsPerSlice) * 0.6180339887498948482f;
            float stepNoise = frac(noiseSample + stepBaseNoise);

            float s = (step + stepNoise) / (stepsPerSlice);
            s = (float)pow(s, sampleDistributionPower);
            s += minS;

            float2 sampleOffset = s * omega;
            float sampleOffsetLength = length(sampleOffset);

            float mipLevel = (float)clamp(log2(sampleOffsetLength) - _MipSamplingOffset, 0, 5);
            sampleOffset = round(sampleOffset) * viewportPixelSize;

            float2 sampleScreenPos0 = normalizedScreenPos + sampleOffset;
            float SZ0 = tex2Dfetch(OutDepths0, sampleScreenPos0 * float2(BUFFER_WIDTH, BUFFER_HEIGHT)).r;
            float3 samplePos0 = ComputeViewspacePosition(sampleScreenPos0, SZ0);

            float2 sampleScreenPos1 = normalizedScreenPos - sampleOffset;
            float SZ1 = tex2Dfetch(OutDepths0, sampleScreenPos1 * float2(BUFFER_WIDTH, BUFFER_HEIGHT)).r;
            float3 samplePos1 = ComputeViewspacePosition(sampleScreenPos1, SZ1);

            float3 sampleDelta0 = (samplePos0 - float3(center));
            float3 sampleDelta1 = (samplePos1 - float3(center));
            float sampleDist0 = (float)length(sampleDelta0);
            float sampleDist1 = (float)length(sampleDelta1);

            float3 sampleHorizonVec0 = (float3)(sampleDelta0 / sampleDist0);
            float3 sampleHorizonVec1 = (float3)(sampleDelta1 / sampleDist1);

            float falloffBase0 = length(float3(sampleDelta0.x, sampleDelta0.y, sampleDelta0.z * (1.0f + thinOccluderCompensation)));
            float falloffBase1 = length(float3(sampleDelta1.x, sampleDelta1.y, sampleDelta1.z * (1.0f + thinOccluderCompensation)));
            float weight0 = saturate(falloffBase0 * falloffMul + falloffAdd);
            float weight1 = saturate(falloffBase1 * falloffMul + falloffAdd);

            float shc0 = (float)dot(sampleHorizonVec0, viewVec);
            float shc1 = (float)dot(sampleHorizonVec1, viewVec);

            shc0 = lerp(lowHorizonCos0, shc0, weight0);
            shc1 = lerp(lowHorizonCos1, shc1, weight1);

            horizonCos0 = max(horizonCos0, shc0);
            horizonCos1 = max(horizonCos1, shc1);
        }

        projectedNormalVecLength = lerp(projectedNormalVecLength, 1.0f, 0.5f);

        float h0 = -FastACos(horizonCos1);
        float h1 = FastACos(horizonCos0);

        float iarc0 = (cosNorm + 2.0f * h0 * sin(n) - cos(2.0f * h0 - n)) / 4.0f;
        float iarc1 = (cosNorm + 2.0f * h1 * sin(n) - cos(2.0f * h1 - n)) / 4.0f;
        float localVisibility = projectedNormalVecLength * (iarc0 + iarc1);
        visibility += localVisibility;

        // Compute Bent Normal
        float t0 = (6*sin(h0-n)-sin(3*h0-n)+6*sin(h1-n)-sin(3*h1-n)+16*sin(n)-3*(sin(h0+n)+sin(h1+n)))/12;
        float t1 = (-cos(3 * h0-n)-cos(3 * h1-n) +8 * cos(n)-3 * (cos(h0+n) +cos(h1+n)))/12;
        float3 localBentNormal = float3(directionVec.x * t0, directionVec.y * t0, -t1);
        localBentNormal = mul(RotFromToMatrix(float3(0, 0, -1), viewVec), localBentNormal) * projectedNormalVecLength;
        bentNormal += localBentNormal;
    }

    visibility /= sliceCount;
    visibility = pow(visibility, _FinalValuePower);
    visibility = max(0.03, visibility);
    bentNormal = normalize(bentNormal);

    OutputWorkingTerm(tid.xy, visibility, bentNormal);
}

float4 UnpackEdges(float _packedVal) {
    uint packedVal = (uint)(_packedVal * 255.5);
    float4 edgesLRTB;
    edgesLRTB.x = (float)((packedVal >> 6) & 0x03) / 3.0;
    edgesLRTB.y = (float)((packedVal >> 4) & 0x03) / 3.0;
    edgesLRTB.z = (float)((packedVal >> 2) & 0x03) / 3.0;
    edgesLRTB.w = (float)((packedVal >> 0) & 0x03) / 3.0;

    return saturate(edgesLRTB);
}

void DecodeGatherPartial(const uint4 packedValue, out float4 outDecoded[4]) {
    for (int i = 0; i < 4; ++i) {
        DecodeVisibilityBentNormal(packedValue[i], outDecoded[i].w, outDecoded[i].xyz);
    }
}

void AddSample(float4 ssaoValue, float edgeValue, inout float4 sum, inout float sumWeight) {
    float weight = edgeValue;

    sum += (weight * ssaoValue);
    sumWeight += weight;
}

void AO_Output(uint2 pixCoord, float4 outputValue, bool finalApply) {
    float visibility = outputValue.w * ((finalApply) ? (1.5f) : (1));
    float3 bentNormal = normalize(outputValue.xyz);
    tex2Dstore(s_AOOutput, pixCoord, float4(bentNormal, visibility));
}

void CS_Denoise(uint2 tid : SV_DISPATCHTHREADID) {
    const float2 viewportPixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    const uint2 pixCoordBase = tid * uint2(2, 1);

    bool finalApply = true;

    const float blurAmount = (finalApply) ? DENOISE_BLUR : (DENOISE_BLUR / 5.0f);
    const float diagWeight = 0.85f * 0.5f;

    float4 aoTerm[2];
    float4 edgesC_LRTB[2];
    float weightTL[2];
    float weightTR[2];
    float weightBL[2];
    float weightBR[2];

    const float2 gatherCenter = pixCoordBase * viewportPixelSize;

    float4 edgesQ0 = tex2DgatherR(OutEdges, gatherCenter, int2(0, 0));
    float4 edgesQ1 = tex2DgatherR(OutEdges, gatherCenter, int2(2, 0));
    float4 edgesQ2 = tex2DgatherR(OutEdges, gatherCenter, int2(1, 2));

    float4 visQ0[4]; DecodeGatherPartial(tex2DgatherR(OutWorkingAO, gatherCenter, int2(0, 0)), visQ0);
    float4 visQ1[4]; DecodeGatherPartial(tex2DgatherR(OutWorkingAO, gatherCenter, int2(2, 0)), visQ1);
    float4 visQ2[4]; DecodeGatherPartial(tex2DgatherR(OutWorkingAO, gatherCenter, int2(0, 2)), visQ2);
    float4 visQ3[4]; DecodeGatherPartial(tex2DgatherR(OutWorkingAO, gatherCenter, int2(2, 2)), visQ3);

    [unroll]
    for (int side = 0; side < 2; ++side) {
        const int2 pixCoord = int2(pixCoordBase.x + side, pixCoordBase.y);

        float4 edgesL_LRTB = UnpackEdges((side == 0) ? (edgesQ0.x) : (edgesQ0.y));
        float4 edgesT_LRTB = UnpackEdges((side == 0) ? (edgesQ0.z) : (edgesQ1.w));
        float4 edgesR_LRTB = UnpackEdges((side == 0) ? (edgesQ1.x) : (edgesQ1.y));
        float4 edgesB_LRTB = UnpackEdges((side == 0) ? (edgesQ2.w) : (edgesQ2.z));

        edgesC_LRTB[side] = UnpackEdges((side == 0) ? (edgesQ0.y) : (edgesQ1.x));
        edgesC_LRTB[side] *= float4(edgesL_LRTB.y, edgesR_LRTB.x, edgesT_LRTB.w, edgesB_LRTB.z);
        
        const float leak_threshold = 2.5; 
        const float leak_strength = 0.5;
        
        float edginess = (saturate(4.0f - leak_threshold - dot(edgesC_LRTB[side], 1.0f)) / (4.0f - leak_threshold)) * leak_strength;
        edgesC_LRTB[side] = saturate(edgesC_LRTB[side] + edginess);

        weightTL[side] = diagWeight * (edgesC_LRTB[side].x * edgesL_LRTB.z + edgesC_LRTB[side].z * edgesT_LRTB.x);
        weightTR[side] = diagWeight * (edgesC_LRTB[side].z * edgesT_LRTB.y + edgesC_LRTB[side].y * edgesR_LRTB.z);
        weightBL[side] = diagWeight * (edgesC_LRTB[side].w * edgesB_LRTB.x + edgesC_LRTB[side].x * edgesL_LRTB.w);
        weightBR[side] = diagWeight * (edgesC_LRTB[side].y * edgesR_LRTB.w + edgesC_LRTB[side].w * edgesB_LRTB.y);

        // first pass
        float4 ssaoValue     = (side == 0) ? (visQ0[1]) : (visQ1[0]);
        float4 ssaoValueL    = (side == 0) ? (visQ0[0]) : (visQ0[1]);
        float4 ssaoValueT    = (side == 0) ? (visQ0[2]) : (visQ1[3]);
        float4 ssaoValueR    = (side == 0) ? (visQ1[0]) : (visQ1[1]);
        float4 ssaoValueB    = (side == 0) ? (visQ2[2]) : (visQ3[3]);
        float4 ssaoValueTL   = (side == 0) ? (visQ0[3]) : (visQ0[2]);
        float4 ssaoValueBR   = (side == 0) ? (visQ3[3]) : (visQ3[2]);
        float4 ssaoValueTR   = (side == 0) ? (visQ1[3]) : (visQ1[2]);
        float4 ssaoValueBL   = (side == 0) ? (visQ2[3]) : (visQ2[2]);

        float sumWeight = blurAmount;
        float4 sum = ssaoValue * sumWeight;

        AddSample(ssaoValueL, edgesC_LRTB[side].x, sum, sumWeight);
        AddSample(ssaoValueR, edgesC_LRTB[side].y, sum, sumWeight);
        AddSample(ssaoValueT, edgesC_LRTB[side].z, sum, sumWeight);
        AddSample(ssaoValueB, edgesC_LRTB[side].w, sum, sumWeight);

        AddSample(ssaoValueTL, weightTL[side], sum, sumWeight);
        AddSample(ssaoValueTR, weightTR[side], sum, sumWeight);
        AddSample(ssaoValueBL, weightBL[side], sum, sumWeight);
        AddSample(ssaoValueBR, weightBR[side], sum, sumWeight);

        aoTerm[side] = sum / sumWeight;

        AO_Output(pixCoord, aoTerm[side], finalApply);
    }
}

float4 PS_ApplyAO(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(Common::AcerolaBuffer, uv);
    float visibility = tex2D(AOOutput, uv).w;

    return float4(col.rgb * saturate(visibility), col.a);
}

technique SSAO {
    pass PrefilterDepths {
        ComputeShader = CS_PrefilterDepths<8, 8>;
        DispatchSizeX = (BUFFER_WIDTH + 15) / 16;
        DispatchSizeY = (BUFFER_HEIGHT + 15) / 16;
    }

    pass MainPass {
        ComputeShader = CS_MainPass<NUM_THREADS_X, NUM_THREADS_Y>;
        DispatchSizeX = (BUFFER_WIDTH + NUM_THREADS_X - 1) / NUM_THREADS_X;
        DispatchSizeY = (BUFFER_HEIGHT + NUM_THREADS_Y - 1) / NUM_THREADS_Y;
    }

    pass Denoise {
        ComputeShader = CS_Denoise<NUM_THREADS_X, NUM_THREADS_Y>;
        DispatchSizeX = (BUFFER_WIDTH + (NUM_THREADS_X * 2) - 1) / (NUM_THREADS_X * 2);
        DispatchSizeY = (BUFFER_HEIGHT + NUM_THREADS_Y - 1) / NUM_THREADS_Y;
    }

    pass ApplyAO {
        RenderTarget = AOTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_ApplyAO;
    }

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}