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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define GLOW_X_EVENT_MASK\
    (StructureNotifyMask\
    |KeyPressMask\
    |KeyReleaseMask\
    |ButtonPress\
    |ExposureMask)


struct Glow_Window {
    Display *dpy;
    Screen *scr;
    int scr_id;
    Window wnd;

    Colormap cmap;
    GLXContext ctx;
    XVisualInfo *vis;
    
    unsigned w, h;

    unsigned char keys[100];
};

static unsigned short glow_keystr_number(const char *str);
static unsigned short glow_key_number(char key){
    if(key >= '0' && key <= '9')
        return 16 + key - '0';
    if(key >= 'a' && key <= 'z')
        return 26 + key - 'a';
    if(key >= 'A' && key <= 'Z')
        return 26 + key - 'A';
    if(key == '!')
        return glow_key_number('1');
    if(key == '@')
        return glow_key_number('2');
    if(key == '#')
        return glow_key_number('3');
    if(key == '$')
        return glow_key_number('4');
    if(key == '%')
        return glow_key_number('5');
    if(key == '^')
        return glow_key_number('6');
    if(key == '&')
        return glow_key_number('7');
    if(key == '*')
        return glow_key_number('8');
    if(key == '(')
        return glow_key_number('9');
    if(key == ')')
        return glow_key_number('0');
    if(key == '[' || key == '{')
        return 13;
    if(key == ']' || key == '}')
        return 14;
    if(key == '|' || key == '\\')
        return 15;

    if(key == '`' || key == '~')
        return 90;
    if(key == '-' || key == '_')
        return 91;
    if(key == '=' || key == '+')
        return 92;
    if(key == '<' || key == ',')
        return 93;
    if(key == '>' || key == '.')
        return 94;
    if(key == '/' || key == '?')
        return 95;

    if(key == '\t')
        return glow_keystr_number(GLOW_TAB);

    if(key == ' ')
        return 98;

    return 99;
}

