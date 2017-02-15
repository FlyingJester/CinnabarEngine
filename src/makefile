# Makefile to wrangle dependencies between engine components

all: run_genmk
	$(MAKE) -f modules.mk

build_genmk:
	$(MAKE) -C genmk

run_genmk: build_genmk
	./genmk/genmk render scene model audio util math perlin opengl

clean:
	$(MAKE) -f modules.mk clean
	$(MAKE) -C genmk clean

.IGNORE: clean run_genmk build_genmk
.PHONY: clean
.SILENT: clean
