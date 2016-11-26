:- module opengl.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module mglow.

:- type shader.
:- type frag_shader.
:- type vert_shader.
:- type texture.

:- type shader_type ---> vert ; frag.
:- type shape_type ---> triangle_strip ; triangle_fan ; line_loop ; point.

:- pred use_shader(shader::in, mglow.window::di, mglow.window::uo) is det.

:- pred new_shader(string::in, shader_type::in, int::out, string::out,
    mglow.window::di, mglow.window::uo) is det.

:- pred new_shader_program(shader::in, shader::in, int::out, string::out,
    mglow.window::di, mglow.window::uo) is det.

% Raw GL wrappers
:- pred clear_color(float::in, float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

:- pred clear(mglow.window::di, mglow.window::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- type shader == int.
:- type frag_shader == int.
:- type vert_shader == int.
:- type texture == int.

:- pragma foreign_decl("C", "#include ""glow/glow.h"" ").
:- pragma foreign_decl("C", "#include <GL/gl.h>").
%:- pragma foreign_decl("C", "
%#define GL_GLEXT_PROTOTYPES 1
%#include <GL/glext.h>
%").

:- pragma foreign_enum("C", shader_type/0,
    [
        vert - "GL_VERTEX_SHADER",
        frag - "GL_FRAGMENT_SHADER"
    ]).

:- pragma foreign_enum("C", shape_type/0,
    [
        triangle_strip - "GL_TRIANGLE_STRIP",
        triangle_fan - "GL_TRIANGLE_FAN",
        line_loop - "GL_LINE_LOOP",
        point - "GL_POINTS"
    ]).

:- pragma foreign_proc("C", use_shader(Shader::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    " Glow_MakeCurrent((Win1 = Win0)); glUseProgram(Shader); ").

:- pragma foreign_proc("C",
    new_shader(Src::in, Type::in, Shader::out, Err::out, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    "
        Glow_MakeCurrent((Win1 = Win0)); 
        Shader = glCreateShader(Type);
        {
            GLsizei size = strlen(Src);
            glShaderSource(Shader, 1, &Src, &size);
        }
        
        glCompileShader(Shader);
        
        {
            GLint status;
            glGetShaderiv(Shader, GL_COMPILE_STATUS, &status);
            if(status == GL_FALSE){
                GLint size, written = 0;
                
                glGetShaderiv(Shader, GL_INFO_LOG_LENGTH, &size);
                Err = MR_GC_malloc_atomic(size + 1);
                glGetShaderInfoLog(Shader, size, &written, Err);
                glDeleteShader(Shader);
                Shader = -1;
            }
            else{
                Err = MR_GC_malloc_atomic(1);
                Err[0] = 0;
            }
        }
    ").

:- pragma foreign_proc("C",
    new_shader_program(Vert::in, Frag::in, Shader::out, Err::out, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    "
        GLint prog_stat;
        Glow_MakeCurrent((Win1 = Win0));
#ifndef NDEBUG
        {
            GLint stat;
            glGetShaderiv(Vert, GL_SHADER_TYPE, &stat);
            if(stat != GL_VERTEX_SHADER){
                const char e[] = ""Invalid Vertex Shader"";
                Err = MR_GC_malloc_atomic(sizeof(e));
                memcpy(Err, e, sizeof(e));
                goto ending;
            }
            glGetShaderiv(Frag, GL_SHADER_TYPE, &stat);
            if(stat != GL_FRAGMENT_SHADER){
                const char e[] = ""Invalid Fragment Shader"";
                Err = MR_GC_malloc_atomic(sizeof(e));
                memcpy(Err, e, sizeof(e));
                goto ending;
            }
        }
#endif
        Shader = glCreateProgram();
        glAttachShader(Shader, Frag);
        glAttachShader(Shader, Frag);
        glLinkProgram(Shader);
        
        glGetProgramiv(Shader, GL_LINK_STATUS, &prog_stat);
        
        if(!prog_stat){
            GLint size;
            glGetProgramiv(Shader, GL_INFO_LOG_LENGTH, &size);
            Err = MR_GC_malloc_atomic(size + 1);
            glGetProgramInfoLog(Shader, size, NULL, Err);
            glDeleteProgram(Shader);
            Shader = -1;
        }
        else
            Err = MR_GC_malloc_atomic(1);
            Err[0] = 0;
        ending:

        glDeleteShader(Frag);
        glDeleteShader(Vert);
    ").


:- pragma foreign_proc("C", clear_color(R::in, G::in, B::in, A::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    "
        Glow_MakeCurrent((Win1 = Win0));
        glClearColor(R, G, B, A);
    ").

:- pragma foreign_proc("C", clear(Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    "
        Glow_MakeCurrent((Win1 = Win0));
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    ").
