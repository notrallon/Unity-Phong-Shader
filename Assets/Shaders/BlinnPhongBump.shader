// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unlit/BlinnPhongBump"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}

		_Ambient("Intensity", Range(0.0, 1.0)) = 0.1
		_AmbientColor("Color", color) = (1.0, 1.0, 1.0, 1.0)

		_Diffuse("Diffuse", Range(0.0, 1.0)) = 1.0

		[Toggle] _Specular("Specualar", Float) = 0.0
		_Shininess("Specular intensity", Range(0.1, 100)) = 1
		_SpecColor("Specular color", color) = (1.0, 1.0, 1.0, 1.0)


	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
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
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 normal : TEXCOORD2;
			};

			sampler2D _MainTex;
			//float4 _MainTex_ST;

			fixed4 _LightColor0;

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

				// Normal in WorldSpace
				o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

				o.uv = v.texcoord;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				//return fixed4(i.uv.x, i.uv.y, 0, 1);

				// Grab the color of the pixel on screen
				fixed4 col = tex2D(_MainTex, i.uv);

				// The direction of the lightning
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				// Camera direction
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

				// Compute ambient lighting
				fixed4 amb = _Ambient * _AmbientColor;

				// normal = worldNormal
				float3 normal = normalize(i.normal);
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
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 normal : TEXCOORD2;
			};

			sampler2D _MainTex;
			//float4 _MainTex_ST;

			fixed4 _LightColor0;

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
				o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

				o.uv = v.texcoord;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				// Grab the color of the pixel on screen
				fixed4 col = tex2D(_MainTex, i.uv);

				// normal = worldNormal
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

				float attenuation = 0.5 / pointLightLength / pointLightLength;


				// Compute diffuse ligting
				fixed4 NdotL = saturate((dot(normal, normalize(pointLightDir))) * _LightColor0);
				fixed4 diffuseColor = NdotL * _Diffuse * _LightColor0 * attenuation;
				//float3 diffuseColor = lerp(fixed4(0,0,0,0), _LightColor0.rgb * max(0, dot(normal, pointLightDir) * amb * attenuation), sqrt(_WorldSpaceLightPos0.w));

				fixed4 light = diffuseColor * amb * attenuation;//fixed4(normalize(diffuseColor) * amb * attenuation, attenuation);

					// Compute specular light if it's checked
				#if _SPECULAR_ON
				
				float3 halfVector = normalize(pointLightDir + viewDir);
				float NdotH = saturate(dot(normal, halfVector));
				fixed4 spec = pow(NdotH, _Shininess) * _LightColor0 * _SpecColor * attenuation;
				//fixed4 spec = lerp(pow(NdotH, _Shininess) * _LightColor0 * _SpecColor, pow(NdotH, _Shininess) * _LightColor0 * _SpecColor, _WorldSpaceLightPos0.w);

				light += spec;

				#endif

				//return light;
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);

				col *= light;

				return col;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
