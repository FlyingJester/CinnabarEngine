:- module gl2_render.heightmap.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module render.
:- import_module list.
:- use_module opengl.
:- use_module opengl.texture.

%------------------------------------------------------------------------------%

:- type panel.
:- type heightmap ---> heightmap(list(panel)).
:- func init = panel.

:- instance model.loadable(panel).
:- instance render.heightmap(gl2_render.gl2_render, heightmap, opengl.texture.texture, mglow.window).

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module opengl2.
:- use_module model.
:- use_module mglow.

:- type panel ---> panel(list(model.vertex)).

init = panel([]).

:- instance model.loadable(panel) where [
    next(Vertex, panel(Vertices),
        panel(list.append(Vertices, [Vertex|[]])))
].

:- pred draw(panel::in, mglow.window::di, mglow.window::uo) is det.
draw(panel(Vertices), !Window) :-
    opengl2.begin(opengl.triangle_fan, !Window),
    opengl2.color(1.0, 1.0, 1.0, 1.0, !Window),
    list.foldl(gl2_render.draw_model_vertex, Vertices, !Window),
    opengl2.end(!Window).

:- instance render.heightmap(gl2_render.gl2_render, heightmap, opengl.texture.texture, mglow.window) where [
    (draw_heightmap(_, heightmap(Faces), Tex, !Window) :-
        opengl.texture.bind_texture(Tex, !Window),
        list.foldl(draw, Faces, !Window)
    )
].
