all: cinnabar test sinetest

tests: test sinetest

LIBPX?=lib
LIBSX?=so
LIBSA?=a
LIBPA?=$(LIBPX)
INSTALL?=install
GRADE?=hlc.gc # asm_fast.gc.debug.stseg

MMC?=mmc

MMCFLAGS?=--cflags "-g " --ld-flags " -g "
#  --mercury-linkage static --opt-level 7 --intermodule-optimization 
MMCCALL=$(MMC) $(MMCFLAGS) -L./ --mld lib/mercury --grade=$(GRADE)
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

EDITLIBS=libwavefront.so 

libwavefront.so:
	$(MMCIN) libwavefront

cinedit: editor $(LIBTARGETS) $(EDITLIBS)
	cp -r lib editor
	cp libwavefront.so editor/lib
	cp *.mh editor/include
	$(MAKE) -C editor

cinedit_clean:
	$(MAKE) -C editor clean

clean: cinedit_clean
	scons -C glow -c
	scons -C chrono -c
	scons -C bufferfile -c
	$(MAKE) -C spherefonts clean
	$(MAKE) -C aimage clean
	$(MMCIN) cinnabar.clean
	$(MMCIN) test.clean
	rm -f lib/*.$(LIBSX) lib/*.$(LIBSA) *.mh *.err cinnabar test

libclean: clean
	rm -rf lib/mercury || true
	rm *.init || true
	rm  -rf Mercury || true
	cd fjogg && $(MMCIN) libfjogg.clean
	cd fjogg && $(MMCIN) fjogg.clean
	cd fjogg && rm -rf Mercury || true

PHONY: all cinedit_clean clean $(LIBTARGETS)
IGNORE: clean cinedit_clean libclean
SILENT: clean cinedit_clean libclean
