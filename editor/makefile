all: cinedit

CC?=gcc
CXX?=g++
LINK=g++

MMC?=mmc
GRADE?=hlc.gc
MMCCALL?=$(MMC) $(MMCFLAGS) -L./ --mld lib/mercury --grade=$(GRADE)
MMCIN?=$(MMC) $(MMCCALL) --make 

MERINCFLAGS!=$(MMC) --grade=$(GRADE) --output-c-include-dir-flags

CCFLAGS=-g -Wall -Werror -I${PWD}/../
CFLAGS=$(CCFALGS) -Os -ansi
CXXFLAGS=$(CCFLAGS) $(MERINCFLAGS) -O2 -fno-exceptions -fno-rtti -std=c++98 -fPIC
AUTOCFLAGS=$(CFLAGS) -Wno-switch -Wno-unused-function
FLTKFLAGS!=fltk-config --ldstaticflags --use-images
LINKFLAGS=-g -fPIC -Llib

OBJECTS=editor_ui.o ilib_ui.o clib_ui.o cell_ui.o glue.o
GENSRC=editor_ui.cpp editor_ui.hpp

$(GENSRC): editor_ui.fl
	fluid -c editor_ui.fl

editor_ui.o: editor_ui.cpp editor_ui.hpp ilib_ui.h clib_ui.h cell_ui.h
	$(CXX) $(CXXFLAGS) -c editor_ui.cpp -o editor_ui.o

ilib_ui.o: ilib_ui.cpp ilib_ui.h cinedit.ilib.mh ilib.mh editor_ui.hpp
	$(CXX) $(CXXFLAGS) -c ilib_ui.cpp -o ilib_ui.o

clib_ui.o: clib_ui.cpp clib_ui.h editor_ui.hpp
	$(CXX) $(CXXFLAGS) -c clib_ui.cpp -o clib_ui.o

cell_ui.o: cell_ui.cpp cell_ui.h editor_ui.hpp
	$(CXX) $(CXXFLAGS) -c cell_ui.cpp -o cell_ui.o

glue.o: cinedit_fltk_glue.cpp cinedit_fltk_glue.h
	$(CXX) $(CXXFLAGS) -c cinedit_fltk_glue.cpp -o glue.o

lib/libcineditui.a: $(OBJECTS)
	ar -rs lib/libcineditui.a $(OBJECTS)
	ranlib lib/libcineditui.a
	rm cinedit || true
	# Delete cinedit to cause MMC to rebuild it.

cinedit.ilib.mh: cinedit.ilib.m
	$(MMCIN) cinedit.ilib.mh
	touch cinedit.ilib.mh

ilib.mh: ilib.m
	$(MMCIN) ilib.mh
	touch ilib.mh

EXTRAMMCFLAGS=--cflag -Wno-strict-prototypes --ld-flags="-L${PWD}/lib -lcineditui $(FLTKFLAGS)" --link-executable-command g++

cinedit: lib/libcineditui.a cinedit.m cinedit.ilib.m cinedit.clib.m cinedit.cell.m
	$(MMCIN) cinedit $(EXTRAMMCFLAGS) -l aimg -l bufferfile

.PHONY: clean
.SILENT: clean
.IGNORE: clean

clean:
	$(MMCIN) cinedit.clean
	rm lib/libcineditui.a
	rm $(OBJECTS)
	rm $(GENSRC)
	rm cinedit
