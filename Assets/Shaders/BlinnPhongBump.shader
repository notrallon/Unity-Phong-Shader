// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unlit/BlinnPhongBump"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}

		_BumpMap("Normal map", 2D) = "bump" {}
		_BumpDepth("Depth", Range(0.0, 2.0)) = 0.1

		_Ambient("Intensity", Range(0.0, 1.0)) = 0.1
		_AmbientColor("Color", color) = (1.0, 1.0, 1.0, 1.0)

		_Diffuse("Diffuse", Range(0.0, 1.0)) = 1.0

		[Toggle] _Specular("Specualar", Float) = 0.0
		_Shininess("Specular intensity", Range(0.1, 100)) = 1
		_SpecColor("Specular color", color) = (1.0, 1.0, 1.0, 1.0)


	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }
		LOD 100

		// Directional light
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature __ _SPECULAR_ON


			struct appdata {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float3 tangentWorld : TEXCOORD2;
				float3 normal : TEXCOORD3;
				float3 binormalWorld : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;

			fixed4 _LightColor0;

			// Diffuse variables
			fixed _Diffuse;
			// fixed4 _DifColor; // we're not using this yet

			// Ambient variables
			fixed _Ambient;
			fixed4 _AmbientColor;

			fixed _BumpDepth;

			// Specular variables
			fixed _Shininess;
			fixed4 _SpecColor;

			v2f vert(appdata v) {
				v2f o;
				// World position
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				// Clip position
				o.vertex = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1.));

				// Normal in WorldSpace
				o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				o.tangentWorld = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormalWorld = normalize(cross(o.normal, o.tangentWorld) * v.tangent.w);

				o.uv = v.texcoord;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				//return fixed4(i.uv.x, i.uv.y, 0, 1);

				// Grab the color of the pixel on screen
				fixed4 col = tex2D(_MainTex, _MainTex_ST.xy * i.uv.xy + _MainTex_ST.zw);


				float4 encodedNormal = tex2D(_BumpMap, _BumpMap_ST.xy * i.uv.xy + _BumpMap_ST.zw);
				float3 localCoords = float3(2.0 * encodedNormal.a - 1.0, 2.0 * encodedNormal.g - 1.0, 0.0);
				localCoords.z = sqrt(1.0 - dot(localCoords, localCoords));

				float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normal);
				float3 normalDir = normalize(mul(localCoords, local2WorldTranspose));

				//return fixed4(normalDir * col.xyz, col.a);

				// normal = worldNormal
				float3 normal = normalize(mul(localCoords, local2WorldTranspose));
				//float3 normal = normalize(i.normal);

				// The direction of the lightning
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				// Camera direction
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

				// Compute ambient lighting
				fixed4 amb = _Ambient * _AmbientColor;

				// normal = worldNormal
				//float3 normal = normalize(i.normal);
				float3 worldPos = normalize(i.worldPos.xyz);

				// Compute diffuse ligting
				fixed4 NdotL = saturate((dot(normal, lightDir) - _Ambient) * _LightColor0);
				fixed4 dif = _Ambient + NdotL * 1 * _Diffuse * _LightColor0;

				fixed4 light = dif + amb;

				// Compute specular light if it's checked
				#if _SPECULAR_ON
				float3 halfVector = normalize(lightDir + viewDir);
				float NdotH = max(0., dot(normal, halfVector));
				fixed4 spec = pow(NdotH, _Shininess) * _LightColor0 * _SpecColor;

				light += spec;
				#endif

				//return light;
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);

				col.rgb *= light.rgb;

				return col;
			}
			ENDCG
		}

		// Pass for point lights
		Pass
		{
			Tags{ "LightMode" = "ForwardAdd" }

			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature __ _SPECULAR_ON

			struct appdata {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float3 tangentWorld : TEXCOORD2;
				float3 normal : TEXCOORD3;
				float3 binormalWorld : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;

			fixed4 _LightColor0;

			fixed _BumpDepth;

			// Diffuse variables
			fixed _Diffuse;
			// fixed4 _DifColor; // we're not using this yet

			// Ambient variables
			fixed _Ambient;
			fixed4 _AmbientColor;

			// Specular variables
			fixed _Shininess;
			fixed4 _SpecColor;

			v2f vert(appdata v) {
				v2f o;
				// World position
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				// Clip position
				o.vertex = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1.));
				//o.vertex = mul(unity_WorldToObject, v.vertex);
				//o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

				// Normal in WorldSpace
				//o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);

				o.tangentWorld = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormalWorld = normalize(cross(o.normal, o.tangentWorld) * v.tangent.w);

				o.uv = v.texcoord;

				return o;
			}

			fixed4 frag(v2f i) : COLOR{

				fixed4 encodedNormal = tex2D(_BumpMap, _BumpMap_ST.xy * i.uv.xy + _BumpMap_ST.zw);
				float3 localCoords = float3(2.0 * encodedNormal.ag - float2(1, 1), 0.0);
				localCoords.z = _BumpDepth;//1.0 - 0.5 * dot(localCoords, localCoords);

				float3x3 localToWorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normal);
				float3 normalDir = normalize(mul(localCoords, localToWorldTranspose));

				//return fixed4(normalDir * col.xyz, col.a);

				// normal = worldNormal
				//float3 normal = normalize(mul(localCoords, local2WorldTranspose));
				float3 normal = normalize(i.normal);
				float3 worldPos = normalize(i.worldPos);

				// Camera direction
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);


				// The direction of the lightning
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

			
				// Point light direction
				float3 pointLightDir = _WorldSpaceLightPos0.xyz - i.worldPos.xyz;
				float pointLightLength = length(pointLightDir);

				lightDir = normalize(pointLightDir) * _WorldSpaceLightPos0.w;

				// Compute ambient lighting
				fixed4 amb = _Ambient * _AmbientColor;// +unity_AmbientSky + UNITY_LIGHTMODEL_AMBIENT;

				float attenuation = 1 / pointLightLength;


				// Compute diffuse ligting
				fixed4 NdotL = saturate((dot(normalDir, normalize(pointLightDir))) * _LightColor0);
				fixed4 diffuseColor = NdotL * _Diffuse * _LightColor0 * attenuation;
				//float3 diffuseColor = lerp(fixed4(0,0,0,0), _LightColor0.rgb * max(0, dot(normal, pointLightDir) * amb * attenuation), sqrt(_WorldSpaceLightPos0.w));

				fixed4 light = diffuseColor * amb * attenuation;//fixed4(normalize(diffuseColor) * amb * attenuation, attenuation);

					// Compute specular light if it's checked
				#if _SPECULAR_ON
				//return fixed4(normal, 0);
				float3 halfVector = normalize(pointLightDir + viewDir);
				float NdotH = saturate(dot(normalDir, halfVector));
				//fixed4 spec = pow(NdotH, _Shininess) * _LightColor0 * _SpecColor * attenuation;
				//float4 spec = float4(attenuation * _LightColor0.rgb * _SpecColor.rgb * pow(NdotH, _Shininess), 1);
				fixed4 spec = fixed4(diffuseColor * _SpecColor.xyz * pow(saturate(dot(reflect(-pointLightDir, normalDir), viewDir)), _Shininess), 0);
				//fixed4 spec = lerp(pow(NdotH, _Shininess) * _LightColor0 * _SpecColor, pow(NdotH, _Shininess) * _LightColor0 * _SpecColor, _WorldSpaceLightPos0.w);
				light += spec;

				#endif
				return light;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
