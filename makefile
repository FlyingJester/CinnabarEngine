all: cinnabar test sinetest

tests: test sinetest

LIBPX?=lib
LIBSX?=so
LIBSA?=a
LIBPA?=$(LIBPX)
INSTALL?=install
GRADE?=asm_fast.par.gc.stseg

MMC?=mmc

MMCFLAGS?=--cflags -g  --ld-flag -g --mercury-linkage static --opt-level 7 --intermodule-optimization 
MMCCALL=$(MMC) $(MMCFLAGS) -L./ --mld lib/mercury --grade=$(GRADE)
MMCIN=$(MMCCALL) -E -j4 --make

GLOW=lib/$(LIBPX)glow.$(LIBSX)
CHRONO=lib/$(LIBPA)chrono.$(LIBSA)
SPHEREFONTS=lib/$(LIBPA)spherefonts.$(LIBSA)
AIMG=lib/$(LIBPA)aimg.$(LIBSA)
BUFFERFILE=lib/$(LIBPA)bufferfile.$(LIBSA)
FJOGG=fjogg/$(LIBPA)fjogg.$(LIBSA)

FJOGGFLAGS=--search-lib-files-dir fjogg --init-file fjogg/fjogg.init --link-object $(FJOGG)

LIBTARGETS=$(GLOW) $(CHRONO) $(SPHEREFONTS) $(AIMG) $(BUFFERFILE) $(FJOGG)

$(GLOW): glow
	scons -j2 -C glow
	$(INSTALL) glow/$(LIBPX)glow.$(LIBSX) lib/$(LIBPX)glow.$(LIBSX)

$(CHRONO): chrono
	scons -j2 -C chrono
	$(INSTALL) chrono/$(LIBPA)chrono.$(LIBSA) lib/$(LIBPA)chrono.$(LIBSA)

$(SPHEREFONTS): spherefonts
	$(MAKE) -C spherefonts
	$(INSTALL) spherefonts/$(LIBPA)spherefonts.$(LIBSA) lib/$(LIBPA)spherefonts.$(LIBSA)

$(BUFFERFILE): bufferfile
	scons -j2 -C bufferfile
	$(INSTALL) bufferfile/$(LIBPA)bufferfile.$(LIBSA) lib/$(LIBPA)bufferfile.$(LIBSA)

$(AIMG): aimage bufferfile
	$(MAKE) -C aimage
	$(INSTALL) aimage/$(LIBPA)aimg.$(LIBSA) lib/$(LIBPA)aimg.$(LIBSA)

$(FJOGG): fjogg/fjogg.m
	cd fjogg && $(MMCIN) --make libfjogg

#libopenglextra: openglextra
#	$(MAKE) -C openglextra
#	$(INSTALL) openglextra/$(LIBPA)openglextra.$(LIBSA) lib/$(LIBPA)openglextra.$(LIBSA)

LIBS=-l glow -l openal -l opus -l chrono -l spherefonts -l aimg -l bufferfile -l GL -l png

MERCURY_SRC=camera.m gl2.m gl2.skybox.m gl2.heightmap.m matrix.m model.m opengl.m render.m \
scene.m scene.matrix_tree.m scene.node_tree.m softshape.m vector.m wavefront.m mopus.m \
mopenal.m audio_loader.m aimg.m heightmap.m

cinnabar: $(LIBTARGETS) $(WRAPPERS_SRC) $(MERCURY_SRC) cinnabar.m
	$(MMCIN) cinnabar -L lib $(LIBS) $(FJOGGFLAGS)
	touch -c cinnabar

test: test.m test.wavefront.m wavefront.m test.buffer.m buffer.m
	$(MMCIN) test -L lib $(LIBS)
	touch -c test

sinetest: sinetest.m sinegen.m mopenal.m $(CHRONO)
	$(MMCIN) sinetest -L lib -l openal -l chrono
	touch -c sinetest

perlintest: perlintest.m perlin.m xorshift.m $(AIMG) $(BUFFERFILE)
	$(MMCIN) perlintest -L lib -l aimg -l png -l bufferfile

EDITLIBS=libwavefront.so 

libwavefront.so:
	$(MMCIN) libwavefront

ilib.m editor/ilib.m: bottles/ilib.json
	python bottlegen/generate.py -lm bottles/ilib.json
	cp ilib.m editor/ilib.m

cell.m editor/cell.m: bottles/cell.json
	python bottlegen/generate.py -lm bottles/cell.json
	cp cell.m editor/cell.m

editor/aimg.m: aimg.m
	cp aimg.m editor/aimg.m

editor/buffer.m: buffer.m
	cp buffer.m editor/buffer.m

editor/bufferfile.m: bufferfile.m
	cp bufferfile.m editor/bufferfile.m

cinedit: editor $(LIBTARGETS) $(EDITLIBS) editor/cell.m editor/ilib.m editor/aimg.m editor/buffer.m editor/bufferfile.m
	cp -r lib editor
	mkdir editor/aimage || true
	cp aimage/image.h editor/aimage/image.h
	cp aimage/export.h editor/aimage/export.h
	cp libwavefront.so editor/lib
	cp *.mh editor/include
	$(MAKE) -C editor MMCIN="$(MMCIN)" GRADE=$(GRADE) MMC="$(MMC)"

cinedit_clean:
	$(MAKE) -C editor MMCIN="$(MMCIN)" GRADE=$(GRADE) MMC="$(MMC)" clean

clean: cinedit_clean
	scons -C glow -c
	scons -C chrono -c
	scons -C bufferfile -c
	$(MAKE) -C spherefonts clean
	$(MAKE) -C aimage clean
	$(MMCIN) cinnabar.clean
	$(MMCIN) test.clean
	$(MMCIN) perlintest.clean
	rm -f lib/*.$(LIBSX) lib/*.$(LIBSA) *.mh *.err cinnabar test

libclean: clean
	rm -rf lib/mercury || true
	rm *.init || true
	rm  -rf Mercury || true
	cd fjogg && $(MMCIN) libfjogg.clean
	cd fjogg && $(MMCIN) fjogg.clean
	cd fjogg && rm -rf Mercury || true

.PHONY: all cinedit_clean clean $(LIBTARGETS)
.IGNORE: clean cinedit_clean libclean
.SILENT: clean cinedit_clean libclean
