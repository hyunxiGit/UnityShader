# UnityShader
update :
-Voumn rendering with ray marching , wip
![Image of software ray march volumen](https://github.com/hyunxiGit/UnityShader/blob/master/readmeImg/voulem%20fog%20wip.gif)

-software ray marching volumen with z plane alignment

![Image of software ray march volumen](https://github.com/hyunxiGit/UnityShader/blob/master/readmeImg/software_raymarch_volumen.gif)

-volumen builder plugin for creating uniyt 3d texture from texture atler

![Image volume builder](https://github.com/hyunxiGit/UnityShader/blob/master/readmeImg/volumeassetBuilder.gif)

-PBR / render equation hlsl implementation in 3ds max

![Image volume builder](https://github.com/hyunxiGit/UnityShader/blob/master/readmeImg/pbr.jpg)

-ray marching displacement with two point interpolation

![Image of raymatching](https://github.com/hyunxiGit/UnityShader/blob/master/readmeImg/raymarchingDis.gif)

a seriers of learning shaders / scripts aim to learn the rendering pipeline of Unity
forward, deferred, shadows, translucent ...

There are a lot of shader in the repository. They are created for the purpos of understanding Unity/ general commercial engine rendering pipeline.

To refer the original tutorial
catLikeCoding
https://catlikecoding.com/unity/tutorials/rendering/

My version is a little bit different from place to place as these are my way of understanding the rendering.
My implementation aims to give a clear idea the meaning of each steps. Optimization is avoid as detailed optimization shadows the original algorithm and math meaning.

To use this package,
create a Unity project in your local drive, clone the repository and overwrite the asset folder with the repository.

Also, along the process of writiting these shader I write a Unity rendering cookbook. 
This cookbook provide a quick reference for solving a common problem like:
how to create vertex light
how to create reflection
how to do transparent shadow
...

It also provides some explaination of Unity background work like:

How Unity handel postprocess
How Unity do defer rendering

The cookbook might be helpful to the ones who is learning Unity shader, I put the googledoc link here:
https://docs.google.com/document/d/1e8QrC7O2QIXjDiG8zIQbFDn7qBQOmDhwqsVZnDHhrRU/edit?usp=sharing

The cook book is still WIP so there might be some inaccuracy.


