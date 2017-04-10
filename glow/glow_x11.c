#include "glow.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>

#ifdef __APPLE__

#include <OpenGL/gl.h>
#include <OpenGL/glx.h>

#else

#include <GL/gl.h>
#include <GL/glx.h>

#endif

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#define GLOW_X_EVENT_MASK\
    (StructureNotifyMask\
    |KeyPressMask\
    |KeyReleaseMask\
    |ButtonPress\
    |ExposureMask)

/* Gets a display, first using the DISPLAY environment variable, then using the
 * X default (which may be different than the env variable depending on the DE),
 * and finally we just try 0, 0.
 */
static Display *glow_get_display(){
    char *const dpy_env = getenv("DISPLAY");
    Display *dpy;
    if((dpy = XOpenDisplay(dpy_env)))
        return dpy;
    if((dpy = XOpenDisplay(NULL)))
        return dpy;
    if((dpy = XOpenDisplay(":0.0")))
        return dpy;
    return NULL;
}

static const GLint glow_attribs[] = {
    GLX_X_RENDERABLE, True,
    GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
    GLX_RENDER_TYPE, GLX_RGBA_BIT,
    GLX_X_VISUAL_TYPE, GLX_TRUE_COLOR,
    GLX_RED_SIZE, 6,
    GLX_GREEN_SIZE, 6,
    GLX_BLUE_SIZE, 6,
    GLX_ALPHA_SIZE, 6,
    GLX_DEPTH_SIZE, 8,
    GLX_DOUBLEBUFFER, True,
    None
};

struct Glow_Context {
    unsigned char gl[2];
    Display *dpy;
    Window wnd;
    GLXContext ctx;
};

struct Glow_Window{
    
    Display *dpy;
    Screen *scr;
    int scr_id;
    Window wnd;
    Colormap cmap;
    
    struct Glow_Context *ctx;
    XVisualInfo *vis;
    
    GLXFBConfig fbconfig;
    
    unsigned w, h;
    int mouse_x, mouse_y;
};

unsigned Glow_WindowStructSize(){
    return sizeof(struct Glow_Window);
}

void Glow_CreateWindow(struct Glow_Window *window,
    unsigned w, unsigned h, const char *title, int flags){
    
    window->w = w;
    window->h = h;

    window->mouse_x = 0;
    window->mouse_y = 0;
    
    window->dpy = glow_get_display();
    
    if(window->dpy == NULL){
        fputs("Could not open an X11 display\n", stderr);
        return;
    }
    
    window->scr = DefaultScreenOfDisplay(window->dpy);
    window->scr_id = DefaultScreen(window->dpy);
    
    /* Fiddle about determining the best fbconfig. */
    {
        int num = 0, i, best = -1, best_samples = -1;
        GLXFBConfig *const config = glXChooseFBConfig(window->dpy,
            window->scr_id, glow_attribs, &num);
        if(config == NULL || num == 0){
            fputs("Could not get glX framebuffer configuration\n", stderr);
            XCloseDisplay(window->dpy);
            window->dpy = NULL;
            return;
        }
        for(i = 0; i < num; i++){
            XVisualInfo *const info =
                glXGetVisualFromFBConfig(window->dpy, config[i]);
            if(info != NULL){
                int sample_buffers, samples;
                glXGetFBConfigAttrib(window->dpy, config[i],
                    GLX_SAMPLE_BUFFERS, &sample_buffers);
                glXGetFBConfigAttrib(window->dpy, config[i],
                    GLX_SAMPLES, &samples);
                
                if(best < 0 || (sample_buffers > 0 && samples > best_samples)){
                    best = i;
                    best_samples = samples;
                }
                XFree(info);
            }
        }
        
        assert(best != -1);
        assert(best < num);
        
        window->fbconfig = config[best];

        XFree(config);
    }

    /* Get a glX visual info for the fbconfig */
    window->vis = glXGetVisualFromFBConfig(window->dpy, window->fbconfig);
    if(window->vis == NULL){
        fputs("Could not create a glX visual\n", stderr);
        XCloseDisplay(window->dpy);
        window->dpy = NULL;
        return;
    }
    if(window->scr_id != window->vis->screen){
        fputs("Screen does not match a given visual\n", stderr);
        XCloseDisplay(window->dpy);
        window->dpy = NULL;
        return;
    }

    /* Open the window. */
    {
        XSetWindowAttributes winAttr;
        Window root = RootWindow(window->dpy, window->scr_id);
        winAttr.border_pixel = BlackPixel(window->dpy, window->scr_id);
        winAttr.background_pixel = WhitePixel(window->dpy, window->scr_id);
        winAttr.override_redirect = True;
        winAttr.colormap = window->cmap =
            XCreateColormap(window->dpy, root, window->vis->visual, AllocNone);
        winAttr.event_mask = ExposureMask;
        
        window->wnd = XCreateWindow(window->dpy, root, 0, 0, w, h, 0,
            window->vis->depth, InputOutput, window->vis->visual,
            CWBackPixel | CWColormap | CWBorderPixel | CWEventMask, &winAttr);
    }
    
    XStoreName(window->dpy, window->wnd, title);

    XSelectInput(window->dpy, window->wnd, GLOW_X_EVENT_MASK);
    
    XSync(window->dpy, False);
}

