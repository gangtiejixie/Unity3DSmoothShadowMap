Shader "Custom/ShadowMapReceiver"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _ShadowTex ("Texture", 2D) = "black" { }

        _ShadowStrength ("ShadowStrength", float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        /*
        */
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
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex: SV_POSITION;
                float3 normal: NORMAL;
                float4 worldPos: TEXCOORD0;
                float2 uv: TEXCOORD1;
                half4 color: TEXCOORD2;
            };

            float4x4 SHADOW_MAP_VP;
            sampler2D ShadowMapTexture;
            uniform float4 ShadowMapTexture_TexelSize;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ShadowTex;
            float4 _ShadowTex_ST;
            float3 worldLightVector;

            half _ShadowStrength;
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }


            float PCFSample(float depth, float2 uv)
            {
                float shadow = 0.0;

                float shadowMask = tex2D(ShadowMapTexture, uv).b;


                for (int x = -1; x <= 2; ++x)
                {
                    for (int y = -1; y <= 1; ++y)
                    {
                        float4 col = tex2D(ShadowMapTexture, uv + float2(x, y) * ShadowMapTexture_TexelSize.xy);
                        float sampleDepth = DecodeFloatRGBA(col) * shadowMask;
                        shadow += sampleDepth < depth ? _ShadowStrength: 1;
                    }
                }
                return shadow /= 9;
            }




            fixed4 frag(v2f i): SV_Target
            {

                // return i.color.a;
                float d = step(dot(worldLightVector, i.normal), 0);

                fixed4 b = tex2D(_MainTex, i.uv);
                fixed4 s = tex2D(_ShadowTex, i.uv);
                //计算NDC坐标
                fixed4 ndcpos = mul(SHADOW_MAP_VP, i.worldPos);
                ndcpos.xyz = ndcpos.xyz / ndcpos.w;
                //从[-1,1]转换到[0,1]
                float3 uvpos = ndcpos * 0.5 + 0.5;
                // float depth = tex2D(ShadowMapTexture, uvpos.xy).b;
                
                half4 attenuation4;
                half attenuation;

                // attenuation4.x = DecodeFloatRG(tex2D(ShadowMapTexture, uvpos.xy + half2(-0.01, -0.01)).rg);
                // attenuation4.y = DecodeFloatRG(tex2D(ShadowMapTexture, uvpos.xy + half2(-0.01, 0.01)).rg);
                // attenuation4.z = DecodeFloatRG(tex2D(ShadowMapTexture, uvpos.xy + half2(0.01, 0.01)).rg);
                // attenuation4.w = DecodeFloatRG(tex2D(ShadowMapTexture, uvpos.xy + half2(0.01, -0.01)).rg);
                // attenuation = dot(attenuation4, 0.25);
                // attenuation = depth;



                attenuation = PCFSample(ndcpos.z + 0.00005, uvpos.xy) ;

                return lerp(b, s, attenuation);
                //fixed4 color = lerp(0, 1, d * step(depth, ndcpos.z + 0.00005));
                // fixed4 color = lerp(s, b, d * step(attenuation, ndcpos.z + 0.00005));
                // return color;

            }
            ENDCG

        }

        /*
        // 方便在其他视角上生成平滑边界线，用于观察
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2g {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                int    isVisible : TEXCOORD0;
            };

            struct g2f {
                float4 vertex : SV_POSITION;
            };

            struct SilhouetteVertex {
                float3 position;
                float3 normal;
            };
            float3 worldLightVector;

            SilhouetteVertex computeSilhouetteVertex(v2g point1, v2g point2, float3 viewDir) {
                float3 V1 = point1.vertex.xyz;
                float3 V2 = point2.vertex.xyz;

                float3 N1 = point1.normal.xyz;
                float3 N2 = point2.normal.xyz;

                float3 T1 = (V2 - V1) - dot(V2 - V1, N1) * N1;
                float3 T2 = (V2 - V1) - dot(V2 - V1, N2) * N2;

                float3 D = viewDir;

                SilhouetteVertex result;
                //计算出平行光的u0，并保存在result.w中。
                float u0 = dot(D, N1) / (dot(D, N1) - dot(D, N2));
                //计算出S(u)和N(u) u=u0的结果，并保存在result中。
                result.position = (2 * V1 - 2 * V2 + T1 + T2) * u0 * u0 * u0 - (3 * V1 - 3 * V2 + 2 * T1 + T2) * u0 * u0 + T1 * u0 + V1;
                result.normal = (1 - u0) * N1 + u0 * N2;

                return result;
            }

            v2g vert (appdata v) {
                v2g o;
                o.vertex = mul(unity_ObjectToWorld, v.vertex);
                o.normal = float4(mul((float3x3)unity_ObjectToWorld, v.normal), 0);
                o.isVisible = step(0, dot(worldLightVector, o.normal.xyz));
                return o;
            }

            [maxvertexcount(6)]
            void geo(triangle v2g input[3], inout TriangleStream<g2f> stream) {
                g2f o;
                int vertexFlag1 = input[0].isVisible;
                int vertexFlag2 = input[1].isVisible;
                int vertexFlag3 = input[2].isVisible;
                int flag = vertexFlag1 + vertexFlag2 + vertexFlag3;

                if (flag == 0 || flag == 3) {
                    return;
                }

                SilhouetteVertex S1, S2;
                if (vertexFlag1 == 1 && vertexFlag2 == 0 && vertexFlag3 == 1) {
                    S1 = computeSilhouetteVertex(input[1], input[2], worldLightVector);
                    S2 = computeSilhouetteVertex(input[1], input[0], worldLightVector);
                    } else if (vertexFlag1 == 0 && vertexFlag2 == 1 && vertexFlag3 == 0) {
                        S1 = computeSilhouetteVertex(input[1], input[0], worldLightVector);
                        S2 = computeSilhouetteVertex(input[1], input[2], worldLightVector);
                        } else if (vertexFlag1 == 1 && vertexFlag2 == 1 && vertexFlag3 == 0) {
                            S1 = computeSilhouetteVertex(input[2], input[0], worldLightVector);
                            S2 = computeSilhouetteVertex(input[2], input[1], worldLightVector);
                            } else if (vertexFlag1 == 0 && vertexFlag2 == 0 && vertexFlag3 == 1) {
                                S1 = computeSilhouetteVertex(input[2], input[1], worldLightVector);
                                S2 = computeSilhouetteVertex(input[2], input[0], worldLightVector);
                                } else if (vertexFlag1 == 0 && vertexFlag2 == 1 && vertexFlag3 == 1) {
                                    S1 = computeSilhouetteVertex(input[0], input[1], worldLightVector);
                                    S2 = computeSilhouetteVertex(input[0], input[2], worldLightVector);
                                    } else {
                                        S1 = computeSilhouetteVertex(input[0], input[2], worldLightVector);
                                        S2 = computeSilhouetteVertex(input[0], input[1], worldLightVector);
                                    }

                                    float4 v0 = float4(S1.position, 1);
                                    float4 v1 = float4(S1.position + S1.normal * 0.1, 1);
                                    float4 v2 = float4(S2.position, 1);
                                    float4 v3 = float4(S2.position + S2.normal * 0.1, 1);

                                    v0.xyz += normalize(-worldLightVector) * 0.005;
                                    v1.xyz += normalize(-worldLightVector) * 0.005;
                                    v2.xyz += normalize(-worldLightVector) * 0.005;
                                    v3.xyz += normalize(-worldLightVector) * 0.005;

                                    v0 = mul(UNITY_MATRIX_VP, v0);
                                    v1 = mul(UNITY_MATRIX_VP, v1);
                                    v2 = mul(UNITY_MATRIX_VP, v2);
                                    v3 = mul(UNITY_MATRIX_VP, v3);

                                    //o.vertex = v0;
                                    //stream.Append(o);
                                    //o.vertex = v2;
                                    //stream.Append(o);
                                    //stream.RestartStrip();

                                    o.vertex = v3;
                                    stream.Append(o);
                                    o.vertex = v2;
                                    stream.Append(o);
                                    o.vertex = v0;
                                    stream.Append(o);
                                    stream.RestartStrip();
                                    
                                    o.vertex = v0;
                                    stream.Append(o);
                                    o.vertex = v1;
                                    stream.Append(o);
                                    o.vertex = v3;
                                    stream.Append(o);
                                    stream.RestartStrip();
                                }

                                fixed4 frag (g2f i) : SV_Target {
                                    return fixed4(1, 0, 0, 1);
                                }
                                ENDCG
                            }
                            */

                            /*
                            // 模拟得出光照摄像机构成ShadowMap所需要的所有三角面
                            Pass {
                                CGPROGRAM
                                #pragma vertex vert
                                #pragma fragment frag
                                #pragma geometry geo

                                #include "UnityCG.cginc"

                                struct appdata {
                                    float4 vertex : POSITION;
                                };

                                struct v2g {
                                    float4 vertex : POSITION;
                                };

                                struct g2f {
                                    float4 vertex : SV_POSITION;
                                };

                                float3 worldLightVector;

                                v2g vert (appdata v) {
                                    v2g o;
                                    o.vertex = mul(unity_ObjectToWorld, v.vertex);
                                    return o;
                                }

                                [maxvertexcount(3)]
                                void geo(triangle v2g input[3], inout TriangleStream<g2f> stream) {
                                    g2f o;
                                    if (dot(cross(input[0].vertex.xyz - input[1].vertex.xyz, input[0].vertex.xyz - input[2].vertex.xyz), worldLightVector) > 0) {
                                        return;
                                    }
                                    o.vertex = mul(UNITY_MATRIX_VP, input[0].vertex);
                                    stream.Append(o);
                                    o.vertex = mul(UNITY_MATRIX_VP, input[1].vertex);
                                    stream.Append(o);
                                    o.vertex = mul(UNITY_MATRIX_VP, input[2].vertex);
                                    stream.Append(o);
                                    stream.RestartStrip();
                                }

                                fixed4 frag (g2f i) : SV_Target {
                                    return fixed4(1, 1, 1, 1);
                                }
                                ENDCG
                            }
                            */
                        }
                    }
