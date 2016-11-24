:- module gl2renderer.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module renderer.
:- use_module matrix.
:- use_module mglow.
:- use_module wavefront.
%:- use_module io.

%------------------------------------------------------------------------------%

:- type gl2renderer.

:- pred init(gl2renderer::uo, mglow.window::di, mglow.window::uo) is det.

:- pred new_shader(gl2renderer, string, string, renderer.shader_result, mglow.window, mglow.window).
:- mode new_shader(in, in, in, out, di, uo) is det.

:- pred get_shader(gl2renderer, renderer.shader, mglow.window, mglow.window).
:- mode get_shader(in, out, di, uo) is det.

:- pred set_shader(gl2renderer, gl2renderer, renderer.shader, mglow.window, mglow.window).
:- mode set_shader(in, out, in, di, uo) is det.

% Preds used to implement the typeclass.
:- pred matrix(matrix.matrix::in, mglow.window::di, mglow.window::uo) is det.

:- func vertex_shader(string) = string.
:- func fragment_shader(string) = string.
:- func preprocessor(string) = string.

:- instance renderer.renderer(gl2renderer).
:- instance renderer.model(gl2renderer, wavefront.shape).

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module string.
:- use_module opengl.
:- use_module exception.
:- import_module int.
:- import_module list.

:- type shader == opengl.shader.
:- type gl2renderer ---> gl2renderer(shader_list::list(shader), current_shader::renderer.shader).

init(gl2renderer([], 0), !Window) :-
    opengl.clear_color(0.9, 0.5, 0.1, 1.0, !Window).

:- instance renderer.renderer(gl2renderer) where [
    (matrix(M, _, _, !Window) :- matrix(M, !Window)),
    renderer.vertex_shader(S, _) = vertex_shader(S),
    renderer.fragment_shader(S, _) = fragment_shader(S),
    pred(renderer.new_shader/6) is (new_shader),
    pred(renderer.get_shader/4) is (get_shader),
    pred(renderer.set_shader/5) is (set_shader),
    (end_frame(_, !Window) :- opengl.clear(!Window))
].

:- pred render_model(wavefront.shape::in, mglow.window::di, mglow.window::uo) is det.

:- instance renderer.model(gl2renderer, wavefront.shape) where [
    (draw(Model, _, !Window) :- render_model(Model, !Window))
].

:- pred element(list(shader)::in, int::in, int::out) is det.

element([], _, 0).
element([E|L], N, Out) :-
    ( N = 0 ->
        Out = E
    ;
        element(L, N-1, Out)
    ).

get_shader(S, S ^ current_shader, !Window).

:- pragma foreign_decl("C", "#include <GL/gl.h>").
:- pragma foreign_decl("C", "#include <GL/glext.h>").
:- pragma foreign_decl("C", "#include ""glow/glow.h"" ").
:- pragma foreign_decl("C", "#include ""renderer.mh"" ").
:- pragma foreign_decl("C", "#include ""matrix.mh"" ").

set_shader(S, gl2renderer(List, Index), Index, !Window) :-
    List = S ^ shader_list,
    element(List, Index, Shader),
    opengl.use_shader(Shader, !Window).

:- pragma foreign_proc("C", matrix(Matrix::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    "
        Win1 = Win0;
        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        
        glMatrixMode(GL_PROJECTION);

        {
            float mat[16];
            LoadMatrix(Matrix, mat);
            glLoadMatrixf(mat);
        }
    ").

new_shader(_, Vert, Frag, Result, !Window) :-
    opengl.new_shader(Vert, opengl.vert, VertShader, VertErr, !Window),
    opengl.new_shader(Frag, opengl.frag, FragShader, FragErr, !Window),
    ( VertShader >= 0, FragShader >= 0 ->
        opengl.new_shader_program(VertShader, FragShader, Program, ProgErr, !Window),
        ( Program >= 0 ->
            Result = renderer.ok(Program)
        ;
            Result = renderer.err(string.append("PROGRAM: ", ProgErr))
        )
    ;
        Result = renderer.err(string.append(
            string.append("VERTEX: ", VertErr),
            string.append("\nFRAGMENT: ", FragErr)))
    ).

preprocessor(In) = Out :-
    string.append("#version 110\n", In, WithVersion),
    string.replace_all(WithVersion, "%uniform", "uniform", Out).

vertex_shader(In) = Out :-
    preprocessor(In) = Str0,
    string.replace_all(Str0, "%in", "attribute", Str1),
    string.replace_all(Str1, "%out", "varying", Str2),
    string.replace_all(Str2, "%matrix", "gl_ModelViewProjectionMatrix", Out).

fragment_shader(In) = Out :-
    preprocessor(In) = Str0,
    string.replace_all(Str0, "%in", "varying", Str1),
    string.replace_all(Str1, "%color", "gl_FragColor", Out).

:- pred get_element(list(T)::in, int::in, T::out) is semidet.
get_element([Elem|List], N, Out) :-
    N >= 0,
    ( N = 0 ->
        Out = Elem
    ;
        get_element(List, N - 1, Out)
    ).

% Short wrapper to make opengl.vertex and opengl.tex_coord more concise
:- pred point(wavefront.point::in, wavefront.tex::in, mglow.window::di, mglow.window::uo) is det.
point(wavefront.point(X, Y, Z), wavefront.tex(U, V), !Window) :-
    opengl.tex_coord(U, V, !Window), opengl.vertex(X, Y, Z, !Window).

render_model(S, !Window) :- S ^ wavefront.faces = [].
render_model(wavefront.shape(Vert, Tex, N, I), !Window) :-
    I = [wavefront.face(V0, V1, V2)|List],
    V = get_element(Vert), T = get_element(Tex), % Lazy names.
    V0 = wavefront.vertex(VertexIndex0, TexCoordIndex0),
    V1 = wavefront.vertex(VertexIndex1, TexCoordIndex1),
    V2 = wavefront.vertex(VertexIndex2, TexCoordIndex2),
    (
      V(VertexIndex0, Vertex0),
      V(VertexIndex1, Vertex1),
      V(VertexIndex2, Vertex2) -> 
        opengl.begin(opengl.triangle_strip, !Window),
        (
          T(TexCoordIndex0, TexCoord0),
          T(TexCoordIndex1, TexCoord1),
          T(TexCoordIndex2, TexCoord2) ->
            point(Vertex0, TexCoord0, !Window),
            point(Vertex1, TexCoord1, !Window),
            point(Vertex2, TexCoord2, !Window)
        ;
            T0 = wavefront.tex(0.0, 0.0),
            point(Vertex0, T0, !Window),
            point(Vertex1, T0, !Window),
            point(Vertex2, T0, !Window)
        ),
        opengl.end(!Window)
    ;
        string.append("Invalid indices: ", string.from_int(list.length(Vert)), Err),
        exception.throw(exception.software_error(Err)),
        true % Pass
    ),
    render_model(wavefront.shape(Vert, Tex, N, List), !Window).
