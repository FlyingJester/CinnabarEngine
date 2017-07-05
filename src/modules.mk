# Makefile to wrangle dependencies between engine components

all: Mercury.modules cinnabar cinlaunch

.include "common.mk"

.include "render/render.mk"
.include "scene/scene.mk"
.include "model/model.mk"
.include "audio/audio.mk"
.include "util/util.mk"
.include "math/math.mk"
.include "perlin/perlin.mk"
.include "opengl/opengl.mk"
.include "engine/engine.mk"
.include "window/window.mk"

.include "run_genmk.mk"

clean:
	rm Mercury.modules
	rm $(INCLUDES)
	mmc --make cinnabar.clean

cinnabar: Mercury.modules
	$(MMCIN) cinnabar -lglow -lGL -lchrono -laimg -lpng -lbufferfile

cinlaunch:
	$(MAKE) -C launcher
	cp launcher/cinlauncher ..

.IGNORE: clean
.PHONY: clean cinlaunch
.SILENT: clean
