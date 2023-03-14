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
    float3 keyColor = float3(0.0,0.0,0.0);
    float keyThreshold = 0.0;
    // only when color filter is not at default values:
    if ( !all(g_fColorFilter.rgb==1)
    // only when this pixel is the key color:
    && all(abs(vColor.rgb-keyColor)<=keyThreshold) ) {
        float3 vnoise = GenNoise(uv*g_fScreenSize);

        // find another pixel outwith the radius to sample.
        float2 aspect = float2(g_fScreenSize.x/g_fScreenSize.y,1.0);
        float2 pos = g_fColorFilter.xy;
        float radius = g_fColorFilter.z;
        float2 delta = uv-pos;
        delta.y = vnoise.x*radius;
        float d = length(delta);

        //float modulation = pow(d/radius, 3.0);
        //uv += float2(0.5,0.0)*50.0*vnoise*modulation;

        // offset the uv to outwith the radius
        uv += normalize(delta)*(radius+d);
        // and get a different pixel to render
        vColor = tex2D(s0, uv);
        //vColor.r = vnoise.x;
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
        PixelShader = compile ps_3_0 SatGammaPS(1, 1, 1);
    }
}

// apply brightness/contrast and gamma
technique TeqBrGamma
{
    pass P0
    {
        PixelShader = compile ps_3_0 SatGammaPS(0, 1, 1);
    }
}

// apply brightness/contrast and saturation/color
technique TeqBrSat
{
    pass P0
    {
        PixelShader = compile ps_3_0 SatGammaPS(1, 0, 1);
    }
}


// apply saturation/color filter and gamma
technique TeqSatGamma
{
    pass P0
    {
        PixelShader = compile ps_3_0 SatGammaPS(1, 1, 0);
    }
}

// apply only gamma
technique TeqGamma
{
    pass P0
    {
        PixelShader = compile ps_3_0 SatGammaPS(0, 1, 0);
    }
}

// apply only brightness/contrast
technique TeqBr
{
    pass P0
    {
        PixelShader = compile ps_3_0 SatGammaPS(0, 0, 1);
    }
}

// apply only saturation/color
technique TeqSat
{
    pass P0
    {
        PixelShader = compile ps_3_0 SatGammaPS(1, 0, 0);
    }
}

// plain copy
technique TeqCopy
{
    pass P0
    {
        PixelShader = compile ps_3_0 SatGammaPS(0, 0, 0);
    }
}
