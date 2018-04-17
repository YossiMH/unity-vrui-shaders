// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef VRUISHARED_CGINC
#define VRUISHARED_CGINC

#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"
#include "UnityUI.cginc"

#pragma multi_compile __ UNITY_UI_ALPHACLIP
			
struct appdata_t
{
	float4 vertex   : POSITION;
	float4 color    : COLOR;
	float2 texcoord : TEXCOORD0;
};

struct v2f
{
	float4 vertex   : SV_POSITION;
	fixed4 color    : COLOR;
	half2 texcoord  : TEXCOORD0;
	float4 worldPosition : TEXCOORD1;
};
			
fixed4 _Color;
fixed4 _TextureSampleAdd;
float4 _ClipRect;

v2f vert(appdata_t IN)
{
	v2f OUT;
	OUT.worldPosition = IN.vertex;
	OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

	OUT.texcoord = IN.texcoord;
				
	#ifdef UNITY_HALF_TEXEL_OFFSET
	OUT.vertex.xy += (_ScreenParams.zw-1.0)*float2(-1,1);
	#endif
				
	OUT.color = IN.color * _Color;
	return OUT;
}

sampler2D _MainTex;
#ifdef VRUI_OCCLUDED_ALPHA
float _OcclusionAlpha;
#endif

fixed4 frag(v2f IN) : SV_Target
{
	#ifdef VRUI_OCCLUDED_STIPPLED

		// Help from http://answers.unity3d.com/questions/39803/how-to-get-an-objects-position-in-screen-space-in.html

		// get clip space coords of the origin:
		float4 pixelCoordinates = UnityObjectToClipPos( IN.worldPosition );

		// get screen coords from clip space coords:
		pixelCoordinates.xy /= pixelCoordinates.w;

		// Pixel corodinates
		pixelCoordinates.xy = 0.5 * (pixelCoordinates.xy + 1.0) * _ScreenParams.xy;

		if( uint(pixelCoordinates.x) % 2 == 0 )
		{
			discard;
		}

		if (uint(pixelCoordinates.y) % 2 == 0)
		{
			discard;
		}

#endif

	half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;
				
	color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				
	#ifdef UNITY_UI_ALPHACLIP
	clip (color.a - 0.001);
	#endif

	#ifdef VRUI_OCCLUDED_ALPHA
		color.a *= _OcclusionAlpha;
	#endif

	return color;
}

#endif