static const float3x3 protanomaly0  = float3x3(
    float3(1.0f, 0.0f, 0.0f),
    float3(0.0f, 1.0f, 0.0f),
    float3(0.0f, 0.0f, 1.0f)
);

static const float3x3 ACESInputMat = float3x3(
    float3(0.59719, 0.35458, 0.04823),
    float3(0.07600, 0.90834, 0.01566),
    float3(0.02840, 0.13383, 0.83777)
);

static const float3x3 protanomaly01  = float3x3(
     float3(0.856167,  0.182038, -0.038205),
     float3(0.029342,  0.955115,  0.015544),
    float3(-0.002880, -0.001563,  1.004443)
);

static const float3x3 protanomaly02  = float3x3(
     float3(0.734766,  0.334872, -0.069637),
     float3(0.051840,  0.919198,  0.028963),
    float3(-0.004928, -0.004209,  1.009137)
);

static const float3x3 protanomaly03  = float3x3(
     float3(0.630323,  0.465641, -0.095964),
     float3(0.069181,  0.890046,  0.040773),
    float3(-0.006308, -0.007724,  1.014032)
);

static const float3x3 protanomaly04  = float3x3(
     float3(0.539009,  0.579343, -0.118352),
     float3(0.082546,  0.866121,  0.051332),
    float3(-0.007136, -0.011959,  1.019095)
);

static const float3x3 protanomaly05  = float3x3(
     float3(0.458064,  0.679578, -0.137642),
     float3(0.092785,  0.846313,  0.060902),
    float3(-0.007494, -0.016807,  1.024301)
);

static const float3x3 protanomaly06  = float3x3(
     float3(0.385450,  0.769005, -0.154455),
    float3( 0.100526,  0.829802,  0.069673),
    float3(-0.007442, -0.022190,  1.029632)
);

static const float3x3 protanomaly07  = float3x3(
     float3(0.319627,  0.849633, -0.169261),
     float3(0.106241,  0.815969,  0.077790),
    float3(-0.007025, -0.028051,  1.035076)
);

static const float3x3 protanomaly08  = float3x3(
     float3(0.259411,  0.923008, -0.182420),
     float3(0.110296,  0.804340,  0.085364),
    float3(-0.006276, -0.034346,  1.040622)
);

static const float3x3 protanomaly09  = float3x3(
     float3(0.203876,  0.990338, -0.194214),
     float3(0.112975,  0.794542,  0.092483),
    float3(-0.005222, -0.041043,  1.046265)
);

static const float3x3 protanomaly10  = float3x3(
     float3(0.152286,  1.052583, -0.204868),
    float3( 0.114503,  0.786281,  0.099216),
    float3(-0.003882, -0.048116,  1.051998)
);

static const float3x3 protanomalySeverities[11] = {
    protanomaly0,
    protanomaly01,
    protanomaly02,
    protanomaly03,
    protanomaly04,
    protanomaly05,
    protanomaly06,
    protanomaly07,
    protanomaly08,
    protanomaly09,
    protanomaly10
};