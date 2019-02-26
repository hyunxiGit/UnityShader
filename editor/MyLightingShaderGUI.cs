using UnityEngine;
using UnityEditor;
public class MyLightingShaderGUI : ShaderGUI {
	public override void OnGUI (
	MaterialEditor editor, MaterialProperty[] properties) 
	{
		DoMain();
	}

	void DoMain() 
	{
		GUILayout.Label("Main Maps");
	}
}