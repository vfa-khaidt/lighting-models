Shader "Unlit/Specular"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
            [HDR]
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
            // Controls the size of the specular reflection.
         _Glossiness("Glossiness", Float) = 32
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
            float4 _SpecularColor;
            float _Glossiness;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                float3 viewDir = normalize(i.viewDir);
                float NdotL = saturate(dot(_WorldSpaceLightPos0, normal));

                float shadow = SHADOW_ATTENUATION(i);
                float lightIntensity =  NdotL ;
                float4 light = lightIntensity * _LightColor0;


                // Calculate specular reflection.
                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = saturate(dot(normal, halfVector));
                // Multiply _Glossiness by itself to allow artist to use smaller
                // glossiness values in the inspector.
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = specularIntensity;
                float4 specular = specularIntensitySmooth * _SpecularColor;

                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return (UNITY_LIGHTMODEL_AMBIENT+specular) *col*_Color;
            }
            ENDCG
        }
                UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
