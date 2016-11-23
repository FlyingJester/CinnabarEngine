:- module renderer.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module mglow.
:- use_module matrix.

:- type shader == int.
:- type shader_result ---> ok(shader) ; err(string).

:- typeclass renderer(Renderer) where [
    pred matrix(matrix.matrix, Renderer, shader, mglow.window, mglow.window),
    mode matrix(in, in, in, di, uo) is det,
    
    func vertex_shader(string, Renderer) = string,
    func fragment_shader(string, Renderer) = string,
    
    pred new_shader(Renderer, string, string, shader_result, mglow.window, mglow.window),
    mode new_shader(in, in, in, out, di, uo) is det,

    pred get_shader(Renderer, shader, mglow.window, mglow.window),
    mode get_shader(in, out, di, uo) is det,

    pred set_shader(Renderer, Renderer, shader, mglow.window, mglow.window),
    mode set_shader(in, out, in, di, uo) is det,

    pred end_frame(Renderer::in, mglow.window::di, mglow.window::uo) is det
].

:- typeclass model(Renderer, Model) <= renderer(Renderer) where [
    pred draw(Model, Renderer, mglow.window, mglow.window),
    mode draw(in, in, di, uo) is det
].

:- func create_shader_ok(shader) = shader_result.
:- func create_shader_err(string) = shader_result.

%==============================================================================%
:- implementation.
%==============================================================================%

create_shader_ok(S) = ok(S).
create_shader_err(E) = err(E).

:- pragma foreign_export("C", create_shader_ok(in) = (out), "CreateShaderOK").
:- pragma foreign_export("C", create_shader_err(in) = (out), "CreateShaderErr").

:- pragma foreign_export("Java", create_shader_ok(in) = (out), "CreateShaderOK").
:- pragma foreign_export("Java", create_shader_err(in) = (out), "CreateShaderErr").
