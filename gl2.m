:- module gl2.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module mglow.
:- use_module render.
:- use_module wavefront.

:- import_module list.

% Raw OpenGL 2 wrapping

:- type shape_type ---> triangle_strip ; triangle_fan ; line_loop ; point.

:- pred ortho(float::in, float::in, mglow.window::di, mglow.window::uo) is det.

:- pred vertex2(float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.
:- pred vertex(float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

:- pred tex_coord(float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

:- pred color3(float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.
:- pred color(float::in, float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

:- pred clear_color(float::in, float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

:- pred clear(mglow.window::di, mglow.window::uo) is det.

:- pred begin(shape_type::in, mglow.window::di, mglow.window::uo) is det.
:- pred end(mglow.window::di, mglow.window::uo) is det.

:- type gl2.

:- pred init(mglow.window::di, mglow.window::uo, gl2::uo) is det.

:- pred draw(wavefront.shape::in, mglow.window::di, mglow.window::uo) is det.

:- pred draw(wavefront.face::in,
    list(wavefront.point)::in,
    list(wavefront.tex)::in,
    mglow.window::di, mglow.window::uo) is det.

% Used for mapping
:- pred draw(wavefront.vertex::in,
    list(wavefront.point)::in, list(wavefront.point)::out,
    list(wavefront.tex)::in, list(wavefront.tex)::out,
    mglow.window::di, mglow.window::uo) is det.

:- instance render.model(gl2, wavefront.shape).
:- instance render.render(gl2).

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module opengl.
:- import_module int.

:- type gl2 ---> q. % dummy.

init(!Window, q).

:- pragma foreign_decl("C", "#include ""glow/glow.h"" ").
:- pragma foreign_decl("C", "#include <GL/gl.h>").

:- pragma foreign_enum("C", shape_type/0,
    [
        triangle_strip - "GL_TRIANGLE_STRIP",
        triangle_fan - "GL_TRIANGLE_FAN",
        line_loop - "GL_LINE_LOOP",
        point - "GL_POINTS"
    ]).

:- pragma foreign_proc("C", vertex2(X::in, Y::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glVertex2f(X, Y); ").

:- pragma foreign_proc("C", vertex(X::in, Y::in, Z::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glVertex3f(X, Y, Z); ").

:- pragma foreign_proc("C", tex_coord(U::in, V::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glTexCoord2f(U, V); ").

:- pragma foreign_proc("C", color3(R::in, G::in, B::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glColor3f(R, G, B); ").

:- pragma foreign_proc("C", color(R::in, G::in, B::in, A::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glColor4f(R, G, B, A); ").

:- pragma foreign_proc("C", begin(Type::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glBegin(Type); ").

:- pragma foreign_proc("C", end(Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glEnd(); ").

:- pragma foreign_proc("C", clear_color(R::in, G::in, B::in, A::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glClearColor(R, G, B, A); ").

:- pragma foreign_proc("C", clear(Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Win1 = Win0; glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); ").

:- pragma foreign_proc("C", ortho(W::in, H::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    "
        Win1 = Win0;
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, W, H, 0, -1.0, 1.0);
    ").

draw(Shape, !Window) :- Shape ^ wavefront.faces = [].
draw(wavefront.shape(Vertices, TexCoords, N, [Face|List]), !Window) :-
    draw(Face, Vertices, TexCoords, !Window),
    draw(wavefront.shape(Vertices, TexCoords, N, List), !Window).

% Nothing
draw(wavefront.face([]), _, _, !Window).
%Point
draw(wavefront.face([V0|[]]), Vertices, TexCoords, !Window) :-
    opengl.begin(opengl.point, !Window),
    draw(V0, Vertices, _, TexCoords, _, !Window),
    opengl.end(!Window).
%Line
draw(wavefront.face([V0|[V1|[]]]), Vertices, TexCoords, !Window) :-
    opengl.begin(opengl.line_loop, !Window),
    draw(V0, Vertices, _, TexCoords, _, !Window),
    draw(V1, Vertices, _, TexCoords, _, !Window),
    opengl.end(!Window).
% Triangle or Poly
draw(wavefront.face(F), Vertices, TexCoords, !Window) :-
    (
        F = [_|[_|[_|[]]]]
    ;
        F = [_|[_|[_|[_|[_|_]]]]]
    ),
    opengl.begin(opengl.triangle_strip, !Window),
    list.foldl3(draw, F, Vertices, _, TexCoords, _, !Window),
    opengl.end(!Window).
% Quad
draw(wavefront.face(F), Vertices, TexCoords, !Window) :-
    F = [_|[_|[_|[_|[]]]]],
    opengl.begin(opengl.triangle_fan, !Window),
    list.foldl3(draw, F, Vertices, _, TexCoords, _, !Window),
    opengl.end(!Window).

:- instance render.model(gl2, wavefront.shape) where [
    (render.draw(q, Model, !Window) :- draw(Model, !Window))
].

:- pred use_element(pred(T, mglow.window, mglow.window), list(T), int, mglow.window, mglow.window).
:- mode use_element(pred(in, di, uo) is det, in, in, di, uo).

use_element(_, [], _, !Window).
use_element(Pred, [E|List], N, !Window) :-
    ( N =< 0 ->
        Pred(E, !Window)
    ;
        use_element(Pred, List, N-1, !Window)
    ).

:- pred use_point(wavefront.point::in, mglow.window::di, mglow.window::uo) is det.
use_point(wavefront.point(X, Y, Z), !Window) :- opengl.vertex(X, Y, Z, !Window).

:- pred use_tex_coord(wavefront.tex::in, mglow.window::di, mglow.window::uo) is det.
use_tex_coord(wavefront.tex(U, V), !Window) :- opengl.tex_coord(U, V, !Window).

draw(wavefront.vertex(V, T), !Points, !TexCoords, !Window) :-
    use_element(use_tex_coord, !.TexCoords, T, !Window),
    use_element(use_point, !.Points, V, !Window).

:- instance render.render(gl2) where [
    (frustum(_, NearZ, FarZ, Left, Right, Top, Bottom, !Window) :-
        opengl.frustum(NearZ, FarZ, Left, Right, Top, Bottom, !Window))
].
