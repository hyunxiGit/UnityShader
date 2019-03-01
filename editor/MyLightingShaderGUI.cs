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
		MaterialProperty metalicMap = FindProperty("_MetalicMap");
		MaterialProperty metalic = FindProperty("_Metalic");
		editor.TexturePropertySingleLine(MakeLabel(metalicMap , "metalic map (grey)"), metalicMap,  metalicMap.textureValue? null : metalic);
		
		EditorGUI.BeginChangeCheck();
		if (EditorGUI.EndChangeCheck())
		{
			SetKeyword("_METALIC_MAP", metalicMap.textureValue);	
		}
		// EditorGUI.indentLevel +=2;
		// editor.ShaderProperty(metalic, MakeLabel(metalic , "metalness"));
		// EditorGUI.indentLevel -=2;
	}
	void DoRoughness()
	{
		MaterialProperty rough = FindProperty("_Roughness");
		EditorGUI.indentLevel +=2;
		editor.ShaderProperty(rough , MakeLabel(rough , "roughness"));
		EditorGUI.indentLevel -=2;
	}
	void DoMain() 
	{
		GUILayout.Label("Main Maps",EditorStyles.boldLabel);

		MaterialProperty albedo = FindProperty("_Albedo");
		MaterialProperty tint =  FindProperty("_Tint");
	    editor.TexturePropertySingleLine(MakeLabel(albedo , "albedo (RGB)"), albedo, tint);

		DoNormals();
		DoMetalic();
		DoRoughness();
		editor.TextureScaleOffsetProperty(albedo);

		GUILayout.Label("Secondary Maps",EditorStyles.boldLabel);
		DoSecondary();
	}


}