

.if defined(OS) && (${OS} == "WIN")

all: glow.dll glow.lib

glow_win32.obj: glow_win32.c glow.h
	cl /Foglow_win32.obj /c glow_win32.c /DGLOW_EXPORTS /nologo

glow.dll glow.lib:
	link /nologo /dll /out:glow.dll /implib:glow.lib OpenGL32.lib gdi32.lib user32.lib glow_win32.obj

.else

all: libglow.so

glow_x11.o: glow_x11.c glow.h
	cc -Wall -Werror -ansi -c glow_x11.c -o glow_x11.o

libglow.so:
	cc -shared glow_x11.o -o libglow.so

.endif
