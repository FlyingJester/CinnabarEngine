
OPENGL_SRC=opengl/opengl.m opengl/opengl2.m opengl/opengl.texture.m
.export OPENGL_SRC

opengl2.m: bindings/opengl2.json
	python bindings/mgenbind.py bindings/opengl2.json -p
	mv opengl2.m opengl/opengl2.m

opengl.m: bindings/opengl.json
	python bindings/mgenbind.py bindings/opengl.json -p
	mv opengl.m opengl/opengl.m
