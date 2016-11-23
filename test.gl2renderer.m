:- module test.gl2renderer.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
%------------------------------------------------------------------------------%

:- pred test(io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module gl2renderer.
:- import_module list.
%------------------------------------------------------------------------------%

:- func vertex_test_1 = string.
vertex_test_1 = "%in vec3 vertex;
%in vec2 tex_input;
%out vec2 tex_coord;

void main(){
    gl_Position = %matrix * vec4(vertex, 1.0);
    tex_coord = tex_input;
}
".

:- func vertex_test_1_ver_str = string.
vertex_test_1_ver_str = "#version 110
attribute vec3 vertex;
attribute vec2 tex_input;
varying vec2 tex_coord;

void main(){
    gl_Position = gl_ModelViewProjectionMatrix * vec4(vertex, 1.0);
    tex_coord = tex_input;
}
".

:- pred vertex_test_1_ver(string::in) is semidet.
vertex_test_1_ver(vertex_test_1_ver_str).

:- pred gl2vertex_tester(string::in, string::out) is det.
gl2vertex_tester(In, gl2renderer.vertex_shader(In)).

:- pred test(io.io::di, io.io::uo, int::di, int::uo, int::di, int::uo) is det.
test(!IO) :- test(!IO, 0, OK, 0, Sum), sum_suite(!IO, "GL2", OK, Sum).
test(!IO, !N, !Sum) :-
    run_test(!IO, "Vertex Shader", vertex_test_1, vertex_test_1_ver, gl2vertex_tester, !N, !Sum).
