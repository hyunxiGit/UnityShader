using UnityEngine;
using UnityEditor;

public class MyPracticGUI : ShaderGUI
{
	Material target;
	MaterialEditor editor;
	MaterialProperty[] properties;

    public override void OnGUI(MaterialEditor editor , MaterialProperty[] properties)
    {
    	base.OnGUI(editor , properties);
    	this.target = editor.target as Material;
    	this.editor = editor;
    	this.properties = properties;
    	base.OnGUI(editor, properties);
    	//DoMain();

    }

 //    void DoMain() 
	// {
	// 	GUILayout.Label("Main Maps",EditorStyles.boldLabel);

	// 	MaterialProperty albedo = FindProperty("_Albedo");
	// 	MaterialProperty tint =  FindProperty("_Tint");
	//     editor.TexturePropertySingleLine(MakeLabel(albedo , "albedo (RGB)"), albedo, tint);

	// 	editor.TextureScaleOffsetProperty(albedo);

	// 	GUILayout.Label("Secondary Maps",EditorStyles.boldLabel);
	// 	DoSecondary();
	// }
}
