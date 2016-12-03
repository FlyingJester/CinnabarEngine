all: cinnabar test

# MMCIN=mmc -E -j4 --grade=asm_fast.gc.debug.stseg --make
MMCCALL=mmc --grade=hlc.gc --cflag "-g" --opt-level --intermodule-optimization
MMCIN=$(MMCCALL) -E -j4 --make


LIBTARGETS=libglow libchrono libspherefonts libbufferfile libaimg libopenglextra

libglow: glow
	scons -j2 -C glow
	install glow/libglow.so lib/libglow.so

libchrono: chrono
	scons -j2 -C chrono
	install chrono/libchrono.a lib/libchrono.a

libspherefonts: spherefonts
	$(MAKE) -C spherefonts
	install spherefonts/libspherefonts.a lib/libspherefonts.a

libbufferfile: bufferfile
	scons -j2 -C bufferfile
	install bufferfile/libbufferfile.a lib/libbufferfile.a

libaimg: aimage bufferfile
	$(MAKE) -C aimage
	install aimage/libaimg.a lib/libaimg.a

libopenglextra: openglextra
	$(MAKE) -C openglextra
	install openglextra/libopenglextra.a lib/libopenglextra.a

LIBS=-l glow -l openal -l opus -l ogg -l chrono -l spherefonts -l aimg -l bufferfile -l GL -l png -l openglextra
	
cinnabar: $(LIBTARGETS)
	$(MMCIN) cinnabar -L lib $(LIBS)

test: $(LIBTARGETS)
	$(MMCIN) test -L lib $(LIBS)

clean:
	scons -C glow -c
	scons -C chrono -c
	$(MAKE) -C spherefonts clean
	$(MMCIN) cinnabar.clean
	$(MMCIN) test.clean
	rm -f lib/*.so lib/*.a *.mh *.err cinnabar test

PHONY: all clean $(LIBTARGETS)
IGNORE: clean
SILENT: clean
