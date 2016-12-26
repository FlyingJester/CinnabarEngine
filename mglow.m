:- module mglow.
%==============================================================================%
:- interface.
%==============================================================================%

:- import_module io.
:- import_module maybe.
%------------------------------------------------------------------------------%

:- type window.

:- type size ---> size(w::int, h::int).
:- type gl_version ---> gl_version(int, int).

% TODO: Needs the other wrappers
:- type glow_event ---> quit.

:- type keypress ---> press ; release.

%------------------------------------------------------------------------------%

:- pred create_window(io::di, io::uo,
    size::in, gl_version::in, string::in, window::uo) is det.

:- pred create_window(io::di, io::uo,
    int::in, int::in, int::in, int::in, string::in, window::uo) is det.

:- pred width(window::di, window::uo, int::uo) is det.
:- pred height(window::di, window::uo, int::uo) is det.
:- pred size(window::di, window::uo, int::uo, int::uo) is det.

:- pred destroy_window(io::di, io::uo, window::di) is det.

:- pred make_window_current(io::di, io::uo, window::di, window::uo) is det.

:- pred flip_screen(window::di, window::uo) is det.

:- pred get_event(maybe(glow_event)::uo, window::di, window::uo) is det.
% AKA Glow_IsKeyPressed
:- pred key_pressed(string::in, keypress::uo, window::di, window::uo) is det.
:- pred get_mouse_location(int::uo, int::uo, window::di, window::uo) is det.

:- pred center_mouse(window::di, window::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- pragma foreign_decl("C", "#include ""glow/glow.h"" ").
:- pragma foreign_type("C", window, "struct Glow_Window *").

:- pragma foreign_decl("C", "void MGlowFinalizeWindow(void *window, void*);").

:- pragma foreign_code("C",
    "
    void MGlowFinalizeWindow(void *window, void *_){
        Glow_DestroyWindow(window);
        (void)_;
    }
    ").

:- pragma foreign_enum("C", keypress/0,
    [
        press - "1",
        release - "0"
    ]).

create_window(!IO, size(W, H), gl_version(Maj, Min), Title, Window) :-
    create_window(!IO, W, H, Maj, Min, Title, Window).

:- pragma foreign_proc("C",
    create_window(IOin::di, IOout::uo,
        W::in, H::in,
        Maj::in, Min::in,
        Title::in, Window::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, thread_safe],
    "
        Window = Glow_CreateWindow(W, H, Title, Maj, Min);
        Glow_ShowWindow(Window);
        
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
    [will_not_call_mercury, promise_pure, will_not_throw_exception, thread_safe],
    "
        H = Glow_WindowHeight((WindowOut = Window));
    ").

:- pragma foreign_proc("C",
    size(Window::di, WindowOut::uo, W::uo, H::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, thread_safe],
    "
        W = Glow_WindowWidth((WindowOut = Window));
        H = Glow_WindowHeight((WindowOut = Window));
    ").

:- pragma foreign_proc("C",
    flip_screen(Window::di, WindowOut::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, thread_safe],
    "
        WindowOut = Window;
        Glow_FlipScreen(Window);
    ").

:- pragma foreign_proc("C",
    make_window_current(IO0::di, IO1::uo, Window::di, WindowOut::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception, thread_safe],
    "
        IO1 = IO0;
        Glow_MakeCurrent((WindowOut = Window));
    ").

:- func create_no_event = (maybe(glow_event)::uo) is det.
create_no_event = no.
:- pragma foreign_export("C", create_no_event=(uo), "create_no_event").

:- func create_quit_event = (maybe(glow_event)::uo) is det.
create_quit_event = yes(quit).
:- pragma foreign_export("C", create_quit_event=(uo), "create_quit_event").

:- pragma foreign_proc("C",
    get_event(EventOut::uo, Window::di, WindowOut::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception],
    "
        struct Glow_Event event;
        if(Glow_GetEvent(WindowOut = Window, &event))
            switch(event.type){
                case eGlowQuit:
                    EventOut = create_quit_event();
                    break;
                default:
                    EventOut = create_no_event();
            }
        else
            EventOut = create_no_event();
    ").

:- pragma foreign_proc("C",
    key_pressed(Str::in, Press::uo, Win0::di, Win1::uo),
    [will_not_call_mercury, promise_pure, thread_safe, will_not_throw_exception],
    "
        Press = 0;
        if(Glow_IsKeyPressed((Win1 = Win0), Str))
            Press = 1;
    ").

:- pragma foreign_proc("C",
    get_mouse_location(X::uo, Y::uo, Win0::di, Win1::uo),
    [will_not_call_mercury, promise_pure, thread_safe, will_not_throw_exception],
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
    [will_not_call_mercury, promise_pure, thread_safe, will_not_throw_exception],
    " Glow_CenterMouse((Win1 = Win0));").