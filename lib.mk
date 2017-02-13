
LIBPX?=lib
LIBSX?=so
LIBSA?=a
LIBPA?=$(LIBPX)

GLOW=$(LIBDIR)/$(LIBPX)glow.$(LIBSX)
CHRONO=$(LIBDIR)/$(LIBPA)chrono.$(LIBSA)
SPHEREFONTS=$(LIBDIR)/$(LIBPA)spherefonts.$(LIBSA)
AIMG=$(LIBDIR)/$(LIBPA)aimg.$(LIBSA)
BUFFERFILE=$(LIBDIR)/$(LIBPA)bufferfile.$(LIBSA)

INSTALL?=install

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

glowclean:
	scons -C glow -c

chronoclean:
	scons -C chrono -c

bufferfileclean:
	scons -C bufferfile -c

spherefontsclean:
	$(MAKE) -C spherefonts clean

aimgclean:
	$(MAKE) -C aimage clean

CINLIBS=$(GLOW) $(CHRONO) $(BUFFERFILE) $(SPHEREFONTS) $(AIMG)
CINLIBSCLEAN=glowclean chronoclean bufferfileclean spherefontsclean aimgclean

.export CINLIBS
.export CINLIBSCLEAN
