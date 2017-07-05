
.if defined(OS) && (${OS} == "WIN")

spherefonts.lib:
	cl /Fospherefonts.obj /c font.c /nologo
	lib /nologo /OUT:spherefonts.lib spherefonts.obj

.else

libspherefonts.a:
	$(CC) -Os -c font.c -o spherefonts.o
	ar -rs libspherefonts.a spherefonts.o

.endif

clean:
	rm spherefonts.o
	rm libspherefonts.a

.IGNORE: clean
.PHONY: clean
.SILENT: clean