void Glow_DestroyWindow(struct Glow_Window *window){
    XSync(window->dpy, False);

    if(window->ctx)
        glXDestroyContext(window->dpy, window->ctx->ctx);

    XFreeColormap(window->dpy, window->cmap);
    XDestroyWindow(window->dpy, window->wnd);
    XSync(window->dpy, False);

    XCloseDisplay(window->dpy);
}

void Glow_SetTitle(struct Glow_Window *window, const char *title){
    XStoreName(window->dpy, window->wnd, title);
}

void Glow_ShowWindow(struct Glow_Window *window){
    XClearWindow(window->dpy, window->wnd);
    XMapRaised(window->dpy, window->wnd);
    {
        XEvent event;
        do{
            XNextEvent(window->dpy, &event);
        } while(event.type != MapNotify);
    }
}

void Glow_HideWindow(struct Glow_Window *window){
    XUnmapWindow(window->dpy, window->wnd);
}

void Glow_GetWindowSize(const struct Glow_Window *window,
    unsigned *out_w, unsigned *out_h){
    out_w[0] = window->w;
    out_h[0] = window->h;
}

void Glow_FlipScreen(struct Glow_Window *window){
    Glow_MakeCurrent(window->ctx);
    glXSwapBuffers(window->dpy, window->wnd);
}

static unsigned glow_get_event(struct Glow_Window *window,
    unsigned block, struct Glow_Event *out){
glow_get_event_start:
    if(block || XPending(window->dpy) > 0){
        XEvent event;
        unsigned char press = 0u;
        XNextEvent(window->dpy, &event);
        switch(event.type){
            case KeyPress:
                press = 1u;
            case KeyRelease:
                {
                    KeySym sym;
                    XComposeStatus compose;
                    XLookupString(&event.xkey, out->value.key,
                        GLOW_MAX_KEY_NAME_SIZE, &sym, &compose);
                }
                out->type = press ?
                    eGlowKeyboardPressed : eGlowKeyboardReleased;
                return 1;
            case UnmapNotify:
            case DestroyNotify:
                out->type = eGlowQuit;
                return 1;
            default:
                if(block) /* TCO doesn't work here for all compilers :( */
                    goto glow_get_event_start;
        }
    }
    return 0;
}

unsigned Glow_GetEvent(struct Glow_Window *window,
    struct Glow_Event *out_event){
    return glow_get_event(window, 0, out_event);
}
void Glow_WaitEvent(struct Glow_Window *window, struct Glow_Event *out_event){
    glow_get_event(window, 1, out_event);
}

unsigned Glow_ContextStructSize(){
    return sizeof(struct Glow_Context);
}

int Glow_CreateContext(struct Glow_Window *window,
    struct Glow_Context *opt_share,
    unsigned major, unsigned minor,
    struct Glow_Context *out){
    
    int context_attribs[] = {
        GLX_CONTEXT_MAJOR_VERSION_ARB, 0,
        GLX_CONTEXT_MINOR_VERSION_ARB, 0,
        None, None
    };
    
    context_attribs[1] = major;
    context_attribs[3] = minor;
    
    out->gl[0] = major;
    out->gl[1] = minor;
    
    out->dpy = window->dpy;
    out->wnd = window->wnd;
    
    typedef GLXContext (*glXCreateContextAttribsARB_t)(Display*, GLXFBConfig, GLXContext, Bool, const int*);
    const glXCreateContextAttribsARB_t glXCreateContextAttribsARB =
        (glXCreateContextAttribsARB_t)glXGetProcAddressARB((const GLubyte*)"glXCreateContextAttribsARB");
    const GLXContext share_ctx = opt_share != NULL ? opt_share->ctx : 0;

    if(glXCreateContextAttribsARB == NULL){
        fputs("Could not use glXCreateContextAttribsARB, expect the wrong version of OpenGL\n", stderr);
        if(major > 2)
            return -1;
        out->ctx = glXCreateNewContext(out->dpy, window->fbconfig, GLX_RGBA_TYPE, share_ctx, True);
    }
    else{
        out->ctx = glXCreateContextAttribsARB(out->dpy, window->fbconfig, share_ctx, True, context_attribs);
    }
    
    if(window->ctx != NULL)
        return -1;
    
    window->ctx = out;
    
    return 0;
}

void Glow_CreateLegacyContext(struct Glow_Window *window,
    struct Glow_Context *out){
    Glow_CreateContext(window, NULL, 2, 1, out);
}

void Glow_MakeCurrent(struct Glow_Context *ctx){
    glXMakeCurrent(ctx->dpy, ctx->wnd, ctx->ctx);
}

struct Glow_Window *Glow_CreateLegacyWindow(unsigned w, unsigned h,
    const char *title){

    /* Put the window and CTX in one location so that free() will get them both. */
    struct Glow_Window *const window =
        malloc(Glow_WindowStructSize() + Glow_ContextStructSize());
    struct Glow_Context *const ctx = (struct Glow_Context *)(window + 1);
    Glow_CreateWindow(window, w, h, title, 0);
    Glow_CreateContext(window, NULL, 2, 1, ctx);
    Glow_MakeCurrent(ctx);
    return window;
}
