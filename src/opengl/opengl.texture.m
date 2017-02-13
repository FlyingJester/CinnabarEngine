:- module opengl.texture.
%==============================================================================%
:- interface.
%==============================================================================%

:- type texture.

% upload_texture(Output, Pixels, W, H, !Window)
:- pred upload_texture(texture::uo, c_pointer::in, int::in, int::in,
    Window::di, Window::uo) is det.

:- pred bind_texture(texture::in, Window::di, Window::uo) is det. 

%==============================================================================%
:- implementation.
%==============================================================================%

:- pragma foreign_decl("C", "
#ifdef _WIN32
#include <Windows.h>
#endif
#include <GL/gl.h>
").

:- pragma foreign_decl("C", "
    void Cinnabar_OpenGL_TextureFinalizer(void *in, void *unused);
").

:- pragma foreign_code("C", "
    void Cinnabar_OpenGL_TextureFinalizer(void *in, void *win){
        glDeleteTextures(1, (GLuint*)in);
    }
").

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
        Tex = MR_GC_malloc_atomic(sizeof(void*));
        Tex[0] = tex;
        MR_GC_register_finalizer(Tex, Cinnabar_OpenGL_TextureFinalizer, (void*)Win1);
    ").

:- pragma foreign_proc("C",
    bind_texture(Tex::in, Win0::di, Win1::uo),
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        Win1 = Win0;
        glBindTexture(GL_TEXTURE_2D, *((GLuint*)Tex));
    ").
