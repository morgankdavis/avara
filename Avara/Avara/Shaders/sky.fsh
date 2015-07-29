void main(
    uniform float4 k_skyColor : COLOR,
    uniform float4 k_horizonColor : COLOR,
    uniform float4 k_groundColor : COLOR,
    uniform float4 k_gradientHeight,
    in float3 l_vector,
    out float4 o_color : COLOR)
{
    float phi = normalize(l_vector).y;
    if (phi <= 0.0) {
        o_color = k_groundColor;
    }
    else if (phi > k_gradientHeight[0]) {
        o_color = k_skyColor;
    }
    else {
        float gradientValue = phi / k_gradientHeight[0];
        o_color = k_skyColor * gradientValue + k_horizonColor * (1.0 - gradientValue);
    }
}