PARALLEL?=2

all: cinnabar

LIBDIR=${PWD}/lib
.export LIBDIR

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
