using UnityEngine;
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
	void DoSecondary()
	{
		MaterialProperty second = FindProperty("_Secondary");
	    editor.TexturePropertySingleLine(MakeLabel(second , "secondary (grey)"), second );
	    editor.TextureScaleOffsetProperty(second);
	}
	void DoNormals()
	{
		MaterialProperty normal = FindProperty("_Normal");
		editor.TexturePropertySingleLine(MakeLabel(normal,"normal map"), normal, normal.textureValue?FindProperty("_BumpScale"):null);
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

	bool IsKeywordEnable (string keyword)
	{
		return target.IsKeywordEnabled(keyword);
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
	void DoMain() 
	{
		GUILayout.Label("Main Maps",EditorStyles.boldLabel);

		MaterialProperty albedo = FindProperty("_Albedo");
		MaterialProperty tint =  FindProperty("_Tint");
	    editor.TexturePropertySingleLine(MakeLabel(albedo , "albedo (RGB)"), albedo, tint);

		DoNormals();
		DoMetalic();
		DoSmoothness();
		DoEmission();
		editor.TextureScaleOffsetProperty(albedo);

		GUILayout.Label("Secondary Maps",EditorStyles.boldLabel);
		DoSecondary();
	}

}