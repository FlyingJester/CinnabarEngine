:- module glow_window.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
:- use_module maybe.
:- use_module window.

%------------------------------------------------------------------------------%

:- type window.

%------------------------------------------------------------------------------%

:- pred create_window(io.io::di, io.io::uo,
    int::in, int::in, window.gl_version::in, string::in,
    window::uo) is det.

:- pred create_window(io.io::di, io.io::uo,
    int::in, int::in, int::in, int::in, string::in, window::uo) is det.

:- pred width(window::di, window::uo, int::uo) is det.
:- pred height(window::di, window::uo, int::uo) is det.
:- pred size(window::di, window::uo, int::uo, int::uo) is det.

:- pred destroy_window(io.io::di, io.io::uo, window::di) is det.

:- pred make_window_current(io.io::di, io.io::uo, window::di, window::uo) is det.

:- pred flip_screen(window::di, window::uo) is det.

:- pred check(maybe.maybe(window.window_event)::uo, window::di, window::uo) is det.
:- pred wait(window.window_event::uo, window::di, window::uo) is det.
:- pred get_mouse_location(int::uo, int::uo, window::di, window::uo) is det.

:- pred center_mouse(window::di, window::uo) is det.

:- pred gl_version(int::uo, int::uo, window::di, window::uo) is det.

%------------------------------------------------------------------------------%

:- instance window.window(window).

%==============================================================================%
:- implementation.
%==============================================================================%

:- pragma foreign_import_module("C", window).
:- pragma foreign_decl("C", "#include ""glow/glow.h"" ").
:- pragma foreign_type("C", window, "struct Glow_Window *").

:- pragma foreign_decl("C", "void MGlow_FinalizeWindow(void *window, void*);").
:- pragma foreign_decl("C", "MR_Word MGlow_ConvertEvent(const struct Glow_Event *event);").

:- pragma foreign_code("C",
    "
    void MGlow_FinalizeWindow(void *window, void *_){
        Glow_DestroyWindow(window);
        (void)_;
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
            case eGlowQuit:
                return MW_CreateQuitEvent();
        }
    }
    ").

create_window(!IO, W, H, window.gl_version(Maj, Min), Title, Window) :-
    create_window(!IO, W, H, Maj, Min, Title, Window).

:- pragma foreign_proc("C",
    create_window(IOin::di, IOout::uo,
        W::in, H::in,
        Maj::in, Min::in,
        Title::in, Window::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, thread_safe],
    "
        Window = MR_GC_malloc_atomic(Glow_WindowStructSize());
        Glow_CreateWindow(Window, W, H, Title, Maj, Min);
        Glow_ShowWindow(Window);
        MR_GC_register_finalizer(Window, MGlowFinalizeWindow, NULL);
        IOout = IOin;
    ").

destroy_window(!IO, _).

:- pragma foreign_proc("C",
    width(Window::di, WindowOut::uo, W::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, thread_safe],
    "
        W = Glow_WindowWidth((WindowOut = Window));
    ").

:- pragma foreign_proc("C",
    height(Window::di, WindowOut::uo, H::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "
        H = Glow_WindowHeight((WindowOut = Window));
    ").

:- pragma foreign_proc("C",
    size(Window::di, WindowOut::uo, W::uo, H::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, 
     thread_safe, does_not_affect_liveness],
    "
        W = Glow_WindowWidth((WindowOut = Window));
        H = Glow_WindowHeight((WindowOut = Window));
    ").

:- pragma foreign_proc("C",
    flip_screen(Window::di, WindowOut::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, 
     thread_safe, does_not_affect_liveness],
    "
        WindowOut = Window;
        Glow_FlipScreen(Window);
    ").

:- pragma foreign_proc("C",
    make_window_current(IO0::di, IO1::uo, Window::di, WindowOut::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, 
     thread_safe, does_not_affect_liveness],
    "
        IO1 = IO0;
        Glow_MakeCurrent((WindowOut = Window));
    ").

:- pragma foreign_proc("C",
    check(EventOut::uo, Window::di, WindowOut::uo),
    [promise_pure, thread_safe, will_not_throw_exception, does_not_affect_liveness],
    "
        struct Glow_Event event;
        if(Glow_GetEvent((WindowOut = Window), 0, &event) == 1)
            EventOut = MW_Yes(MGlow_ConvertEvent(&event));
        else
            EventOut = MW_No();
    ").

:- pragma foreign_proc("C",
    wait(EventOut::uo, Window::di, WindowOut::uo),
    [promise_pure, thread_safe, will_not_throw_exception, does_not_affect_liveness],
    "
        struct Glow_Event event;
        Glow_GetEvent((WindowOut = Window), 1, &event);
        EventOut = MGlow_ConvertEvent(&event));
    ").

:- pragma foreign_proc("C",
    get_mouse_location(X::uo, Y::uo, Win0::di, Win1::uo),
    [will_not_call_mercury, promise_pure, thread_safe, will_not_throw_exception,
     does_not_affect_liveness],
    "
        {
            glow_pixel_coords_t coords;
            Glow_GetMousePosition((Win1 = Win0), coords);
            X = coords[0];
            Y = coords[1];
        }
    ").

:- pragma foreign_proc("C",
    center_mouse(Win0::di, Win1::uo),
    [will_not_call_mercury, promise_pure, thread_safe, will_not_throw_exception,
     does_not_affect_liveness],
    " Glow_CenterMouse((Win1 = Win0));").

:- pragma foreign_proc("C", gl_version(Maj::uo, Min::uo, Win0::di, Win1::uo),
    [will_not_call_mercury, promise_pure, thread_safe, will_not_throw_exception,
     does_not_affect_liveness],
    "
        unsigned M, m;
        Glow_GetWindowGLVersion((Win1 = Win0), &M, &m);
        Maj = M;
        Min = m;
    ").

:- instance window.window(window) where [
    ( window.gl_version(window.gl_version(Maj, Min), !Window) :-
        glow_window.gl_version(Maj, Min, !Window) ),
    pred(window.wait/3) is glow_window.wait,
    pred(window.check/3) is glow_window.check,
    pred(window.run/6) is window.run_basic
].
