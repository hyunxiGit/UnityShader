using System.IO;
using System.Collections;
using System.Collections.Generic;

using UnityEngine;
using UnityEditor;

namespace VolumeRendering
{
    public class d3_d2_volumn_info
    {
        //2dtexture width / height
        public int d2_w;
        public int d2_h;
        public int d2_r;
        public int d2_c;

        //3dtexture w/h/depth
        public int d3_w;
        public int d3_h;
        public int d3_d;

        //d2 d3 coordinate structure
        public struct d2_coord
        {
            public int x ;
            public int y ;

            public d2_coord(int _x, int _y)
            {
                x = _x;
                y = _y;
            }
        };

        public struct d3_coord
        {
            public int x ;
            public int y ;
            public int z ;
            public d3_coord(int _x, int _y, int _z)
            {
                x = _x;
                y = _y;
                z = _z;
            }
        };

        public d3_d2_volumn_info (int d2_w, int d2_h, int d2_r, int d2_c)
        {
            this.d2_w = d2_w;
            this.d2_h = d2_h;
            this.d2_r = d2_r;
            this.d2_c = d2_c;

            this.d3_w = this.d2_w / this.d2_c;
            this.d3_h = this.d2_h / this.d2_r;
            this.d3_d = this.d2_c * this.d2_r;
        }

        public d3_d2_volumn_info (int d3_w, int d3_h, int d3_d, int d2_r, int d2_c)
        {
            this.d3_w = d3_w;
            this.d3_h = d3_h;
            this.d3_d = d3_d;

            this.d2_r = d2_r;
            this.d2_c = d2_c;

            this.d2_w = this.d3_w * this.d2_c;
            this.d2_h = this.d3_h * this.d2_r;
        }

        public void d3_to_d2_pix_cood(d3_coord d3c, ref d2_coord d2c)
        {
            if ((d3c.x > this.d3_w) ||(d3c.y > this.d3_h) || (d3c.z > this.d3_d))
            {
                d2c.x = -1;
                d2c.y = -1;
            }

            int main_index = d3c.z * this.d3_w * this.d3_h + d3c.y * this.d3_w + d3c.x;
            d2c.x = main_index % this.d2_w;
            d2c.y = main_index / this.d2_w; 
            // Debug.Log("main_index  :" + main_index );
            // Debug.Log("d2c.x :" + d2c.x);
            // Debug.Log("d2c.y :" + d2c.y);
        }
    }

    public class VolumeAssetBuilder : EditorWindow {

        [MenuItem("Window/VolumeAssetBuilder")]
        static void Init()
        {
            var window = EditorWindow.GetWindow(typeof(VolumeAssetBuilder));
            window.Show();
        }

        string inputPath, outputPath;
        int row = 12, column = 12;
        Object source_texture;

        void OnEnable()
        {
            inputPath = "Assets/texture/T_Volume_Wisp_01.tga";
            outputPath = "Assets/T_Volume_Wisp_01.asset";

            //Load a Texture (Assets/Resources/Textures/texture01.png)
            // var texture = Resources.Load<Texture2D>("T_Volume_Wisp_01");
            // Debug.Log("texture load:" + texture);
            // if (texture == null)
            // {
            //     Debug.Log("failed!");

            // }
            // else
            // {
            //     Debug.Log("OK");
                // for(int i = 0 ; i<texture.width; i++)
                // {
                //     for(int j = 0 ; j<texture.height; j++)
                //     {
                //         Color pixel = texture.GetPixel(i,j);
                //         Debug.Log("pixel =" + pixel);
                //     }   
                // }
            //}


        }

        void OnGUI()
        {
            const float headerSize = 120f;
            
            using(new EditorGUILayout.HorizontalScope())
            {
                GUILayout.Label("Input Image", GUILayout.Width(headerSize));
                source_texture = EditorGUILayout.ObjectField(source_texture, typeof(Object), true);
                inputPath = AssetDatabase.GetAssetPath(source_texture);
            }

            // using(new EditorGUILayout.HorizontalScope())
            // {
            //     GUILayout.Label("Width", GUILayout.Width(headerSize));
            //     width = EditorGUILayout.IntField(width);
            // }

            // using(new EditorGUILayout.HorizontalScope())
            // {
            //     GUILayout.Label("Height", GUILayout.Width(headerSize));
            //     height = EditorGUILayout.IntField(height);
            // }

            // using(new EditorGUILayout.HorizontalScope())
            // {
            //     GUILayout.Label("Depth", GUILayout.Width(headerSize));
            //     depth = EditorGUILayout.IntField(depth);
            // }

            using(new EditorGUILayout.HorizontalScope())
            {
                GUILayout.Label("Output path", GUILayout.Width(headerSize));
                outputPath = EditorGUILayout.TextField(outputPath);
            }

            if(GUILayout.Button("Build"))
            {
                Build(source_texture, outputPath);
            }
        }

        void Build( Object myAsset, string outputPath)
        {
            if (myAsset == null)
            {
                Debug.LogWarning("input source texture is empty");
                return;
            }
            source_texture = EditorGUILayout.ObjectField(source_texture, typeof(Object), true);
            Texture2D myTexture = (Texture2D)source_texture;

            var volume = Build(myTexture, row,column);
            AssetDatabase.CreateAsset(volume, outputPath);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }




        public static Texture3D Build(Texture2D myTexture,int row, int column)
        {
            d3_d2_volumn_info v_info = new d3_d2_volumn_info (myTexture.width, myTexture.height, row, column);
            Debug.Log("v_info.d3_w :" + v_info.d3_w);
            Debug.Log("v_info.d3_h :" + v_info.d3_h);
            Debug.Log("v_info.d3_d :" + v_info.d3_d);

            var tex  = new Texture3D(v_info.d3_w, v_info.d3_h, v_info.d3_d, TextureFormat.RGBA32, false);
            tex.wrapMode = TextureWrapMode.Clamp;
            tex.filterMode = FilterMode.Bilinear;
            tex.anisoLevel = 0;

            //int i = 0;
            Color[] colors = new Color[v_info.d3_w * v_info.d3_h * v_info.d3_d];
            float inv = 1f / 255.0f;

            for(int z = 0 ; z< v_info.d3_d; z++)
            {
                for(int y = 0 ; y< v_info.d3_h; y++)
                {
                    for(int x = 0 ; x< v_info.d3_w ; x++)
                    {
                        //convert 3d to 3d coord
                        d3_d2_volumn_info.d2_coord d2c = new d3_d2_volumn_info.d2_coord(-1,-1);
                        d3_d2_volumn_info.d3_coord d3c = new d3_d2_volumn_info.d3_coord(x,y,z);

                        v_info.d3_to_d2_pix_cood(d3c, ref d2c);                         
                        
                        // if (z == 15)
                        // {
                        //     Debug.Log("d2c : "+"x=" + d2c.x+ ", y=" + d2c.y);
                        //     Debug.Log("d3c : "+"x=" + d3c.x+ ", y=" + d3c.y + ", z=" + d3c.z);
                        // }
                        
                        colors[z* v_info.d3_w *v_info.d3_h + y * v_info.d3_w +x] = myTexture.GetPixel(d2c.x,d2c.y);
                    }
                }   
            }

            tex.SetPixels(colors);
            Debug.Log("colors");
            tex.Apply();

            return tex;
        }

    }

}


