
INCLUDES=render/render.mk scene/scene.mk model/model.mk audio/audio.mk\
    util/util.mk math/math.mk perlin/perlin.mk opengl/opengl.mk

CHILDMODULES=$(RENDER_SRC) $(SCENE_SRC) $(MODEL_SRC) $(AUDIO_SRC) $(UTIL_SRC) $(MATH_SRC) $(PERLIN_SRC) $(OPENGL_SRC) $(ENGINE_SRC) $(WINDOW_SRC)

Mercury.modules: $(INCLUDES)
	$(MMCCALL) -f $(CHILDMODULES)
