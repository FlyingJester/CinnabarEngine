CC?=gcc
CXX?=g++
LINK?=g++

CCFLAGS?=-Wall -Wextra -Werror -pedantic -Os -g
CFLAGS?=$(CCFLAGS) -ansi
CXXFLAGS?=$(CCFLAGS) -fno-rtti -fno-exceptions -std=c++98
LINKFLAGS?=-g
FLTKFLAGS!=fltk-config --ldflags --use-images

all: cinlauncher

cinlauncher: launcher.cpp launcher.hpp
	$(CXX) $(CXXFLAGS) -c launcher.cpp -o launcher.o
	$(LINK) $(LINKFLAGS) launcher.o $(FLTKFLAGS) -o cinlauncher

launcher.cpp launcher.hpp: launcher.fl
	fluid -c launcher.fl


