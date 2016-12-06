:- module gl2.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module mglow.
:- use_module opengl.
:- use_module render.
:- use_module wavefront.
:- use_module softshape.

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

:- pred unbind_texture(mglow.window::di, mglow.window::uo) is det.

% Translates to glBegin()
% begin(Type, !Window)
:- pred begin(opengl.shape_type::in, mglow.window::di, mglow.window::uo) is det.

:- pred end(mglow.window::di, mglow.window::uo) is det.

:- pred draw_pixels(int::in, int::in, c_pointer::in,
    mglow.window::di, mglow.window::uo) is det.
:- pred raster_pos(float::in, float::in, mglow.window::di, mglow.window::uo) is det.

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

:- type shape2d ---> shape2d(softshape.shape2d) ; shape2d(softshape.shape2d, opengl.texture).
:- type shape3d ---> shape3d(softshape.shape3d) ; shape3d(softshape.shape3d, opengl.texture).

:- typeclass vertex(T) where [
    % Used with list.foldl to draw shapes.
    pred draw_vertex(T::in, mglow.window::di, mglow.window::uo) is det
].

:- instance vertex(softshape.vertex2d).
:- instance vertex(softshape.vertex3d).

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

:- type gl2 ---> gl2(w::int, h::int).

init(!Window, gl2(W, H)) :- mglow.size(!Window, W, H).

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
    
:- pragma foreign_proc("C", unbind_texture(Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glBindTexture(GL_TEXTURE_2D, 0); ").

:- pragma foreign_proc("C", begin(Type::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glBegin(Type); ").

:- pragma foreign_proc("C", end(Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Win1 = Win0; glEnd(); ").


:- pragma foreign_proc("C", draw_pixels(W::in, H::in, Pix::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glDrawPixels(W, H, GL_RGBA, GL_UNSIGNED_BYTE, (const void*)Pix);
    ").

:- pragma foreign_proc("C", raster_pos(X::in, Y::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glRasterPos2f(X, Y);
    ").

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
    (render.draw(_, Model, !Window) :- draw(Model, !Window))
].


:- instance render.model(gl2, shape2d) where [
    (render.draw(_, Shape, !Window) :-
        (
            Shape = shape2d(SoftShape, Tex),
            opengl.bind_texture(Tex, !Window)
        ;
            Shape = shape2d(SoftShape),
            unbind_texture(!Window)
        ),
        (
            SoftShape = softshape.shape2d(Vertices, R, G, B)
        ;
            R = 1.0, G = 1.0, B = 1.0,
            SoftShape = softshape.shape2d(Vertices)
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
    (render.draw(_, Shape, !Window) :- 
        (
            Shape = shape3d(SoftShape, Tex),
            Binder = opengl.bind_texture(Tex)
        ;
            Shape = shape3d(SoftShape),
            Binder = unbind_texture
        ),
        (
            R = 1.0, G = 1.0, B = 1.0,
            SoftShape = softshape.shape3d(Vertices)
        ;
            SoftShape = softshape.shape3d(Vertices, R, G, B)
        ),
        ( mode(Vertices, Mode) ->
            color(R, G, B, 1.0, !Window),
            Binder(!Window),
            begin(Mode, !Window),
            list.foldl(draw_vertex, Vertices, !Window),
            end(!Window)
        ;
            true % Pass
        )
    )
].

:- instance vertex(softshape.vertex2d) where [
    (draw_vertex(softshape.vertex(X, Y, U, V), !Window) :-
        tex_coord(U, V, !Window), vertex2(X, Y, !Window))
].

:- instance vertex(softshape.vertex3d) where [
    (draw_vertex(softshape.vertex(X, Y, Z, U, V), !Window) :-
        tex_coord(U, V, !Window), vertex3(X, Y, Z, !Window))
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
        frustum(NearZ, FarZ, Left, Right, Top, Bottom, !Window)),
    (render.draw_image(gl2(WinW, WinH), X, Y, W, H, Pix, !Window) :-
        raster_pos(float(X) / float(WinW), float(Y) / float(WinH), !Window),
        draw_pixels(W, H, Pix, !Window),
        raster_pos(0.0, 0.0, !Window)
    )
].
