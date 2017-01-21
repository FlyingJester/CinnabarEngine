all: cinnabar test

tests: test sinetest

LIBPX?=lib
LIBSX?=so
LIBSA?=a
LIBPA?=$(LIBPX)
INSTALL?=install
GRADE?=hlc.gc

MMC?=mmc

# MMCIN=$(MMC) -E -j4 --grade=asm_fast.gc.debug.stseg --make
MMCFLAGS?=--cflags "-g -O2 " --opt-level 7 --intermodule-optimization 
MMCCALL=$(MMC) --grade=$(GRADE) $(MMCFLAGS) -L./ --mld lib/mercury
MMCIN=$(MMCCALL) -E -j4 --make

GLOW=lib/$(LIBPX)glow.$(LIBSX)
CHRONO=lib/$(LIBPA)chrono.$(LIBSA)
SPHEREFONTS=lib/$(LIBPA)spherefonts.$(LIBSA)
AIMG=lib/$(LIBPA)aimg.$(LIBSA)
BUFFERFILE=lib/$(LIBPA)bufferfile.$(LIBSA)
FJOGG=lib/mercury/lib/$(GRADE)/$(LIBPX)fjogg.$(LIBSX)

echo_fjogg:
	echo $(FJOGG)

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
	cd fjogg && $(MMCIN) --make libfjogg.install --install-prefix=../

#libopenglextra: openglextra
#	$(MAKE) -C openglextra
#	$(INSTALL) openglextra/$(LIBPA)openglextra.$(LIBSA) lib/$(LIBPA)openglextra.$(LIBSA)

LIBS=-l glow -l openal -l opus -l chrono -l spherefonts -l aimg -l bufferfile -l GL -l png

MERCURY_SRC=camera.m gl2.m gl2.skybox.m matrix.m model.m opengl.m render.m \
scene.m scene.matrix_tree.m scene.node_tree.m softshape.m vector.m \
wavefront.m mopus.m mopenal.m audio_loader.m

cinnabar: $(LIBTARGETS) $(WRAPPERS_SRC) $(MERCURY_SRC) cinnabar.m
	$(MMCIN) cinnabar -L lib $(LIBS) --ml fjogg
	touch -c cinnabar

test: test.m test.wavefront.m wavefront.m test.buffer.m buffer.m
	$(MMCIN) test -L lib $(LIBS)
	touch -c test

sinetest: sinetest.m sinegen.m mopenal.m $(CHRONO)
	$(MMCIN) sinetest -L lib -l openal -l chrono
	touch -c sinetest

clean:
	scons -C glow -c
	scons -C chrono -c
	scons -C bufferfile -c
	$(MAKE) -C spherefonts clean
	$(MAKE) -C aimage clean
	$(MMCIN) cinnabar.clean
	$(MMCIN) test.clean
	rm -f lib/*.$(LIBSX) lib/*.$(LIBSA) *.mh *.err cinnabar test

libclean: clean
	rm -rf lib/mercury
	rm *.init
	rm *.err
	rm Mercury
	cd fjogg && rm Mercury
	cd fjogg && $(MMCIN) libfjogg.clean

PHONY: all clean $(LIBTARGETS)
IGNORE: clean
SILENT: clean
