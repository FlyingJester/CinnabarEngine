all: cinnabar test

LIBPX?=lib
LIBSX?=so
LIBSA?=a
LIBPA?=$(LIBPX)
INSTALL?=install

MMC?=mmc

# MMCIN=$(MMC) -E -j4 --grade=asm_fast.gc.debug.stseg --make
MMCCALL=$(MMC) --grade=hlc.gc --cflags "-g -O2 " --opt-level 7 --intermodule-optimization
MMCIN=$(MMCCALL) -E -j4 --make


LIBTARGETS=libglow libchrono libspherefonts libbufferfile libaimg # libopenglextra

libglow: glow
	scons -j2 -C glow
	$(INSTALL) glow/$(LIBPX)glow.$(LIBSX) lib/$(LIBPX)glow.$(LIBSX)

libchrono: chrono
	scons -j2 -C chrono
	$(INSTALL) chrono/$(LIBPA)chrono.$(LIBSA) lib/$(LIBPA)chrono.$(LIBSA)

libspherefonts: spherefonts
	$(MAKE) -C spherefonts
	$(INSTALL) spherefonts/$(LIBPA)spherefonts.$(LIBSA) lib/$(LIBPA)spherefonts.$(LIBSA)

libbufferfile: bufferfile
	scons -j2 -C bufferfile
	$(INSTALL) bufferfile/$(LIBPA)bufferfile.$(LIBSA) lib/$(LIBPA)bufferfile.$(LIBSA)

libaimg: aimage bufferfile
	$(MAKE) -C aimage
	$(INSTALL) aimage/$(LIBPA)aimg.$(LIBSA) lib/$(LIBPA)aimg.$(LIBSA)

#libopenglextra: openglextra
#	$(MAKE) -C openglextra
#	$(INSTALL) openglextra/$(LIBPA)openglextra.$(LIBSA) lib/$(LIBPA)openglextra.$(LIBSA)

LIBS=-l glow -l openal -l opus -l ogg -l chrono -l spherefonts -l aimg -l bufferfile -l GL -l png # -l openglextra
	
cinnabar: $(LIBTARGETS)
	$(MMCIN) cinnabar -L lib $(LIBS)

test: $(LIBTARGETS)
	$(MMCIN) test -L lib $(LIBS)

clean:
	scons -C glow -c
	scons -C chrono -c
	scons -C bufferfile -c
	$(MAKE) -C spherefonts clean
	$(MAKE) -C aimage clean
	$(MMCIN) cinnabar.clean
	$(MMCIN) test.clean
	rm -f lib/*.$(LIBSX) lib/*.$(LIBSA) *.mh *.err cinnabar test

PHONY: all clean $(LIBTARGETS)
IGNORE: clean
SILENT: clean
