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
:- instance render.heightmap(gl2_render.gl2_render, heightmap, opengl.texture.texture).

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module opengl2.
:- use_module model.

:- type panel ---> panel(list(model.vertex)).

init = panel([]).

:- instance model.loadable(panel) where [
    next(Vertex, panel(Vertices),
        panel(list.append(Vertices, [Vertex|[]])))
].

:- pred draw(panel::in, io.io::di, io.io::uo) is det.
draw(panel(Vertices), !IO) :-
    opengl2.begin(opengl.triangle_fan, !IO),
    opengl2.color(1.0, 1.0, 1.0, 1.0, !IO),
    list.foldl(gl2_render.draw_model_vertex, Vertices, !IO),
    opengl2.end(!IO).

:- instance render.heightmap(gl2_render, heightmap, opengl.texture.texture) where [
    (draw_heightmap(gl2_render, heightmap(Faces), Tex, !IO) :-
        opengl.texture.bind_texture(Tex, !IO),
        list.foldl(draw, Faces, !IO)
    )
].
