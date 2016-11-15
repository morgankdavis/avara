# avara

The beginning of a clone of the 1996 classic Mac game [Avara by Ambrosia software.](https://en.wikipedia.org/wiki/Avara)

The project is written in Swift 2.2, uses SceneKit for rendering and physics, a handful of other tools for things like UDP networking and direct mouse input, and includes targets for OS X (main), iOS and tvOS (the latter two require an MFi gamepad).

The intention of this project was mainly to get me introduced to 3D graphics and game development, with an eye on writing my own engine eventually.

Not a whole lot has been done visually, but instead focus was put on building out an appropriate architecture, and in making solid netcode central from the beginning.

I had to abandon the prpject about a year ago when I determined that the way SceneKit did physics simulation was not going to work in my networking modal. That's just as well, as now I've moved onto learning about OpenGL proper!

Please excuse any swearing you may find in the source code. I did not audit it before making it public :)