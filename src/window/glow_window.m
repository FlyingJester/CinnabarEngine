:- module glow_window.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
:- use_module maybe.
:- use_module window.

%------------------------------------------------------------------------------%

:- type window.
:- type context.

%------------------------------------------------------------------------------%

% Creates a base window.
% create_window(W, H, Title, Version, Out, !IO)
:- pred create_window(int, int, string, window.gl_version, window, io.io, io.io).
:- mode create_window(in, in, in, in, uo, di, uo) is det.
:- mode create_window(in, in, in, di, uo, di, uo) is det.
:- mode create_window(di, di, in, in, uo, di, uo) is det.
:- mode create_window(di, di, in, di, uo, di, uo) is det.

% create_window(W, H, Title, GLMajor, GLMinor, Out, !IO)
:- pred create_window(int, int, string, int, int, window, io.io, io.io).
:- mode create_window(in, in, in, in, in, uo, di, uo) is det.

:- func context(window) = context.

:- pred hide(window, io.io, io.io).
:- mode hide(in, di, uo) is det.

:- pred show(window, io.io, io.io).
:- mode show(in, di, uo) is det.

:- pred title(window, string, io.io, io.io).
:- mode title(in, in, di, uo) is det.

:- pred size(window, int, int, io.io, io.io).
:- mode size(in, uo, uo, di, uo) is det.

:- pred wait(window, window.window_event, io.io, io.io).
:- mode wait(in, uo, di, uo) is det.

:- pred check(window, maybe.maybe(window.window_event), io.io, io.io).
:- mode check(in, uo, di, uo) is det.

:- pred make_current(context::in, io.io::di, io.io::uo) is det.

%------------------------------------------------------------------------------%

:- instance window.window(window).
:- instance window.gl_context(context).

%==============================================================================%
:- implementation.
%==============================================================================%

:- pragma foreign_import_module("C", window).
:- pragma foreign_decl("C", "#include ""glow/glow.h"" ").

