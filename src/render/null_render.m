:- module null_render.
%==============================================================================%
% Null renderer, swallows all input. Mainly used for testing purposes, mostly
% finding if a crash is OpenGL or Mercury.
:- interface.
%==============================================================================%

:- use_module render.

:- type null_render ---> null_render.
:- type null_model.
:- type null_texture.
:- type null_heightmap.

:- instance render.render(null_render).
:- instance render.model_compiler(null_render, null_model).
:- instance render.model(null_render, null_model).
:- instance render.skybox(null_render, null_texture).
:- instance render.heightmap(null_render, null_heightmap, null_texture).

%==============================================================================%
:- implementation.
%==============================================================================%

:- type null_model ---> null_model.
:- type null_texture ---> null_texture.
:- type null_heightmap ---> null_heightmap.

:- instance render.render(null_render) where [
    frustum(null_render, _, _, _, _, _, _, !IO),
    
    enable_depth(null_render, !IO),
    disable_depth(null_render, !IO),
    
    push_matrix(null_render, !IO),
    pop_matrix(null_render, !IO),
    
    translate(null_render, _, _, _, !IO),
    
    rotate_x(null_render, _, !IO),
    rotate_y(null_render, _, !IO),
    rotate_z(null_render, _, !IO),
    
    scale(null_render, _, _, _, !IO),

    max_lights(null_render) = 0,

    light(null_render, _, _, !IO)
].

%------------------------------------------------------------------------------%

:- instance render.model_compiler(null_render, null_model) where [
    compile_wavefront(_, null_render, null_model),
    compile_softshape(_, null_render, null_model)
].

%------------------------------------------------------------------------------%

:- instance render.model(null_render, null_model) where [
    draw(null_render, null_model, !IO)
].

%------------------------------------------------------------------------------%

:- instance render.skybox(null_render, null_texture) where [
    draw_skybox(null_render, _, _, null_texture, !IO)
].

%------------------------------------------------------------------------------%

:- instance render.heightmap(null_render, null_heightmap, null_texture) where [
    draw_heightmap(null_render, null_heightmap, null_texture, !IO)
].
