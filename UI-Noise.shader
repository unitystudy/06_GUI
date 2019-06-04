// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/Default"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        [PerRendererData] _GradationTex("Gradation Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _GradationTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed2 random2(float2 st) {
                st = float2(dot(st, fixed2(127.1, 311.7)),
                    dot(st, fixed2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float Noise(float2 st)
            {
                float2 p = floor(st);
                float2 f = frac(st);
                float2 u = f * f * (3.0 - 2.0 * f);

                float v00 = random2(p + fixed2(0, 0));
                float v10 = random2(p + fixed2(1, 0));
                float v01 = random2(p + fixed2(0, 1));
                float v11 = random2(p + fixed2(1, 1));

                return lerp(lerp(dot(random2(p + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                    dot(random2(p + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
                    lerp(dot(random2(p + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                        dot(random2(p + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;

                float2 tc = IN.texcoord * float2(-3.0, 1.0);
                float time = 0.1 * _Time.y;
                float noise = sin(tc.y + 
                    abs(Noise((tc + time)*  1.0)) +
                    abs(Noise((tc + time)*  2.0))* 0.5 +
                    abs(Noise((tc + time)*  4.0))* 0.25 +
                    abs(Noise((tc + time)*  8.0))* 0.125 +
                    abs(Noise((tc + time)* 16.0))* 0.0625 +
                    abs(Noise((tc + time)* 32.0))* 0.03125 +
                    abs(Noise((tc + time)* 64.0))* 0.015625 +
                    abs(Noise((tc + time)*128.0))* 0.0078125);
                noise = noise / (1.0 + 0.5 + 0.25); // ê≥ãKâª
                noise = sin(100 * noise);           // é»ñÕólÇÇ¬ÇØÇÈ
                noise = noise * 0.5 + 0.5;          // ê≥ílâª
                color = tex2D(_GradationTex, float2(noise, 0));

                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                return color;
            }
        ENDCG
        }
    }
}
