# Makefile to wrangle dependencies between engine components

BINDINGS=gl_bindings gl2_bindings

all: run_genmk $(BINDINGS)
	$(MAKE) -f modules.mk

cinlaunch:
	$(MAKE) -f modules.mk cinlaunch

build_genmk:
	$(MAKE) -C genmk

run_genmk: build_genmk
	./genmk/genmk render scene model audio util math perlin opengl engine window

gl_bindings: bindings/opengl.json
	python bindings/mgenbind.py bindings/opengl.json
	mv opengl.m opengl

gl2_bindings: bindings/opengl2.json
	python bindings/mgenbind.py bindings/opengl2.json
	mv opengl2.m opengl

clean:
	$(MAKE) -f modules.mk clean
	$(MAKE) -C genmk clean
	rm *.err

.PHONY: clean run_genmk build_genmk $(BINDINGS)
.IGNORE: clean
.SILENT: clean
