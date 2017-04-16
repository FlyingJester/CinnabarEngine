:- module null_window.
%==============================================================================%
% Null window, does nothing. Mainly used for testing purposes, mostly finding if
% a crash is in Glow/FLTK or Mercury.
:- interface.
%==============================================================================%

:- use_module io.
:- use_module maybe.
:- use_module window.

%------------------------------------------------------------------------------%

:- type window ---> window.
:- type context ---> context.

%------------------------------------------------------------------------------%

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

hide(window, !IO).
show(window, !IO).

title(window, _, !IO).

size(window, 1, 1, !IO).

wait(window, window.resize(1, 1), !IO).

check(window, maybe.no, !IO).

make_current(context, !IO).

:- instance window.window(window) where [
    pred(window.show/3) is null_window.show,
    pred(window.hide/3) is null_window.hide,
    pred(window.title/4) is null_window.title,
    pred(window.size/5) is null_window.size,
    pred(window.wait/4) is null_window.wait,
    pred(window.check/4) is null_window.check,
    pred(window.run/5) is window.run_basic
].

:- instance window.gl_context(context) where [
    pred(window.make_current/3) is null_window.make_current
].