:- pragma foreign_decl("C", "

#define MGLOW_GET_WINDOW(THAT) ((struct Glow_Window*)THAT)
#define MGLOW_GET_CONTEXT(THAT)\
    ((struct Glow_Context*)(((unsigned char*)THAT)+Glow_WindowStructSize()))

").

:- pragma foreign_type("C", window, "void*").
:- pragma foreign_type("C", context, "void*").

:- pragma foreign_decl("C", "void MGlow_FinalizeWindow(void *data, void*);").
:- pragma foreign_decl("C", "MR_Word MGlow_ConvertEvent(const struct Glow_Event *event);").

:- pragma foreign_code("C",
    "
    void MGlow_FinalizeWindow(void *data, void *_){
        struct Glow_Window *const window = MGLOW_GET_WINDOW(data);
        Glow_DestroyWindow(window);
    }
    ").

:- pragma foreign_code("C",
    "
    MR_Word MGlow_ConvertEvent(const struct Glow_Event *event){
        int p = 0;
        switch(event->type){
            case eGlowKeyboardPressed:
                p = 1; /* FALLTHROUGH */
            case eGlowKeyboardReleased:
                {
                    char *const k = MR_GC_malloc_atomic(GLOW_MAX_KEY_NAME_SIZE);
                    for(unsigned i = 0; i < GLOW_MAX_KEY_NAME_SIZE / sizeof(MR_Word); i++)
                        ((MR_Word*)k)[i] = ((MR_Word*)event->value.key)[i];
                    return MW_CreateKeyEvent(p ? MW_key_down : MW_key_up, k);
                }
            case eGlowMousePressed:
                p = 1; /* FALLTHROUGH */
            case eGlowMouseReleased:
                return MW_CreateMouseEvent(p ? MW_mouse_down : MW_mouse_up,
                    event->value.mouse.xy[0], event->value.mouse.xy[1]);
            case eGlowResized:
            case eGlowQuit:
                return MW_CreateQuitEvent();
        }
        return MW_CreateQuitEvent();
    }
    ").

create_window(W, H, Title, window.gl_version(Maj, Min), Window, !IO) :-
    create_window(W, H, Title, Maj, Min, Window, !IO).

:- pragma foreign_proc("C",
    create_window(W::in, H::in, Title::in, Maj::in, Min::in, Window::uo, IOin::di, IOout::uo),
    [promise_pure, will_not_throw_exception, thread_safe, tabled_for_io],
    "
        const unsigned size = Glow_WindowStructSize() + Glow_ContextStructSize();
        Window = MR_GC_malloc_atomic(size);
        Glow_CreateWindow(MGLOW_GET_WINDOW(Window), W, H, Title, 0);
        Glow_CreateContext(MGLOW_GET_WINDOW(Window), NULL, Maj, Min,
            MGLOW_GET_CONTEXT(Window));
        MR_GC_register_finalizer(Window, MGlow_FinalizeWindow, NULL);
        IOout = IOin;
    ").
    
:- pragma foreign_proc("C",
    context(Window::in) = (Context::out),
    [promise_pure, will_not_throw_exception, thread_safe, will_not_call_mercury],
    "
        Context = MGLOW_GET_CONTEXT(Window);
    ").

:- pragma foreign_proc("C",
    wait(Window::in, Event::uo, IOin::di, IOout::uo),
    [promise_pure, will_not_throw_exception, thread_safe, tabled_for_io],
    "
        struct Glow_Event event;
        Glow_WaitEvent(MGLOW_GET_WINDOW(Window), &event);
        Event = MGlow_ConvertEvent(&event);
        IOout = IOin;
    ").

:- pragma foreign_proc("C",
    check(Window::in, MaybeEvent::uo, IOin::di, IOout::uo),
    [promise_pure, will_not_throw_exception, thread_safe, tabled_for_io],
    "
        struct Glow_Event event;
        if(Glow_GetEvent(MGLOW_GET_WINDOW(Window), &event)){
            MaybeEvent = MW_Yes(MGlow_ConvertEvent(&event));
        }
        else{
            MaybeEvent = MW_No();
        }
        IOout = IOin;
    ").

:- pragma foreign_proc("C",
    hide(Window::in, IOin::di, IOout::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "
        Glow_HideWindow(MGLOW_GET_WINDOW(Window));
        IOout = IOin;
    ").

:- pragma foreign_proc("C",
    show(Window::in, IOin::di, IOout::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "
        Glow_ShowWindow(MGLOW_GET_WINDOW(Window));
        IOout = IOin;
    ").

:- pragma foreign_proc("C",
    title(Window::in, Title::in, IOin::di, IOout::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "
        Glow_SetTitle(MGLOW_GET_WINDOW(Window), Title);
        IOout = IOin;
    ").

:- pragma foreign_proc("C",
    size(Window::in, W::uo, H::uo, IOin::di, IOout::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "
        unsigned lw, lh;
        Glow_GetWindowSize(MGLOW_GET_WINDOW(Window), &lw, &lh);
        W = lw;
        H = lh;
        IOout = IOin;
    ").

:- pragma foreign_proc("C", make_current(Ctx::in, IOin::di, IOout::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "
        Glow_MakeCurrent(MGLOW_GET_CONTEXT(Ctx));
        IOout = IOin;
    ").

:- instance window.window(window) where [
    pred(window.show/3) is glow_window.show,
    pred(window.hide/3) is glow_window.hide,
    pred(window.title/4) is glow_window.title,
    pred(window.size/5) is glow_window.size,
    pred(window.wait/4) is glow_window.wait,
    pred(window.check/4) is glow_window.check,
    pred(window.run/5) is window.run_basic
].

:- instance window.gl_context(context) where [
    pred(window.make_current/3) is glow_window.make_current
].
