all: cinedit

CC?=gcc
CXX?=g++
LINK=g++

CCFLAGS=-g -Wall -Werror -I${PWD}/../
CFLAGS=$(CCFALGS) -Os -ansi
CXXFLAGS=$(CCFLAGS) -O2 -fno-exceptions -fno-rtti -std=c++98
AUTOCFLAGS=$(CFLAGS) -Wno-switch -Wno-unused-function
FLTKFLAGS!=fltk-config --ldstaticflags --use-images
LINKFLAGS=-g -Llib 

OBJECTS=editor.o editor_ui.o editor_ilib.o ilib.o
GENSRC=editor_ui.cpp editor_ui.hpp

$(GENSRC): editor_ui.fl
	fluid -c editor_ui.fl

editor_ui.o: editor_ui.cpp editor_ui.hpp ilib_glue.h
	$(CXX) $(CXXFLAGS) -c editor_ui.cpp -o editor_ui.o

editor.o: editor.cpp editor.hpp glow_fltk_glue.hpp editor_ui.hpp
	$(CXX) $(CXXFLAGS) -c editor.cpp -o editor.o

editor_ilib.o: editor_ilib.cpp editor_ilib.hpp ilib.h
	$(CXX) $(CXXFLAGS) -c editor_ilib.cpp -o editor_ilib.o

ilib.o: ilib.c ilib.h
	$(CC) $(AUTOCFLAGS) -c ilib.c -o ilib.o

cinedit: $(OBJECTS)
	$(LINK) $(LINKFLAGS) $(OBJECTS) $(FLTKFLAGS) -lglow -lwavefront -o cinedit

.PHONY: clean
.SILENT: clean
.IGNORE: clean

clean:
	rm $(OBJECTS)
	rm $(GENSRC)
	rm cinedit
