Shader "Hidden/ShadowMap"
{
    Properties { }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        /**/
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"


            struct appdata
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                half4 color: COLOR;
            };

            
            struct v2f
            {
                float4 vertex: POSITION;
                float2 depth: TEXCOORD1;
                half4 color: TEXCOORD2;
                half4 worldPos: TEXCOORD3;
            };

            float3 worldLightVector;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = o.vertex.zw;

                o.worldPos = o.vertex; // mul(unity_WorldToObject, v.vertex);

                o.color = v.color;
                return o;
            }

            fixed4 frag(v2f i): SV_Target
            {
                //discard;
                float depth = i.worldPos.z / i.worldPos.w;
                // float depth = i.depth.x / i.depth.y;
                return half4(EncodeFloatRG(depth), i.color.b, 0);
            }
            ENDCG

        }

        /*
        */
        // 单独平滑明暗边界，可和上述Pass合并。
        // Pass
        // {
            //     //ZTest Always

            //     CGPROGRAM

            //     #pragma vertex vert
            //     #pragma fragment frag


            //     #include "UnityCG.cginc"

            //     struct appdata
            //     {
                //         float4 vertex: POSITION;
                //         float3 normal: NORMAL;
                //     };

                //     struct v2g
                //     {
                    //         float4 vertex: POSITION;
                    //         float4 normal: NORMAL;
                    //         int isVisible: TEXCOORD0;
                    //     };

                    //     struct g2f
                    //     {
                        //         float4 vertex: SV_POSITION;
                        //         float depth: TEXCOORD0;
                        //     };

                        //     struct SilhouetteVertex
                        //     {
                            //         float3 position;
                            //         float3 normal;
                            //     };

                            //     float3 worldLightVector;

                            //     SilhouetteVertex computeSilhouetteVertex(v2g point1, v2g point2, float3 viewDir)
                            //     {
                                //         float3 V1 = point1.vertex.xyz;
                                //         float3 V2 = point2.vertex.xyz;

                                //         float3 N1 = point1.normal.xyz;
                                //         float3 N2 = point2.normal.xyz;

                                //         float3 T1 = (V2 - V1) - dot(V2 - V1, N1) * N1;
                                //         float3 T2 = (V2 - V1) - dot(V2 - V1, N2) * N2;

                                //         float3 D = viewDir;

                                //         SilhouetteVertex result;
                                //         //计算出平行光的u0，并保存在result.w中。
                                //         float u0 = dot(D, N1) / (dot(D, N1) - dot(D, N2));
                                //         //计算出S(u)和N(u) u=u0的结果，并保存在result中。
                                //         result.position = (2 * V1 - 2 * V2 + T1 + T2) * u0 * u0 * u0 - (3 * V1 - 3 * V2 + 2 * T1 + T2) * u0 * u0 + T1 * u0 + V1;
                                //         result.normal = normalize((1 - u0) * N1 + u0 * N2);

                                //         return result;
                                //     }

                                //     v2g vert(appdata v)
                                //     {
                                    //         v2g o;
                                    //         o.vertex = mul(unity_ObjectToWorld, v.vertex);
                                    //         o.normal = float4(mul((float3x3)unity_ObjectToWorld, v.normal), 0);
                                    //         o.isVisible = step(0, dot(worldLightVector, o.normal.xyz));
                                    //         return o;
                                    //     }


                                    //     fixed4 frag(g2f i): SV_Target
                                    //     {
                                        //         return half4(EncodeFloatRG(i.depth), 0, 0);
                                        //     }
                                        //     ENDCG

                                        // }

                                    }
                                }
