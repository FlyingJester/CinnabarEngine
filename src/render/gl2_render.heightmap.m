:- module gl2_render.heightmap.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module render.
:- import_module list.
:- use_module opengl.

%------------------------------------------------------------------------------%

:- type panel.
:- type heightmap ---> heightmap(list(panel)).
:- func init = panel.

:- instance model.loadable(panel).
:- instance render.heightmap(gl2, heightmap, opengl.texture).

%==============================================================================%
:- implementation.
%==============================================================================%

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
    begin(opengl.triangle_fan, !Window),
    color(1.0, 1.0, 1.0, 1.0, !Window),
    list.foldl(gl2.draw_vertex, Vertices, !Window),
    end(!Window).

:- instance render.heightmap(gl2, heightmap, opengl.texture) where [
    (draw_heightmap(_, heightmap(Faces), Tex, !Window) :-
        opengl.bind_texture(Tex, !Window),
        list.foldl(draw, Faces, !Window)
    )
].
