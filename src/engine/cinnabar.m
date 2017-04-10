:- module cinnabar.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.

:- pred main(io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module thread.
:- use_module thread.mvar.
:- use_module maybe.
:- use_module exception.
:- import_module list.
:- import_module int.

:- use_module scene.
:- use_module scene.matrix_tree.
:- use_module render.
:- use_module window.
:- use_module glow_window.
:- use_module config.
:- use_module mchrono.

:- use_module gl2_render.
:- use_module gl2_render.heightmap.
:- use_module gl2_render.skybox.
:- use_module opengl.texture.

% Basic Cinnabar startup:
%  * Load config
%  * Start Window backend
%  * Start OpenGL system and create contexts
%  * Begin frames:
%   - Load any new cells
%   - Handle Events
%   - Process Frame

:- type scene_frame(Model, Texture, Heightmap) --->
    quit ;
    scene(scene.scene(Model, Texture, Heightmap), scene.matrix_tree.matrix_tree).

:- pred engine(Render,
    thread.mvar.mvar(int),
    thread.mvar.mvar(scene_frame(Model, Texture, Heightmap)),
    list.list(string), list.list(window.window_event),
    io.io, io.io) <= (render.render(Render),
            render.skybox(Render, Texture),
            render.model(Render, Model),
            render.heightmap(Render, Heightmap, Texture)).

:- mode engine(in,
    in,
    in,
    in, in,
    di, uo) is det.

:- pred render(Render,
    thread.mvar.mvar(scene_frame(Model, Texture, Heightmap)),
    io.io, io.io) <= (render.render(Render),
        render.skybox(Render, Texture),
        render.model(Render, Model),
        render.heightmap(Render, Heightmap, Texture)).

:- mode render(in, in, di, uo) is det.

:- func gl2_scene =
    (scene_frame(gl2_render.model, opengl.texture.texture, gl2_render.heightmap.heightmap)).
gl2_scene = scene(scene.scene(scene.end, maybe.no, [], []), scene.matrix_tree.init).

main(!IO) :-
    config.load(Config, !IO),
    Config ^ config.gl_version = window.gl_version(Maj, Min),
    ( Maj = 2 ->
        thread.mvar.init(TimeMVar, !IO),
        thread.mvar.init(SceneMVar, !IO),
        thread.mvar.put(SceneMVar, gl2_scene, !IO),
        thread.mvar.put(TimeMVar, 0, !IO),
        Renderer = render(gl2_render.gl2_render, SceneMVar),
        Engine = engine(gl2_render.gl2_render, TimeMVar, SceneMVar)
    ;
        exception.throw(exception.software_error(
            "Graphics other than OpenGL 2 are not supported yet!"
        ))
    ), % TODO: This will need to be made into a separate pred when different backends are supported!
    ( Config ^ config.back = config.glow ->
        W = Config ^ config.w, H = Config ^ config.h,
        Title = "Cinnabar Game Engine",
        glow_window.create_window(W, H, Title, Maj, Min, Window, !IO)
    ;
        exception.throw(exception.software_error(
            "Backends other than Glow are not supported yet!"
        ))
    ),
    window.show(Window, !IO),
    window.run(Renderer, Engine, Window, !IO).

engine(_, TimeMVar, SceneMVar, Keys, Events, !IO) :-
    thread.mvar.take(TimeMVar,OldTime, !IO),
    mchrono.micro_ticks(!IO, mchrono.microseconds(Time)),
    Duration = Time - OldTime,
    thread.mvar.put(TimeMVar, Duration, !IO).

render(Render, SceneMVar, !IO) :-
    thread.mvar.take(SceneMVar, SceneFrame, !IO),
    (
        SceneFrame = quit
    ;
        SceneFrame = scene(Scene, Matrices),
        scene.draw(Render, Scene, Matrices, 0.0, 0.0, !IO)
    ).
