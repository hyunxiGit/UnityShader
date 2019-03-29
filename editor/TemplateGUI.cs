using UnityEngine;
using UnityEditor;
public class TemlateGUI : ShaderGUI {
	
	Material target;
	MaterialEditor editor;
	MaterialProperty[] properties;

	MaterialProperty FindProperty(string propertyName )
	{
		return FindProperty(propertyName , this.properties);
	}

	GUIContent makeLabel(MaterialProperty property, string tooltip = "" )
	{
		//initiate
		GUIContent label = new GUIContent();
		label.text = property.displayName;
		label. tooltip = tooltip;
		return label;
	}

	void seKeywords(string keyword , bool state)
	{
		if (state)
		{
			this.target.EnableKeyword(keyword);	
		}
		else
		{
			this.target.DisableKeyword(keyword);	
		}
	}

	enum SmoothnessSource
	{
		Uniform , Albedo , Metallic
	}
	
	public override void OnGUI (MaterialEditor editor, MaterialProperty[] properties) 
	{
		//render default material editor
		//base.OnGUI(editor, properties);

		//reference
		this.target = editor.target as Material;
		this.editor = editor;
		this.properties = properties;

		//label
		GUILayout.Label("Main Maps",EditorStyles.boldLabel);

		//find property
		MaterialProperty albedoPro = FindProperty("_Albedo");
		MaterialProperty tint = FindProperty("_Tint" );

		// make label from property
		GUIContent albedoMapLabel = makeLabel(albedoPro,"albedo map");

		//add texturemap to GUI
		editor.TexturePropertySingleLine(albedoMapLabel, albedoPro , tint);

		//texture scale and offset , GUI indent
		EditorGUI.indentLevel +=2;
		editor.TextureScaleOffsetProperty(albedoPro);
		EditorGUI.indentLevel -=2;

		//show property depend on the texture value
		MaterialProperty normalPro = FindProperty("_Normal");
		editor.TexturePropertySingleLine(makeLabel(normalPro), normalPro, normalPro.textureValue?FindProperty("_NormalScale"):null);

		//slider
		// MaterialProperty metalicPro = FindProperty("_Metalic");
		// editor.ShaderProperty(metalicPro, makeLabel(metalicPro));

		//adjust shader feature by texture value
		EditorGUI.BeginChangeCheck();
		MaterialProperty metalicPro = FindProperty("_Metalic");
		MaterialProperty metalicMapPro = FindProperty("_MetalicMap");
		editor.TexturePropertySingleLine(makeLabel(metalicMapPro), metalicMapPro ,metalicMapPro.textureValue ? null : metalicPro);
		if (EditorGUI.EndChangeCheck())
		{
			seKeywords("_METALIC_MAP" , metalicMapPro.textureValue);			
		}

		//dropdown menu
		//initiate options
		SmoothnessSource source = SmoothnessSource.Uniform;
		if (this.target.IsKeywordEnabled("_SMOOTHNESS_ALBEDO"))
		{
			source = SmoothnessSource.Albedo;
		}
		else if (this.target.IsKeywordEnabled("_SMOOTHNESS_METALLIC"))
		{
			source = SmoothnessSource.Metallic;	
		}

		EditorGUI.BeginChangeCheck();
		source = (SmoothnessSource)EditorGUILayout.EnumPopup("Source",source);
		if(EditorGUI.EndChangeCheck())
		{
			seKeywords("_SMOOTHNESS_ALBEDO" , source == SmoothnessSource.Albedo);
			seKeywords("_SMOOTHNESS_METALLIC" , source == SmoothnessSource.Metallic);
		}
	}

}