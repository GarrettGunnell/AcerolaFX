namespace XeGTAO {

#define AFX_CLIP_FAR (1000.0f)
#define AFX_CLIP_NEAR (1.0f)

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
        float depthLinearizeMul = (AFX_CLIP_FAR * AFX_CLIP_NEAR) / (AFX_CLIP_FAR - AFX_CLIP_NEAR);
        float depthLinearizeAdd = AFX_CLIP_FAR / (AFX_CLIP_FAR - AFX_CLIP_NEAR);

        if (depthLinearizeMul * depthLinearizeAdd < 0)
            depthLinearizeAdd = -depthLinearizeAdd;

        return depthLinearizeMul / (depthLinearizeAdd - depth);
    }

    float ClampDepth(float depth) {
        return clamp(depth, 0.0, 3.402823466e+38);
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

    float4 UnpackEdges(float _packedVal) {
        uint packedVal = (uint)(_packedVal * 255.5);
        float4 edgesLRTB;
        edgesLRTB.x = (float)((packedVal >> 6) & 0x03) / 3.0;
        edgesLRTB.y = (float)((packedVal >> 4) & 0x03) / 3.0;
        edgesLRTB.z = (float)((packedVal >> 2) & 0x03) / 3.0;
        edgesLRTB.w = (float)((packedVal >> 0) & 0x03) / 3.0;

        return saturate(edgesLRTB);
    }

    float3 ComputeViewspacePosition(const float2 screenPos, const float viewspaceDepth, float4 NDCToView) {
        float3 pos;

        pos.xy = (NDCToView.xy * screenPos.xy + NDCToView.zw) * viewspaceDepth;
        pos.z = viewspaceDepth;

        return pos;
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

    float3 R11G11B10_UNORM_to_FLOAT3(uint packedInput) {
        float3 unpackedOutput;
        unpackedOutput.x = (float)((packedInput      ) & 0x000007ff) / 2047.0f;
        unpackedOutput.y = (float)((packedInput >> 11) & 0x000007ff) / 2047.0f;
        unpackedOutput.z = (float)((packedInput >> 22) & 0x000003ff) / 1023.0f;

        return unpackedOutput;
    }

    uint FLOAT3_to_R11G11B10_UNORM(float3 unpackedInput) {
        uint packedOutput;
        packedOutput = ((uint(saturate(unpackedInput.x) * 2047 + 0.5f)) |
                    (uint(saturate(unpackedInput.y) * 2047 + 0.5f) << 11) |
                    (uint(saturate(unpackedInput.z) * 1023 + 0.5f) << 22));

        return packedOutput;
    }

    void DecodeGatherPartial(const uint4 packedValue, out float outDecoded[4]) {
        for (int i = 0; i < 4; ++i) {
            outDecoded[i] = (float)(packedValue[i]) / 255.0f;
        }
    }
}