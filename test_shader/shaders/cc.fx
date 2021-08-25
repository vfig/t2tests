// sw_cc shaders which add temporal noise to reduce (some) banding/posterization artifacts
//
// to use this, copy the file to the "shaders" directory and rename it to cc.fx

static const float3 LUMINANCE_VECTOR = float3(0.2125, 0.7154, 0.0721);

float g_fGamma;
float g_fSaturation;
float g_fContrast;
float g_fBrightness;
float4 g_fColorFilter;
float2 g_fScreenSize;
float g_fNoiseTimer;

// the frame texture
sampler s0 : register(s0);


float NoiseRand(float2 n)
{
    return frac( sin( dot(n.xy, float2(12.9898, 78.233)) )* 43758.5453 );
}

float GenNoise(float2 pos)
{
    float n = NoiseRand(pos + g_fNoiseTimer * 0.01);

    float f = n * 2.0 - 1.0;
    n = rsqrt( abs(f) ) * f;
    n = max(-1.0, n);
    n = n - sign(f);

    return n * (1.0/128.0);
}

float3 Noise(float3 vColor, float2 uv)
{
    uv *= g_fScreenSize;
    vColor.x *= g_fColorFilter.x;
    vColor.y *= g_fColorFilter.y;
    vColor.z *= g_fColorFilter.z;
    return vColor.xyz + GenNoise(uv);
}

float4 SatGammaPS(in float2 uv : TEXCOORD0, uniform int bDoSat, uniform int bDoGamma, uniform int bDoContrBright) : COLOR
{
    // get this pixel color
    float4 vColor = tex2D(s0, uv);
    // effect only enabled when color filter is at default color filter values!
    if (!all(g_fColorFilter.rgb==1)) {

      // Only set one of these to 1!!
      #define NOISE_BLUR 0
      #define DRIPS 1
      #define PIXELATE 0

        float2 aspect = float2(g_fScreenSize.x/g_fScreenSize.y,1.0);
        float2 pos = g_fColorFilter.xy;
        float radius = g_fColorFilter.z;
        //float bigness = 1.0-smoothstep(radius,2*radius,dist);
        float dist = length(uv*aspect-pos*aspect);
        float centeredness = 1.0-saturate(1.414*length(pos-float2(0.5,0.5)));
        float modulation = pow(centeredness,3.0);

      #if NOISE_BLUR
        // using g_fColorFilter as our input parameter, to control noise amplitude
        float3 noise = GenNoise(uv*g_fScreenSize);
        // offset the uvs by the noise
        uv += float2(0.5,0.0)*50.0*noise*modulation;
        // and get a different pixel to render
        vColor = tex2D(s0, uv);
      #endif
      #if DRIPS
        // the effect intensity depends on this pixel brightness
        float brightness = (0.299*vColor.r + 0.587*vColor.g + 0.144*vColor.b);
        float rand = frac(sin(4.0*g_fNoiseTimer)*1000000.0);
        uv += float2(0,brightness)*2.0*modulation;
        uv = fmod(uv, 1.0);
        // and get a different pixel to render
        vColor = tex2D(s0, uv);
      #endif
      #if PIXELATE
        float t = 10.0/modulation;
        uv = trunc(t*uv)/t;
        // and get a different pixel to render
        vColor = tex2D(s0, uv);
      #endif
    }

    if (bDoSat)
    {
        float lumi = dot(vColor.xyz, LUMINANCE_VECTOR);
        vColor.xyz = lerp(lumi.xxx, vColor.xyz, g_fSaturation); // * g_fColorFilter.xyz;
    }
    if (bDoGamma)
    {
        vColor.xyz = pow(vColor.xyz, g_fGamma);
    }
    if (bDoContrBright)
    {
        // old not quite correct contrast formula used in T2 v1.25 / SS2 v2.46 and older
        //vColor.xyz = saturate(vColor.xyz * g_fContrast + g_fBrightness);

        vColor.xyz = saturate((vColor.xyz - 0.5) * g_fContrast + 0.5 + g_fBrightness);
    }

    //vColor.xyz = Noise(vColor.xyz, uv);

    return vColor;
}


// apply saturation/color filter, brightness/contrast and gamma
technique TeqBrSatGamma
{
    pass P0
    {
        PixelShader = compile ps_2_0 SatGammaPS(1, 1, 1);
    }
}

// apply brightness/contrast and gamma
technique TeqBrGamma
{
    pass P0
    {
        PixelShader = compile ps_2_0 SatGammaPS(0, 1, 1);
    }
}

// apply brightness/contrast and saturation/color
technique TeqBrSat
{
    pass P0
    {
        PixelShader = compile ps_2_0 SatGammaPS(1, 0, 1);
    }
}


// apply saturation/color filter and gamma
technique TeqSatGamma
{
    pass P0
    {
        PixelShader = compile ps_2_0 SatGammaPS(1, 1, 0);
    }
}

// apply only gamma
technique TeqGamma
{
    pass P0
    {
        PixelShader = compile ps_2_0 SatGammaPS(0, 1, 0);
    }
}

// apply only brightness/contrast
technique TeqBr
{
    pass P0
    {
        PixelShader = compile ps_2_0 SatGammaPS(0, 0, 1);
    }
}

// apply only saturation/color
technique TeqSat
{
    pass P0
    {
        PixelShader = compile ps_2_0 SatGammaPS(1, 0, 0);
    }
}

// plain copy
technique TeqCopy
{
    pass P0
    {
        PixelShader = compile ps_2_0 SatGammaPS(0, 0, 0);
    }
}
