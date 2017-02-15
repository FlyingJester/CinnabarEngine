# Makefile to wrangle dependencies between engine components

all: Mercury.modules cinnabar

.include "common.mk"

.include "render/render.mk"
.include "scene/scene.mk"
.include "model/model.mk"
.include "audio/audio.mk"
.include "util/util.mk"
.include "math/math.mk"
.include "perlin/perlin.mk"
.include "opengl/opengl.mk"

INCLUDES=render/render.mk scene/scene.mk model/model.mk audio/audio.mk\
    util/util.mk math/math.mk perlin/perlin.mk opengl/opengl.mk

CHILDMODULES=$(RENDER_SRC) $(SCENE_SRC) $(MODEL_SRC) $(AUDIO_SRC) $(UTIL_SRC) $(MATH_SRC) $(PERLIN_SRC) $(OPENGL_SRC)

Mercury.modules: $(INCLUDES)
	$(MMCCALL) -f $(CHILDMODULES)

clean:
	rm Mercury.modules

cinnabar: Mercury.modules
	$(MMCIN) cinnabar

.IGNORE: clean
.PHONY: clean
.SILENT: clean
