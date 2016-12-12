:- module opengl.
%==============================================================================%
% Wrapper for common OpenGL functions that are used by both the GL2 and GL4
% renderers. All functions here must be present in OpenGL 1.3 so that no
% function loading is required. If we end up needing some later functionality
% that should be shared between GL2 and GL4, we can make an opengl_ext.m
% module that will handle that.
:- interface.
%==============================================================================%

:- use_module mglow.

:- type shader.
:- type frag_shader.
:- type vert_shader.
:- type texture.

:- type shader_type ---> vert ; frag.
:- type shape_type ---> triangle_strip ; triangle_fan ;  triangles ; line_loop ; point ; lines.
:- type filter_set ---> mag_filter ; min_filter.
:- type filter_type ---> linear ; nearest.

% upload_texture(Output, Pixels, W, H, !Window)
:- pred upload_texture(texture::uo, c_pointer::in, int::in, int::in,
    mglow.window::di, mglow.window::uo) is det.

:- pred bind_texture(texture::in, mglow.window::di, mglow.window::uo) is det. 

:- pred texture_filter(filter_set::in, filter_type::in, mglow.window::di, mglow.window::uo) is det.

% draw_arrays(Type, FirstIndex, Count, !Window)
:- pred draw_arrays(shape_type::in, int::in, int::in,
    mglow.window::di, mglow.window::uo) is det.

:- pred clear_color(float::in, float::in, float::in, float::in,
    mglow.window::di, mglow.window::uo) is det.

:- pred clear(mglow.window::di, mglow.window::uo) is det.

% viewport(X, Y, W, H)
:- pred viewport(int::in, int::in, int::in, int::in,
    mglow.window::di, mglow.window::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- type shader == int.
:- type frag_shader == int.
:- type vert_shader == int.

:- pragma foreign_decl("C", "#include ""glow/glow.h"" ").
:- pragma foreign_decl("C", "
#ifdef _WIN32
#include <Windows.h>
#endif
#include <GL/gl.h>
").

:- pragma foreign_decl("C", "
    void OpenGL_TextureFinalizer(void *in, void *unused);
").

:- pragma foreign_code("C", "
    void OpenGL_TextureFinalizer(void *in, void *win){
        Glow_MakeCurrent((struct Glow_Window*)win);
        glDeleteTextures(1, (GLuint*)in);
    }
").

:- pragma foreign_enum("C", shape_type/0,
    [
        triangle_strip - "GL_TRIANGLE_STRIP",
        triangle_fan - "GL_TRIANGLE_FAN",
        triangles - "GL_TRIANGLES",
        line_loop - "GL_LINE_LOOP",
        lines - "GL_LINES",
        point - "GL_POINTS"
    ]).

:- pragma foreign_enum("C", filter_set/0,
    [
        min_filter - "GL_TEXTURE_MAG_FILTER",
        mag_filter - "GL_TEXTURE_MIN_FILTER"
    ]).

:- pragma foreign_enum("C", filter_type/0,
    [
        linear - "GL_LINEAR",
        nearest - "GL_NEAREST"
    ]).

:- pragma foreign_type("C", texture, "GLuint*").

:- pragma foreign_proc("C",
    upload_texture(Tex::uo, Data::in, W::in, H::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception, thread_safe, promise_pure],
    "
        GLuint tex;
        Win1 = Win0;
        glGenTextures(1, &tex);
        glBindTexture(GL_TEXTURE_2D, tex);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, (void*)Data);
        Tex = MR_GC_malloc_atomic(8);
        Tex[0] = tex;
        MR_GC_register_finalizer(Tex, OpenGL_TextureFinalizer, Win1);
    ").

:- pragma foreign_proc("C",
    bind_texture(Tex::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glBindTexture(GL_TEXTURE_2D, *((GLuint*)Tex));
    ").

:- pragma foreign_proc("C",
    texture_filter(Set::in, Type::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glTexParameterf(GL_TEXTURE_2D, Set, Type);
    ").

:- pragma foreign_proc("C", clear_color(R::in, G::in, B::in, A::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glClearColor(R, G, B, A);
    ").
    
:- pragma foreign_proc("C", draw_arrays(Type::in, I::in, Count::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glDrawArrays(Type, I, Count);
    ").

:- pragma foreign_proc("C", clear(Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    ").

:- pragma foreign_proc("C",
    viewport(X::in, Y::in, W::in, H::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glViewport(X, Y, W, H);
    ").
