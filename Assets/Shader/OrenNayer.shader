Shader "Unlit/OrenNayer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
             _Roughness("Roughness", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdbase

                #include "UnityCG.cginc"
            // Files below include macros and functions to assist
            // with lighting and shadows.
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // Defined in Autolight.cginc. Assigns the above shadow coordinate
                // by transforming the vertex from world space to shadow-map space.
                TRANSFER_SHADOW(o)
                    return o;
                return o;
            }

            float4 _Color;
            float _Roughness;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                float3 viewDir = normalize(i.viewDir);
               


                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

              

                float roughness = _Roughness;
                float roughnessSqr = roughness * roughness;
                float3 o_n_fraction = roughnessSqr / (roughnessSqr
                    + float3(0.33, 0.13, 0.09));
                float3 oren_nayar = float3(1, 0, 0) + float3(-0.5, 0.17, 0.45)
                    * o_n_fraction;
                float cos_ndotl = saturate(dot(normal, _WorldSpaceLightPos0));
                float cos_ndotv = saturate(dot(normal, viewDir));
                float oren_nayar_s = saturate(dot(_WorldSpaceLightPos0, viewDir))
                    - cos_ndotl * cos_ndotv;
                oren_nayar_s /= lerp(max(cos_ndotl, cos_ndotv), 1,
                    step(oren_nayar_s, 0));


                float shadow = SHADOW_ATTENUATION(i);
                float lightIntensity = cos_ndotl * (oren_nayar.x + _Color * oren_nayar.y + oren_nayar.z * oren_nayar_s) ;
                float4 light = lightIntensity * _LightColor0;

                return (light+ UNITY_LIGHTMODEL_AMBIENT) *col*_Color;
            }
            ENDCG
        }
                UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