static unsigned short glow_keystr_number(const char *str){
    if(str == NULL)
        return 0;

    if(str[0] == '\0')
        return 0;
    if(str[1] == '\0')
        return glow_key_number(*str);
    {
        unsigned n = 0;
    #define KEY(WHAT)\
        if(str == GLOW_ ## WHAT || strcmp(GLOW_ ## WHAT, str) == 0)\
            return n;\
        n++
        
        KEY(ESCAPE);
        KEY(CONTROL);
        KEY(BACKSPACE);
        KEY(DELETE);
        KEY(UP_ARROW);
        KEY(DOWN_ARROW);
        KEY(LEFT_ARROW);
        KEY(RIGHT_ARROW);
        KEY(ENTER);
        KEY(TAB);
        
    #undef KEY
    }
    return 99;
}

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

void Glow_MakeCurrent(struct Glow_Window *win){
    glXMakeCurrent(win->dpy, win->wnd, win->ctx);
}

struct Glow_Window *Glow_CreateWindow(unsigned aW, unsigned aH,
    const char *title, unsigned gl_maj, unsigned gl_min){

    int context_attribs[] = {
        GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
        GLX_CONTEXT_MINOR_VERSION_ARB, 2,
        None, None
    };
   
    struct Glow_Window *const out =
        (struct Glow_Window *)malloc(sizeof(struct Glow_Window));
    GLXFBConfig fbconfig;

    context_attribs[1] = gl_maj;
    context_attribs[3] = gl_min;

    out->w = aW;
    out->h = aH;

    fputs("Initializing OpenGL ", stdout);
    printf("%i.%i", gl_maj, gl_min);
    puts(" context");
    out->dpy = glow_get_display();
    if(out->dpy == NULL){
        fputs("Could not open an X11 display\n", stderr);
        goto xclose_err;
    }
    out->scr = DefaultScreenOfDisplay(out->dpy);
    out->scr_id = DefaultScreen(out->dpy);
    
    {
        GLint glx_maj = 0, glx_min = 0;
        glXQueryVersion(out->dpy, &glx_maj, &glx_min);
        if(glx_maj <= 1 && glx_min < 2){
            fputs("glX version must be at least 1.2\n", stderr);
            goto xclose_err;
        }
    }
    
    {
        int num = 0, i, best = -1, best_samples = -1;
        GLXFBConfig *const config = glXChooseFBConfig(out->dpy,
            out->scr_id, glow_attribs, &num);
        if(config == NULL || num == 0){
            fputs("Could not get glX framebuffer configuration\n", stderr);
            goto xclose_err;
        }
        
        for(i = 0; i < num; i++){
            XVisualInfo *const info = glXGetVisualFromFBConfig(out->dpy, config[i]);
            if(info != NULL){
                int sample_buffers, samples;
                glXGetFBConfigAttrib(out->dpy, config[i], GLX_SAMPLE_BUFFERS, &sample_buffers);
                glXGetFBConfigAttrib(out->dpy, config[i], GLX_SAMPLES, &samples);
                
                if(best < 0 || (sample_buffers > 0 && samples > best_samples)){
                    best = i;
                    best_samples = samples;
                }
                XFree(info);
            }
        }
        
        fbconfig = config[best];

        XFree(config);
        
        {
            typedef GLXContext (*glXCreateContextAttribsARB_t)(Display*, GLXFBConfig, GLXContext, Bool, const int*);
            const glXCreateContextAttribsARB_t glXCreateContextAttribsARB =
                (glXCreateContextAttribsARB_t)glXGetProcAddressARB((const GLubyte*)"glXCreateContextAttribsARB");
            
            out->vis = glXGetVisualFromFBConfig(out->dpy, fbconfig);
            if(out->vis == NULL){
                fputs("Could not create a glX visual\n", stderr);
                goto xclose_err;
            }
            if(out->scr_id != out->vis->screen){
                fputs("Screen does not match a given visual\n", stderr);
                goto xclose_err;
            }

            /* Open the window. */
            {
                XSetWindowAttributes winAttr;
                Window root = RootWindow(out->dpy, out->scr_id);
                winAttr.border_pixel = BlackPixel(out->dpy, out->scr_id);
                winAttr.background_pixel = WhitePixel(out->dpy, out->scr_id);
                winAttr.override_redirect = True;
                winAttr.colormap = out->cmap =
                    XCreateColormap(out->dpy, root, out->vis->visual, AllocNone);
                winAttr.event_mask = ExposureMask;
                
                out->wnd = XCreateWindow(out->dpy, root, 0, 0, aW, aH, 0, out->vis->depth, InputOutput,
                    out->vis->visual, CWBackPixel | CWColormap | CWBorderPixel | CWEventMask, &winAttr);
            }
            
            /* TODO: Intern a close atom? */

            if(glXCreateContextAttribsARB == NULL){
                fputs("Could not use glXCreateContextAttribsARB, expect the wrong version of OpenGL", stderr);
                out->ctx = glXCreateNewContext(out->dpy, fbconfig, GLX_RGBA_TYPE, 0, True);
            }
            else{
                out->ctx = glXCreateContextAttribsARB(out->dpy, fbconfig, 0, True, context_attribs);
            }
            
            XStoreName(out->dpy, out->wnd, title);

            XSelectInput(out->dpy, out->wnd, GLOW_X_EVENT_MASK);

            XSync(out->dpy, False);

            Glow_MakeCurrent(out);

            {
                GLint n;
                fputs("Using OpenGL ", stdout);
                glGetIntegerv(GL_MAJOR_VERSION, &n);
                printf("%i", n); putchar('.');
                glGetIntegerv(GL_MINOR_VERSION, &n);
                printf("%i", n); putchar('\n');
            }

            return out;
        }
    }

xclose_err:
    free((void*)out);
    XCloseDisplay(out->dpy);
    return NULL;
}

void Glow_FlipScreen(struct Glow_Window *that){
    glXSwapBuffers(that->dpy, that->wnd);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void Glow_DestroyWindow(struct Glow_Window *that){
    XSync(that->dpy, False);

    glXDestroyContext(that->dpy, that->ctx);
    XFreeColormap(that->dpy, that->cmap);
    XDestroyWindow(that->dpy, that->wnd);
    XFree(that->vis);
    XSync(that->dpy, False);

    XCloseDisplay(that->dpy);
}

void Glow_ShowWindow(struct Glow_Window *that){
    XClearWindow(that->dpy, that->wnd);
    XMapRaised(that->dpy, that->wnd);
    {
        XEvent event;
        do{
            XNextEvent(that->dpy, &event);
        } while(event.type != MapNotify);
    }
}

unsigned Glow_GetEvent(struct Glow_Window *that, struct Glow_Event *out){
    if(XPending(that->dpy) > 0){
        XEvent event;
        unsigned char press = 0u;
        puts("EVENT!");
        XNextEvent(that->dpy, &event);
        switch(event.type){
            
            case KeyPress:
                press = 1u;
            case KeyRelease:
                puts("Event!");
                {
                    KeySym sym;
                    XComposeStatus compose;
                    XLookupString(&event.xkey, out->value.key,
                        GLOW_MAX_KEY_NAME_SIZE, &sym, &compose);
                }
                {
                    const unsigned n = glow_keystr_number(out->value.key);

                    if(press)
                        out->type = eGlowKeyboardPressed;
                    else
                        out->type = eGlowKeyboardReleased;

                    that->keys[n] = press;

#ifndef NDEBUG
                    if(press)
                        fputs("[Glow]Pressed key", stdout);
                    else
                        fputs("[Glow]Released key", stdout);

                    puts(out->value.key);
                    printf("[Glow]Using Glow key number %u\n", n);
#endif
                }
                return 1;
            case UnmapNotify:
            case DestroyNotify:
                out->type = eGlowQuit;
                return 1;
            default:
                return 0;
        }
    }
    return 0;
}

unsigned Glow_WindowWidth(const struct Glow_Window *w) { return w->w; }
unsigned Glow_WindowHeight(const struct Glow_Window *w) { return w->h; }

void Glow_GetMousePosition(struct Glow_Window *win,
    glow_pixel_coords_t out_pos){

    Window root_win;
    Window child_win;
    int root_x, root_y,
        win_x, win_y;
    unsigned mask;
    XQueryPointer(win->dpy, win->wnd, &root_win, &child_win,
        &root_x, &root_y, &win_x, &win_y, &mask);

    if(win_x < 0)
        win_x = 0;
    if(win_y < 0)
        win_y = 0;

    out_pos[0] = win_x;
    out_pos[1] = win_y;
}

void Glow_SetMousePosition(struct Glow_Window *win,
    const glow_pixel_coords_t pos){
    XWarpPointer(win->dpy, win->wnd, win->wnd, 0, 0, 0, 0, pos[0], pos[1]);
    XFlush(win->dpy);
}

void Glow_CenterMouse(struct Glow_Window *win){
    XWarpPointer(win->dpy, win->wnd, win->wnd, 0, 0, 0, 0,
        win->w >> 1, win->h >> 1);
    XFlush(win->dpy);
}

unsigned Glow_IsKeyPressed(struct Glow_Window *win, const char *key){
    const unsigned n = glow_keystr_number(key);
    return win->keys[n];
}

unsigned Glow_IsKeyCharPressed(struct Glow_Window *win, char key){
    return win->keys[glow_key_number(key)];
}

/* int main(int argc, char **argv){ return glow_main(argc, argv); } */


