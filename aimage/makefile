
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

.endif
