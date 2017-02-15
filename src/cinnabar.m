:- module cinnabar.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.

%------------------------------------------------------------------------------%

:- pred main(io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module float.
:- import_module int.

:- use_module scene.
:- use_module scene.matrix_tree.
:- use_module scene.node_tree.
:- use_module camera.

:- use_module render.

:- use_module opengl.
:- use_module opengl.texture.
:- use_module opengl2.
:- use_module gl2_render.
:- use_module gl2_render.heightmap.

:- use_module heightmap_aimg.
:- use_module wavefront.

:- use_module mglow.

%------------------------------------------------------------------------------%
:- pred frame(scene.scene(Model, Heightmap, Texture)::in, Renderer::in,
    mglow.window::di, mglow.window::uo, io.io::di, io.io::uo) is det
    <= (render.render(Renderer, mglow.window),
        render.model(Renderer, Model, mglow.window),
        render.skybox(Renderer, Texture,  mglow.window),
        render.heightmap(Renderer, Heightmap, Texture, mglow.window)).

:- pred load(
    scene.scene(gl2_render.gl2_render, gl2_render.heightmap.heightmap, opengl.texture.texture)::out,
    io.io::di, io.io::uo) is det.

%------------------------------------------------------------------------------%
:- pred setup_gl2(gl2_render.gl2_render::in, mglow.window::di, mglow.window::uo) is det.
setup_gl2(_, !Window) :-
    opengl2.matrix_mode(opengl2.modelview, !Window),
    opengl2.load_identity(!Window),
    opengl2.matrix_mode(opengl2.projection, !Window),
    AspectRatio = float(w) / float(h),
    opengl2.frustum(1.0, 100.0, -0.5 * AspectRatio, 0.5 * AspectRatio, -0.5, 0.5, !Window),
    opengl.viewport(0, 0, w, h, !Window).

main(!IO).
    
