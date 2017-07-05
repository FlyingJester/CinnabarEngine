PARALLEL?=2

all: cinnabar

LIBDIR=${PWD}/lib
ROOTDIR=${PWD}
PYTHON?=python

all: cinnabar

src/engine/ilib.m: bottles/ilib.json
	$(PYTHON) bottlegen/generate.py -lm bottles/ilib.json
	mv ilib.m src/engine/ilib.m

src/engine/cell.m: bottles/cell.json
	$(PYTHON) bottlegen/generate.py -lm bottles/cell.json
	mv cell.m src/engine/cell.m

.include "lib.mk"

cinnabar: $(CINLIBS) src/engine/ilib.m src/engine/cell.m
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean

libclean: clean $(CINLIBSCLEAN)
	rm $(CINLIBS)

.PHONY: libclean clean $(CINLIBSCLEAN) cinnabar
.SILENT: libclean clean
.IGNORE: libclean clean $(CINLIBSCLEAN)
