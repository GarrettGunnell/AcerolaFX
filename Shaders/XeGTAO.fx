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

texture2D OutDepths0Tex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; }; 
sampler2D OutDepths0 { Texture = OutDepths0Tex; };
storage2D s_OutDepths0 { Texture = OutDepths0Tex; };

texture2D OutDepths1Tex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = R32F; }; 
sampler2D OutDepths1 { Texture = OutDepths1Tex; };
storage2D s_OutDepths1 { Texture = OutDepths1Tex; };

texture2D OutDepths2Tex { Width = BUFFER_WIDTH / 4; Height = BUFFER_HEIGHT / 4; Format = R32F; }; 
sampler2D OutDepths2 { Texture = OutDepths2Tex; };
storage2D s_OutDepths2 { Texture = OutDepths2Tex; };

texture2D OutDepths3Tex { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = R32F; }; 
sampler2D OutDepths3 { Texture = OutDepths3Tex; };
storage2D s_OutDepths3 { Texture = OutDepths3Tex; };

texture2D OutDepths4Tex { Width = BUFFER_WIDTH / 16; Height = BUFFER_HEIGHT / 16; Format = R32F; }; 
sampler2D OutDepths4 { Texture = OutDepths4Tex; };
storage2D s_OutDepths4 { Texture = OutDepths4Tex; };

texture2D OutEdgesTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
sampler2D OutEdges { Texture = OutEdgesTex; };
storage2D s_OutEdges { Texture = OutEdgesTex; };

#define CLIP_FAR 1000.0f
#define CLIP_NEAR 0.03f

#define NUM_THREADS_X 8
#define NUM_THREADS_Y 8

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

float3 CalculateNormal(float4 edgesLRTB, float3 pixCenterPos, float3 pixLPos, float3 pixRPos, float3 pixTPos, float3 pixBPos) {
    float4 acceptedNormals  = saturate( float4( edgesLRTB.x*edgesLRTB.z, edgesLRTB.z*edgesLRTB.y, edgesLRTB.y*edgesLRTB.w, edgesLRTB.w*edgesLRTB.x ) + 0.01 );

    pixLPos = normalize(pixLPos - pixCenterPos);
    pixRPos = normalize(pixRPos - pixCenterPos);
    pixTPos = normalize(pixTPos - pixCenterPos);
    pixBPos = normalize(pixBPos - pixCenterPos);

    float3 pixelNormal =  acceptedNormals.x * cross( pixLPos, pixTPos ) +
                        + acceptedNormals.y * cross( pixTPos, pixRPos ) +
                        + acceptedNormals.z * cross( pixRPos, pixBPos ) +
                        + acceptedNormals.w * cross( pixBPos, pixLPos );
    pixelNormal = normalize( pixelNormal );

    return pixelNormal; 
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

    viewspaceZ *= 0.99999;

    const float3 viewVec = normalize(-center);

    const float effectRadius = _EffectRadius * _RadiusMultiplier;
    const float sampleDistributionPower = _SampleDistributionPower;
    const float thinOccluderCompensation = _ThinOccluderCompensation;
    const float falloffRange = _EffectFalloffRange * effectRadius;

    const float falloffFrom = effectRadius * (1.0f - _EffectFalloffRange);

    const float falloffMul = -1.0f / falloffRange;
    const float falloffAdd = falloffFrom / falloffRange + 1.0f;

    float visiblity = 0.0f;
    float3 bentNormal = 0;



}

float4 PS_EndPass(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET { 
    //return tex2D(ReShade::DepthBuffer, uv).r; 
    return tex2D(OutEdges, uv); 
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

    pass EndPass {
        RenderTarget = Common::AcerolaBufferTex;

        VertexShader = PostProcessVS;
        PixelShader = PS_EndPass;
    }
}