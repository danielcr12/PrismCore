#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]]
half4 parameterizedNoise(
    float2 position,
    half4 color,
    float intensity,
    float frequency,
    float opacity
) {
    float2 scaledPos = fmod(position * frequency, float2(10000.0, 10000.0));
    float n = fract(52.9829189 * fract(dot(scaledPos, float2(0.06711056, 0.00583715))));

    float overlay = (n - 0.5) * 2.0 * intensity;
    float3 base = float3(color.rgb);
    float3 noisy = clamp(base + overlay, 0.0, 1.0);
    float3 blended = mix(base, noisy, clamp(opacity, 0.0, 1.0));
    return half4(half3(blended), color.a);
}

[[ stitchable ]]
half4 debandingDither(float2 position, half4 color) {
    float3 magic = float3(0.06711056, 0.00583715, 52.9829189);
    float n = fract(magic.z * fract(dot(position, magic.xy)));
    float dither = (n - 0.5) * (1.0 / 255.0);
    float3 result = clamp(float3(color.rgb) + dither, 0.0, 1.0);
    return half4(half3(result), color.a);
}
