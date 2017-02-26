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

INCLUDES=render/render.mk scene/scene.mk model/model.mk audio/audio.mk\
    util/util.mk math/math.mk perlin/perlin.mk opengl/opengl.mk

CHILDMODULES=$(RENDER_SRC) $(SCENE_SRC) $(MODEL_SRC) $(AUDIO_SRC) $(UTIL_SRC) $(MATH_SRC) $(PERLIN_SRC) $(OPENGL_SRC) $(ENGINE_SRC) $(WINDOW_SRC)

Mercury.modules: $(INCLUDES)
	$(MMCCALL) -f $(CHILDMODULES)

clean:
	rm Mercury.modules
	rm $(INCLUDES)

cinnabar: Mercury.modules
	$(MMCIN) cinnabar

cinlaunch:
	$(MAKE) -C launcher
	cp launcher/cinlauncher ..

.IGNORE: clean
.PHONY: clean cinlaunch
.SILENT: clean
