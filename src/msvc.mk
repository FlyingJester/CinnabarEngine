
!include "render/render.mk"
!include "scene/scene.mk"
!include "model/model.mk"
!include "audio/audio.mk"
!include "util/util.mk"
!include "math/math.mk"
!include "perlin/perlin.mk"
!include "opengl/opengl.mk"
!include "engine/engine.mk"
!include "window/window.mk"

all: cinnabar

!include "run_genmk.mk"

cinnabar: Mercury.modules $(CHILDMODULES)
	$(MMCIN) cinnabar

.PHONY: cinnabar
