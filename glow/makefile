all: libglow.so
GLOW_BACKEND?=x11

all: libglow.so

glow.o: glow.h glow_$(GLOW_BACKEND).c
	cc -Wall -O2 -g -c glow_$(GLOW_BACKEND).c -fPIC -o glow.o
libglow.so: glow.o
	cc -lX11 -lXext -lGL glow.o -shared -fPIC -o libglow.so

clean:
	rm glow.o libglow.so

PHONY: all clean
IGNORE: clean
SILENT: clean
