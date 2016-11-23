libspherefonts.a:
	$(CC) -Os -c font.c -o spherefonts.o
	ar -rs libspherefonts.a spherefonts.o

clean:
	rm spherefonts.o
	rm libspherefonts.a

.IGNORE: clean
.PHONY: clean
.SILENT: clean
