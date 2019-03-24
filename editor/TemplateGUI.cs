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
		GUIContent label = new GUIContent();
		label.text = property.displayName;
		label. tooltip = tooltip;
		return label;
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
		MaterialProperty albedoProperty = FindProperty("_Albedo");
		MaterialProperty tint = FindProperty("_Tint" );

		// make label from property
		GUIContent albedoMapLabel = makeLabel(albedoProperty,"albedo map");

		//add texturemap to GUI
		editor.TexturePropertySingleLine(albedoMapLabel, albedoProperty , tint);
	}
}