void main(
    uniform float4x4 mat_modelproj,
    in float4 vtx_position : POSITION,
    uniform float4 mspos_camera,
    uniform float4x4 wstrans_sky,
    out float3 l_vector,
    out float4 l_position : POSITION)
{
    l_position = mul(mat_modelproj, vtx_position);
    l_vector = mul(wstrans_sky, vtx_position).xyz;// - float3(mspos_camera.x, 0.0, mspos_camera.z);
}