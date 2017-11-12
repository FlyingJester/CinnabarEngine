
CLFLAGS=/DAIMG_EXPORTS /nologo

.if defined(OS) && (${OS} == "WIN")

OBJECTS=image.obj save_jpeg.obj save_png.obj load_png.obj save_tga.obj load_tga.obj

image.obj: image.c image.h
	cl $(CLFLAGS) /Foimage.obj /c image.c

save_jpeg.obj: save_jpeg.c image.h
	cl $(CLFLAGS) /Foimage.obj /c image.c

save_png.obj: save_png.c image.h
	cl $(CLFLAGS) /Fosave_png.obj /c save_png.c

load_png.obj: load_png.c image.h
	cl $(CLFLAGS) /Foload_png.obj /c load_png.c

save_tga.obj: save_tga.c image.h
	cl $(CLFLAGS) /Fosave_tga.obj /c save_tga.c

load_tga.obj: load_tga.c image.h
	cl $(CLFLAGS) /Foload_tga.obj /c load_tga.c



.else

OBJECTS=image.o load_tga.o load_png.o save_tga.o save_png.o

libaimg.a: $(OBJS)
	ar -rs libaimg.a $(OBJS)

all: libaimg

image.o: image.c image.h
	$(CC) -Os -c image.c -o image.o

load_tga.o: load_tga.c image.h
	$(CC) -Os -c load_tga.c -o load_tga.o

load_png.o: load_png.c image.h
	$(CC) -I/usr/local/include -Os -c load_png.c -o load_png.o

save_tga.o: save_tga.c image.h
	$(CC) -Os -c save_tga.c -o save_tga.o

save_png.o: save_png.c image.h
	$(CC) -I/usr/local/include -Os -c save_png.c -o save_png.o

clean:
	rm -f $(OBJS).o
	rm -f libaimg.a

.IGNORE: clean
.PHONY: clean
.SILENT: clean

.endif
