PARALLEL?=2

all: cinnabar

LIBDIR=${PWD}/lib
ROOTDIR=${PWD}

.export LIBDIR
.export ROOTDIR

.include "lib.mk"

cinnabar: $(CINLIBS)
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean

libclean: clean $(CINLIBSCLEAN)
	rm $(CINLIBS)

.PHONY: libclean clean $(CINLIBSCLEAN) cinnabar
.SILENT: libclean clean
.IGNORE: libclean clean $(CINLIBSCLEAN)
