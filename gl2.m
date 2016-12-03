:- module gl2.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module mglow.
:- use_module opengl.
:- use_module render.
:- use_module wavefront.

:- import_module list.

:- type gl2.

% Raw OpenGL 2 wrapping
:- type matrix_mode ---> modelview ; projection.

:- pred matrix_mode(matrix_mode::in, mglow.window::di, mglow.window::uo) is det.

:- pred load_identity(mglow.window::di, mglow.window::uo) is det.

% OLD - Sets the default ortho mode with the given width/height
% orth(W, H, !Window)
:- pred ortho(float::in, float::in, mglow.window::di, mglow.window::uo) is det.
:- pragma obsolete(ortho/4).

% orth(NearZ, FarZ, Left, Right, Top, Bottom, !Window)
:- pred ortho(float, float, float, float, float, float, mglow.window, mglow.window).
:- mode ortho(in, in, in, in, in, in, di, uo) is det.

% Translates to glVertex(X, Y)
% vertex2(X, Y, !Window)
:- pred vertex2(float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

% Translates to glVertex(X, Y, Z)
% vertex3(X, Y, Z, !Window)
:- pred vertex3(float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

% Translates to glTexCoord(U, V)
% tex_coord(U, V !Window)
:- pred tex_coord(float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

% Translates to glColor3f(R, G, B)
% color3(R, G, B, !Window)
:- pred color3(float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

% Translates to glColor4f(R, G, B, A)
% color(R, G, B, A, !Window)
:- pred color(float::in, float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

% Translates to glBegin()
% begin(Type, !Window)
:- pred begin(opengl.shape_type::in, mglow.window::di, mglow.window::uo) is det.


:- pred end(mglow.window::di, mglow.window::uo) is det.

:- pred frustum(float, float, float, float, float, float, mglow.window, mglow.window).
:- mode frustum(in, in, in, in, in, in, di, uo) is det.

% Actual renderer stuff

% Used to get an instance of gl2. Currently a dummy function, but keeps gl2/0 opaque.
:- pred init(mglow.window::di, mglow.window::uo, gl2::uo) is det.

% Draws a single wavefront shape.
:- pred draw(wavefront.shape::in, mglow.window::di, mglow.window::uo) is det.

% Draws a single wavefront face. Used to implement draw/3
:- pred draw(wavefront.face::in,
    list(wavefront.point)::in,
    list(wavefront.tex)::in,
    mglow.window::di, mglow.window::uo) is det.

% Used for folding over the list of faces in a wavefront shape.
:- pred draw(wavefront.vertex::in,
    list(wavefront.point)::in, list(wavefront.point)::out,
    list(wavefront.tex)::in, list(wavefront.tex)::out,
    mglow.window::di, mglow.window::uo) is det.

:- type vertex2d ---> vertex(x2::float, y2::float, u2::float, v2::float).
:- type vertex3d ---> vertex(x3::float, y3::float, z3::float, u3::float, v3::float).
:- type shape2d ---> shape2d(list(vertex2d), opengl.texture) ;
    shape2d(list(vertex2d)) ;
    shape2d(list(vertex2d), float, float, float).

:- type shape3d ---> shape3d(list(vertex3d), opengl.texture).

% Abstraction for vertex2 and vertex3.
:- typeclass vertex(T) where [
    func x(T) = float,
    func y(T) = float,
    func z(T) = float,
    func u(T) = float,
    func v(T) = float,
    % Used with list.foldl to draw shapes.
    pred draw_vertex(T::in, mglow.window::di, mglow.window::uo) is det
].

:- instance vertex(vertex2d).
:- instance vertex(vertex3d).

:- func rectangle(float, float, float, float) = shape2d.
:- func add_texture(shape2d, opengl.texture) = shape2d.

:- instance render.model(gl2, wavefront.shape).
:- instance render.model(gl2, shape2d).
:- instance render.model(gl2, shape3d).
:- instance render.render(gl2).

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module opengl.
:- import_module int.
:- import_module float.

:- type gl2 ---> q. % dummy.

init(!Window, q).

:- pragma foreign_decl("C", "#include ""glow/glow.h"" ").
:- pragma foreign_decl("C", "
#ifdef _WIN32
#include <Windows.h>
#endif
#include <GL/gl.h>
").

:- pragma foreign_enum("C", matrix_mode/0,
    [
        modelview - "GL_MODELVIEW",
        projection - "GL_PROJECTION"
    ]).

:- pragma foreign_proc("C", matrix_mode(Mode::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glMatrixMode(Mode); ").

:- pragma foreign_proc("C", load_identity(Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glLoadIdentity(); ").
    
:- pragma foreign_proc("C", vertex2(X::in, Y::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glVertex2f(X, Y); ").

:- pragma foreign_proc("C", vertex3(X::in, Y::in, Z::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glVertex3f(X, Y, Z); ").

:- pragma foreign_proc("C", tex_coord(U::in, V::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glTexCoord2f(U, V); ").

:- pragma foreign_proc("C", color3(R::in, G::in, B::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glColor3f(R, G, B); ").

:- pragma foreign_proc("C", color(R::in, G::in, B::in, A::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glColor4f(R, G, B, A); ").

:- pragma foreign_proc("C", begin(Type::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glBegin(Type); ").

:- pragma foreign_proc("C", end(Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glEnd(); ").

:- pragma foreign_proc("C", ortho(W::in, H::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, W, H, 0, -1.0, 1.0);
    ").

:- pragma foreign_proc("C",
    ortho(NearZ::in, FarZ::in, Left::in, Right::in, Top::in, Bottom::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glOrtho(Left, Right, Bottom, Top, NearZ, FarZ); ").

:- pragma foreign_proc("C",
    frustum(NearZ::in, FarZ::in, Left::in, Right::in, Top::in, Bottom::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glFrustum(Left, Right, Bottom, Top, NearZ, FarZ); ").

draw(Shape, !Window) :- Shape ^ wavefront.faces = [].
draw(wavefront.shape(Vertices, TexCoords, N, [Face|List]), !Window) :-
    draw(Face, Vertices, TexCoords, !Window),
    draw(wavefront.shape(Vertices, TexCoords, N, List), !Window).

:- pred mode(list(T)::in, opengl.shape_type::uo) is semidet.

mode([_|[]], opengl.point).
mode([_|[_|[]]], opengl.line_loop).
mode([_|[_|[_|[]]]], opengl.triangle_strip).
mode([_|[_|[_|[_|[]]]]], opengl.triangle_fan).
mode([_|[_|[_|[_|[_|_]]]]], opengl.triangle_strip).

draw(wavefront.face(F), Vertices, TexCoords, !Window) :-
    ( mode(F, Mode) ->
        begin(Mode, !Window),
        list.foldl3(draw, F, Vertices, _, TexCoords, _, !Window),
        end(!Window)
    ;
        true % Pass.
    ).

:- instance render.model(gl2, wavefront.shape) where [
    (render.draw(q, Model, !Window) :- draw(Model, !Window))
].

rectangle(X, Y, W, H) = shape2d([vertex(X, Y, 0.0, 0.0)
    |[vertex(X+W, Y,   1.0, 0.0)
    |[vertex(X+W, Y+H, 1.0, 1.0)
    |[vertex(X,   Y+H, 0.0, 1.0)
    |[]]]]]).


add_texture(shape2d(V), T) = shape2d(V, T).
add_texture(shape2d(V, _), T) = shape2d(V, T).
add_texture(shape2d(V, _, _, _), T) = shape2d(V, T).

:- instance vertex(vertex2d) where [
    x(V) = V ^ x2,
    y(V) = V ^ y2,
    z(_) = 0.0,
    u(V) = V ^ u2,
    v(V) = V ^ v2,
    (draw_vertex(vertex(X, Y, U, V), !Window) :-
        tex_coord(U, V, !Window), vertex2(X, Y, !Window))
].

:- instance vertex(vertex3d) where [
    x(V) = V ^ x3,
    y(V) = V ^ y3,
    z(V) = V ^ z3,
    u(V) = V ^ u3,
    v(V) = V ^ v3,
    (draw_vertex(vertex(X, Y, Z, U, V), !Window) :-
        tex_coord(U, V, !Window), vertex3(X, Y, Z, !Window))
].

:- instance render.model(gl2, shape2d) where [
    (render.draw(q, Shape, !Window) :-
        (
            Shape = shape2d(Vertices, R, G, B)
        ;
            R = 1.0, G = 1.0, B = 1.0,
            opengl.bind_texture(Tex, !Window),
            Shape = shape2d(Vertices, Tex)
        ;
            R = 1.0, G = 1.0, B = 1.0,
            Shape = shape2d(Vertices)
        ),
        ( mode(Vertices, Mode) ->
            begin(Mode, !Window),
            color(R, G, B, 1.0, !Window),
            list.foldl(draw_vertex, Vertices, !Window),
            end(!Window),
            color3(1.0, 1.0, 1.0, !Window)
        ;
            true % Pass
        )
    )
].

:- instance render.model(gl2, shape3d) where [
    (render.draw(q, Shape, !Window) :- 
        Shape = shape3d(Vertices, Tex),
        ( mode(Vertices, Mode) ->
            opengl.bind_texture(Tex, !Window),
            begin(Mode, !Window),
            list.foldl(draw_vertex, Vertices, !Window),
            end(!Window)
        ;
            true % Pass
        )
    )
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
use_point(wavefront.point(X, Y, Z), !Window) :- vertex3(X, Y, Z, !Window).

:- pred use_tex_coord(wavefront.tex::in, mglow.window::di, mglow.window::uo) is det.
use_tex_coord(wavefront.tex(U, V), !Window) :- tex_coord(U, V, !Window).

draw(wavefront.vertex(V, T), !Points, !TexCoords, !Window) :-
    use_element(use_tex_coord, !.TexCoords, T, !Window),
    use_element(use_point, !.Points, V, !Window).

:- instance render.render(gl2) where [
    (frustum(_, NearZ, FarZ, Left, Right, Top, Bottom, !Window) :-
        frustum(NearZ, FarZ, Left, Right, Top, Bottom, !Window))
].
