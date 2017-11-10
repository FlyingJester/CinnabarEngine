OBJS=image.o load_tga.o load_png.o save_tga.o save_png.o

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
