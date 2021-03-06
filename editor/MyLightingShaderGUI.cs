using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class MyLightingShaderGUI : ShaderGUI {
	
	Material target;
	MaterialEditor editor;
	MaterialProperty[] properties;


	MaterialProperty FindProperty(string name)
	{
		return FindProperty(name,properties);
	}
	
	static GUIContent MakeLabel(MaterialProperty mproperty, string tooltip = null)
	{
		GUIContent staticLabel = new GUIContent();
		staticLabel.text = mproperty.displayName;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}
	bool IsKeywordEnable (string keyword)
	{
		return target.IsKeywordEnabled(keyword);
	}

	public override void OnGUI (MaterialEditor editor, MaterialProperty[] properties) 
	{
		this.target = editor.target as Material;
		this.editor = editor;
		this.properties = properties;
		DoMain();
	}
	void SetKeyword(string keyword , bool state)
	{
		if (state)
		{
			target.EnableKeyword(keyword);
		}
		else
		{
			target.DisableKeyword(keyword);
		}
	}

	void DoNormals()
	{
		MaterialProperty normal = FindProperty("_Normal");
		editor.TexturePropertySingleLine(MakeLabel(normal,"normal map"), normal, normal.textureValue?FindProperty("_BumpScale"):null);
	}

	enum RenderingMode{Opaque, Cutout,Fade,Transparent}

	struct RenderingSettings
	{
		public RenderQueue queue;
		public string renderType;
		public int SrcBlend;
		public int DstBlend;
		public int zWrite;
		public static RenderingSettings[] modes = {
			new RenderingSettings(RenderQueue.Geometry , "",BlendMode.One , BlendMode.Zero , 1),
			new RenderingSettings(RenderQueue.AlphaTest , "TransparentCutout",BlendMode.One , BlendMode.Zero , 1),
			new RenderingSettings(RenderQueue.Transparent , "Transparent" , BlendMode.SrcAlpha , BlendMode.OneMinusSrcAlpha , 0),
			new RenderingSettings(RenderQueue.Transparent , "Transparent" , BlendMode.One , BlendMode.OneMinusSrcAlpha , 0)
		};
		public RenderingSettings (RenderQueue q, string t,BlendMode src, BlendMode dst, int zWri)
		{
			queue = q;
			renderType = t;
			SrcBlend = (int)src;
			DstBlend = (int)dst;
			zWrite = zWri;
		}
	}

	RenderingMode DoRenderMode()
	{
		RenderingMode mode = RenderingMode.Opaque;
		if (IsKeywordEnable("_RENDERING_CUTOUT"))
		{
			mode = RenderingMode.Cutout;
		}
		else if(IsKeywordEnable("_RENDERING_FADE"))
		{
			mode = RenderingMode.Fade;	
		}
		else if(IsKeywordEnable("_RENDERING_TRANSPARENT"))
		{
			mode = RenderingMode.Transparent;	
		}
		EditorGUI.BeginChangeCheck();
		mode = (RenderingMode)EditorGUILayout.EnumPopup("Render Mode", mode);
		if(EditorGUI.EndChangeCheck())
		{
			SetKeyword("_RENDERING_CUTOUT",mode == RenderingMode.Cutout);
			SetKeyword("_RENDERING_FADE",mode == RenderingMode.Fade);
			SetKeyword("_RENDERING_TRANSPARENT",mode == RenderingMode.Transparent);

			RenderingSettings set = RenderingSettings.modes[(int)mode];

			foreach(Material m in editor.targets)
			{
				m.renderQueue = (int)set.queue;
				m.SetOverrideTag("RenderType", set.renderType);
				m.SetInt("_ScrBlend" , set.SrcBlend);
				m.SetInt("_DstBlend" , set.DstBlend);
				m.SetInt("_ZWri" , set.zWrite);
			}

		}
		return mode;
	}

	void DoClip()
	{
		MaterialProperty clipped = FindProperty("_Cutoff");
	    editor.ShaderProperty(clipped, "clip range");
	}
	
	void DoMetalic()
	{
		EditorGUI.BeginChangeCheck();
		MaterialProperty metalicMap = FindProperty("_MetalicMap");
		MaterialProperty metalic = FindProperty("_Metalic");
		editor.TexturePropertySingleLine(MakeLabel(metalicMap , "metalic map (grey)"), metalicMap,  metalicMap.textureValue? null : metalic);
		

		if (EditorGUI.EndChangeCheck())
		{
			SetKeyword("_METALIC_MAP", metalicMap.textureValue);	
		}
		// EditorGUI.indentLevel +=2;
		// editor.ShaderProperty(metalic, MakeLabel(metalic , "metalness"));
		// EditorGUI.indentLevel -=2;
	}

	void DoEmission()
	{
		EditorGUI.BeginChangeCheck();
		MaterialProperty emissionMap = FindProperty("_EmissionMap");
		MaterialProperty emission = FindProperty("_Emission");
		// editor.TexturePropertySingleLine(MakeLabel(emissionMap, "emission map") , emissionMap,emissionMap.textureValue ?null: emission);

		//ColorPickerHDRConfig emissionConfig = new ColorPickerHDRConfig(0f,99f,1f/99f,3f);

		// editor.TexturePropertyWithHDRColor
		// (MakeLabel(emissionMap, "emission map"), emissionMap,emission,emissionConfig, false);
		editor.TexturePropertyWithHDRColor(MakeLabel(emissionMap, "emission map"), emissionMap, emission, false);

		if (EditorGUI.EndChangeCheck())
		{
			SetKeyword("_EMISSION_MAP",emissionMap.textureValue);
		}
	}

	enum SmoothnessSource
	{
		Uniform, Albedo, Metalic
	}



	void DoSmoothness()
	{

		MaterialProperty smooth = FindProperty("_Smoothness");
		
		//做一个slider
		EditorGUI.indentLevel +=2;
		editor.ShaderProperty(smooth , MakeLabel(smooth , "smoothness"));
		

		//下拉菜单
		SmoothnessSource source = SmoothnessSource.Uniform;
		if (IsKeywordEnable("_SMOOTHNESS_ALBEDO"))
		{
			source = SmoothnessSource.Albedo;
		}
		else if (IsKeywordEnable("_SMOOTHNESS_METALIC"))
		{
			source = SmoothnessSource.Metalic;	
		}
		EditorGUI.indentLevel +=2;
		EditorGUI.BeginChangeCheck();
		source = (SmoothnessSource)EditorGUILayout.EnumPopup("source", source);
		if (EditorGUI.EndChangeCheck())
		{
			//支持redo undo
			editor.RegisterPropertyChangeUndo("smooth");
			SetKeyword("_SMOOTHNESS_ALBEDO", source == SmoothnessSource.Albedo);
			SetKeyword("_SMOOTHNESS_METALIC", source == SmoothnessSource.Metalic);
		}
		EditorGUI.indentLevel -=4;
	}
	void DoOcclusion()
	{
		EditorGUI.BeginChangeCheck();
		MaterialProperty OcMapPro = FindProperty("_OcclusionMap");
		MaterialProperty OcStrPro = FindProperty("_OcclusionStrength");
		editor.TexturePropertySingleLine(MakeLabel(OcMapPro), OcMapPro, OcMapPro.textureValue?OcStrPro : null);
		if (EditorGUI.EndChangeCheck())
		{
			SetKeyword("_OCCLUSIONMAP ", OcMapPro.textureValue);
		}
	}
	void DoDisplacement()
	{
		EditorGUI.BeginChangeCheck();
		MaterialProperty DisMapPro = FindProperty("_DisplacementMap");
		MaterialProperty DisStrPro = FindProperty("_displacementStrength");
		editor.TexturePropertySingleLine(MakeLabel(DisMapPro), DisMapPro, DisMapPro.textureValue?DisStrPro : null);
		if (EditorGUI.EndChangeCheck())
		{
			SetKeyword("_PARALLAXMAP ", DisMapPro.textureValue);
		}
	}

	void DoDetail()
	{
		EditorGUI.BeginChangeCheck();
		MaterialProperty DeAlbedoMap = FindProperty("_DetailAlbedoMap");
		MaterialProperty DeNormalMap = FindProperty("_DetailNormalMap");
		MaterialProperty DeMaskMap = FindProperty("_DetailMaskMap");

		editor.TexturePropertySingleLine(MakeLabel (DeAlbedoMap ), DeAlbedoMap);
		editor.TexturePropertySingleLine(MakeLabel (DeNormalMap ), DeNormalMap);
		editor.TexturePropertySingleLine(MakeLabel (DeMaskMap ), DeMaskMap);
		editor.TextureScaleOffsetProperty(DeAlbedoMap);
		if(EditorGUI.EndChangeCheck())
		{
			SetKeyword("_DETAIL_MASK", DeMaskMap.textureValue);
			SetKeyword("_DETAIL_ALBEDO", DeAlbedoMap.textureValue);
			SetKeyword("_DETAIL_NORMAL", DeNormalMap.textureValue);
		}
	}

	void DoShadowTransparency()
	{
		EditorGUI.BeginChangeCheck();
		string myLabel = "translucent shadow";
		bool translucentShadow = EditorGUILayout.Toggle(myLabel,IsKeywordEnable("_TRANSLUCENT_SHADOW"));
		if(EditorGUI.EndChangeCheck())
		{
			SetKeyword("_TRANSLUCENT_SHADOW" ,translucentShadow);
		}
	}

	void DoMain() 
	{
		RenderingMode m = DoRenderMode();
		 if (m == RenderingMode.Cutout)
	    {
	    	DoClip();
	    }
	    else if ( m == RenderingMode.Fade ||m == RenderingMode.Transparent)
	    {
	    	DoShadowTransparency();	
	    }

		GUILayout.Label("Main Maps",EditorStyles.boldLabel);

		MaterialProperty albedo = FindProperty("_MainTex");
		MaterialProperty tint =  FindProperty("_Color");
	    editor.TexturePropertySingleLine(MakeLabel(albedo , "albedo (RGB)"), albedo, tint);

		DoNormals();
		DoMetalic();
		DoSmoothness();
		DoEmission();
		editor.TextureScaleOffsetProperty(albedo);
		DoDisplacement();

		GUILayout.Label("detail map" , EditorStyles.boldLabel);
		DoOcclusion();
		DoDetail();
	}

}