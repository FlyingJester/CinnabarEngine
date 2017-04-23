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
:- import_module exception.
:- import_module list.
:- import_module int.

:- use_module scene.
:- use_module scene.matrix_tree.
:- use_module render.
:- use_module window.
:- use_module glow_window.
:- use_module null_window.
:- use_module config.
:- use_module mchrono.

:- use_module gl2_render.
:- use_module gl2_render.heightmap.
:- use_module gl2_render.skybox.
:- use_module null_render.
:- use_module opengl.texture.

%------------------------------------------------------------------------------%

% Basic Cinnabar startup:
%  * Load config
%  * Start Window backend
%  * Start OpenGL system and create contexts
%  * Begin frames:
%   - Load any new cells
%   - Handle Events
%   - Process Frame

%------------------------------------------------------------------------------%

:- type scene_frame(Model, Texture, Heightmap) --->
    quit ;
    scene(scene.scene(Model, Texture, Heightmap), scene.matrix_tree.matrix_tree).

%------------------------------------------------------------------------------%

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

%------------------------------------------------------------------------------%

:- pred render(Render,
    thread.mvar.mvar(scene_frame(Model, Texture, Heightmap)),
    io.io, io.io) <= (render.render(Render),
        render.skybox(Render, Texture),
        render.model(Render, Model),
        render.heightmap(Render, Heightmap, Texture)).

:- mode render(in, in, di, uo) is det.

%------------------------------------------------------------------------------%

:- func gl2_scene =
    (scene_frame(gl2_render.model, opengl.texture.texture, gl2_render.heightmap.heightmap)).
gl2_scene = scene(scene.scene(scene.end, maybe.no, [], []), scene.matrix_tree.init).

%------------------------------------------------------------------------------%

:- func null_scene =
    (scene_frame(null_render.null_model, null_render.null_texture, null_render.null_heightmap)).
null_scene = scene(scene.scene(scene.end, maybe.no, [], []), scene.matrix_tree.init).

%------------------------------------------------------------------------------%

% These are defined as explicit preds just so that the preds can specialize on
% different windowing backends and renderers. Basically, main calls main_1 and
% that calls main_2.

% main_1 creates a window and a context.
:- pred main_1(config.config::di, io.io::di, io.io::uo) is det.
main_1(Config, !IO) :-
    Config ^ config.gl_version = window.gl_version(Maj, Min),
    W = Config ^ config.w, H = Config ^ config.h,
    ( Config ^ config.back = config.glow ->
        Title = "Cinnabar Game Engine",
        glow_window.create_window(W, H, Title, Maj, Min, GlowWindow, !IO),
        main_2(Config, GlowWindow, glow_window.context(GlowWindow), !IO)
    ; Config ^ config.back = config.null ->
        % Force GL 0 to indicate a NULL renderer.
        NewConfig = config.config(window.gl_version(0, 0), config.null, 0, 0),
        main_2(NewConfig, null_window.window, null_window.context, !IO)
    ;
        % FLTK is limited to GL 2 (for now?).
        NewConfig = config.config(window.gl_version(2, 1), config.null, W, H),
        % But actually, the fltk_window module isn't done yet!
        throw(software_error("FLTK backend is not yet supported!"))
    ).

%------------------------------------------------------------------------------%
% main_2 creates a renderer and the default scene.
:- pred main_2(config.config::in, Window::in, Context::in, io.io::di, io.io::uo)
     is det <= (window.window(Window), window.gl_context(Context)).
main_2(Config, Window, Context, !IO) :-
    window.show(Window, !IO),
    Config ^ config.gl_version = window.gl_version(Maj, Min),
    ( Maj = 0 -> % Null render
        thread.mvar.init(TimeMVar, !IO),
        thread.mvar.init(SceneMVar, !IO),
        thread.mvar.put(SceneMVar, null_scene, !IO),
        thread.mvar.put(TimeMVar, 0, !IO),
        Renderer = render(null_render.null_render, SceneMVar),
        Engine = engine(null_render.null_render, TimeMVar, SceneMVar)
    ; (Maj =< 2 ; ( Maj = 3, Min < 2) ) -> % OpenGL 1.3, 2.0, 2.1, 3.0, and 3.1
        thread.mvar.init(TimeMVar, !IO),
        thread.mvar.init(SceneMVar, !IO),
        thread.mvar.put(SceneMVar, gl2_scene, !IO),
        thread.mvar.put(TimeMVar, 0, !IO),
        Renderer = render(gl2_render.gl2_render, SceneMVar),
        Engine = engine(gl2_render.gl2_render, TimeMVar, SceneMVar)
    ; (Maj = 4 ; ( Maj = 3, Min > 1) ) -> % OpenGL 3.2+, 4.0+
        throw(software_error("OpenGL 4 not yet supported!"))
    ; % Why do you do this to me?
        throw(software_error("Unknown OpenGL version!"))
    ),
    window.run(Renderer, Engine, Window, !IO).

%------------------------------------------------------------------------------%

main(!IO) :-
    config.load(Config, !IO),
    main_1(Config, !IO).

%------------------------------------------------------------------------------%

engine(_, TimeMVar, SceneMVar, Keys, Events, !IO) :-
    thread.mvar.take(TimeMVar,OldTime, !IO),
    mchrono.micro_ticks(!IO, mchrono.microseconds(Time)),
    Duration = Time - OldTime,
    thread.mvar.put(TimeMVar, Duration, !IO),
    % Dummy empty frame for now.
    thread.mvar.try_put(SceneMVar, quit, _, !IO).

%------------------------------------------------------------------------------%

render(Render, SceneMVar, !IO) :-
    thread.mvar.take(SceneMVar, SceneFrame, !IO),
    (
        SceneFrame = quit
    ;
        SceneFrame = scene(Scene, Matrices),
        scene.draw(Render, Scene, Matrices, 0.0, 0.0, !IO)
    ).
