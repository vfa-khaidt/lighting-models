Shader "Unlit/OrenNayerFull"
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

            float orenNayar(float3 N,float3 L, float3 V, float NdotL, float NdotV, float Roughness1) 
            {
                float theta_r = acos(NdotV);
                float theta_i = acos(NdotL);

                float cos_phi_diff = saturate(dot(normalize(V - N * NdotV), normalize(L - N * NdotL)));

                float alpha = max(theta_i, theta_r);
                float beta = min(theta_i, theta_r);

                float A = 1.0 - 0.5 * Roughness1 / (Roughness1 + 0.33);
                float B = 0.45* Roughness1/ (Roughness1 + 0.09);

                return saturate(NdotL) * (A + B * sin(alpha) * tan(beta));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                float3 viewDir = normalize(i.viewDir);
               


                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

              

                float roughness = _Roughness;
                
                float NdotL = saturate(dot(_WorldSpaceLightPos0, normal));
                float NdotV = saturate(dot(normal, viewDir));

                float shadow = SHADOW_ATTENUATION(i);
                float lightIntensity = orenNayar(normal, _WorldSpaceLightPos0,viewDir, NdotL, NdotV, roughness);
                float4 light = lightIntensity * _LightColor0;

                return (light+ UNITY_LIGHTMODEL_AMBIENT) *col*_Color;
            }
            ENDCG
        }
                UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
