:- module window.
%==============================================================================%
% Defines a typeclass for a windowing system that allows managing windows,
% initializing OpenGL, and handling events.
% Since some windowing systems place requirements on which threads can touch
% the event queue, this is where the threading is located.
:- interface.
%==============================================================================%

:- use_module io.
:- use_module maybe.
:- import_module list.

%------------------------------------------------------------------------------%

:- type gl_version ---> gl_version(int, int).

:- type key_press ---> key_down ; key_up.
:- type mouse_click ---> mouse_down ; mouse_up.

:- type window_event --->
    quit ;
    key(key_press, string) ;
    mouse(mouse_click, int, int) ;
    resize(int, int). % Resize may or may not occur.

%------------------------------------------------------------------------------%

:- typeclass window(Window) where [
    
    pred wait(Window, window_event, io.io, io.io),
    mode wait(in, uo, di, uo) is det,
    
    pred check(Window, maybe.maybe(window_event), io.io, io.io),
    mode check(in, uo, di, uo) is det,

    pred hide(Window, io.io, io.io),
    mode hide(in, di, uo) is det,

    pred show(Window, io.io, io.io),
    mode show(in, di, uo) is det,

    pred title(Window, string, io.io, io.io),
    mode title(in, in, di, uo) is det,

    pred size(Window, int, int, io.io, io.io),
    mode size(in, uo, uo, di, uo) is det,

    % run(Render, Frame, !Window, !IO)
    pred run(pred(io.io, io.io),
        pred(list.list(string), list.list(window_event), io.io, io.io),
        Window,
        io.io, io.io),
    mode run(pred(di, uo) is det,
        pred(in, in, di, uo) is det,
        in,
        di, uo) is det

].

%------------------------------------------------------------------------------%

:- typeclass gl_context(Ctx) where [
    pred make_current(Ctx::in, io.io::di, io.io::uo) is det
].

%------------------------------------------------------------------------------%

:- pred run_basic(pred(io.io, io.io),
    pred(list.list(string), list.list(window_event), io.io, io.io),
    Window,
    io.io, io.io) <= window(Window).
:- mode run_basic(pred(di, uo) is det,
    pred(in, in, di, uo) is det,
    in,
    di, uo) is det.

% run_threaded(Render, Frame, MakeCurrent, RenderCtx, FrameCtx, !Window, !IO)
:- pred run_threaded(pred(io.io, io.io),
    pred(list.list(string), list.list(window_event), io.io, io.io),
    pred(Ctx, io.io, io.io),
    Ctx, Ctx,
    Window,
    io.io, io.io) <= (window(Window), gl_context(Ctx)).
:- mode run_threaded(pred(di, uo) is det,
    pred(in, in, di, uo) is det,
    pred(in, di, uo) is det,
    in, in,
    in,
    di, uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module string.
:- use_module unit.
:- use_module bool.
:- use_module thread.
:- use_module thread.mvar.
:- use_module thread.channel.

%------------------------------------------------------------------------------%

:- pragma foreign_decl("C", "enum MW_KeyPress { MW_key_down, MW_key_up }; ").
:- pragma foreign_decl("C", "enum MW_MouseClick { MW_mouse_down, MW_mouse_up }; ").

:- pragma foreign_enum("C", key_press/0,
    [key_down - "MW_key_down", key_up - "MW_key_up"]).

:- pragma foreign_enum("C", mouse_click/0,
    [mouse_down - "MW_key_up", mouse_up - "MW_mouse_up"]).

%------------------------------------------------------------------------------%

:- func create_quit_event = (window_event::uo) is det.
create_quit_event = quit.
:- pragma foreign_export("C", create_quit_event = uo, "MW_CreateQuitEvent").

:- func create_key_event(key_press::di, string::di) = (window_event::uo) is det.
create_key_event(P, S) = key(P, S).
:- pragma foreign_export("C", create_key_event(di, di) = uo, "MW_CreateKeyEvent").

:- func create_mouse_event(mouse_click, int, int) = window_event.
create_mouse_event(C, X, Y) = mouse(C, X, Y).
:- pragma foreign_export("C",
    create_mouse_event(in, in, in) = out, "MW_CreateMouseEvent").

:- func create_resize_event(int, int) = window_event.
create_resize_event(W, H) = resize(W, H).
:- pragma foreign_export("C", create_resize_event(in, in) = out, "MW_CreateResizeEvent").

:- func create_yes_event(window_event) = maybe.maybe(window_event).
create_yes_event(E) = maybe.yes(E).
:- pragma foreign_export("C", create_yes_event(in) = out, "MW_Yes").

:- func create_no_event = (maybe.maybe(window_event)::uo) is det.
create_no_event = maybe.no.
:- pragma foreign_export("C", create_no_event = uo, "MW_No").

:- pragma foreign_export("C",
    run_threaded(pred(di, uo) is det,
        pred(in, in, di, uo) is det,
        pred(in, di, uo) is det,
        in, in,
        in,
        di, uo),
    "MW_RunThreaded").

:- pragma foreign_export("C", 
    run_basic(pred(di, uo) is det,
        pred(in, in, di, uo) is det,
        in,
        in,
        di, uo),
    "MW_RunBasic").

%------------------------------------------------------------------------------%

:- pred get_events(Window,
    list.list(string), list.list(string),
    list.list(window_event), list.list(window_event),
    bool.bool, io.io, io.io) <= window(Window).
:- mode get_events(in, in, out, in, out, out, di, uo) is det.

:- pred remove(string::in, list(string)::in, list(string)::out) is det.
remove(Name, ListIn, ListOut) :- list.delete_all(ListIn, Name, ListOut).

:- pred handle_keys(key_press::in, string::in, list(string)::in, list(string)::out) is det.
handle_keys(key_up, Name, !Keys) :-
    remove(Name, !Keys).
handle_keys(key_down, Name, !Keys) :-
    list.merge_and_remove_dups([Name|[]], !Keys).

get_events(Window, !Keys, In, Out, Q, !IO) :-
    check(Window, MaybeEvent, !IO),
    (
        MaybeEvent = maybe.yes(Event),
        ( Event = quit ->
            Q = bool.yes,
            Out = []
        ;
            ( Event = key(Press, Name) -> handle_keys(Press, Name, !Keys) ; true ),
            list.append(In, [Event|[]], Events),
            get_events(Window, !Keys, Events, Out, Q, !IO)
        )
    ;
        MaybeEvent = maybe.no,
        Out = In,
        Q = bool.no
    ).

:- pred run_basic(pred(io.io, io.io),
    pred(list.list(string), list.list(window_event), io.io, io.io),
    list.list(string),
    Window,
    io.io, io.io) <= window(Window).
:- mode run_basic(pred(di, uo) is det,
    pred(in, in, di, uo) is det,
    in,
    in,
    di, uo) is det.

run_basic(Render, Frame, Keys, Window, !IO) :-
    Render(!IO),
    get_events(Window, Keys, NewKeys, [], Events, Die, !IO),
    (
        Die = bool.yes
    ;
        Die = bool.no,
        Frame(NewKeys, Events, !IO),
        run_basic(Render, Frame, NewKeys, Window, !IO)
    ).

run_basic(Render, Frame, Window, !IO) :-
    run_basic(Render, Frame, [], Window, !IO).

:- pred render_runner(thread.mvar.mvar(unit.unit),
    pred(io.io, io.io),
    pred(io.io, io.io),
    thread.thread,
    io.io, io.io).
:- mode render_runner(in, pred(di, uo) is det, pred(di, uo) is det, in, di, uo) is cc_multi.
render_runner(DieMVar, Render, MakeCurrent, Thr, !IO) :-
    thread.mvar.try_take(DieMVar, MaybeDie, !IO),
    (
        MaybeDie = maybe.yes(unit.unit)
    ;
        MaybeDie = maybe.no,
        MakeCurrent(!IO),
        Render(!IO),
        render_runner(DieMVar, Render, MakeCurrent, Thr, !IO)
    ).

:- pred collect_events_from_channel(
    thread.channel.channel(window_event)::in,
    list(window_event)::in,
    list(window_event)::out,
    io.io::di, io.io::uo) is det.
collect_events_from_channel(Channel, In, Out, !IO) :-
    thread.channel.try_take(Channel, MaybeEvent, !IO),
    (
        MaybeEvent = maybe.yes(Event),
        list.append(In, [Event|[]], New),
        collect_events_from_channel(Channel, New, Out, !IO)
    ;
        MaybeEvent = maybe.no,
        Out = In
    ).

:- pred frame_runner(thread.mvar.mvar(unit.unit),
    pred(list.list(string), list.list(window_event), io.io, io.io),
    pred(io.io, io.io),
    thread.mvar.mvar(list(string)),
    thread.channel.channel(window_event),
    io.io, io.io).
:- mode frame_runner(in,
    pred(in, in, di, uo) is det,
    pred(di, uo) is det,
    in, in, di, uo) is cc_multi.
frame_runner(DieMVar, Frame, MakeCurrent, KeyMVar, EventChannel, !IO) :-
    thread.mvar.try_take(DieMVar, MaybeDie, !IO),
    (
        MaybeDie = maybe.yes(unit.unit)
    ; % Duplicate disjunction branch to silence cc_multi warnings.
        MaybeDie = maybe.yes(unit.unit)
    ;
        MaybeDie = maybe.no,
        MakeCurrent(!IO),
        thread.mvar.read(KeyMVar, Keys, !IO),
        collect_events_from_channel(EventChannel, [], Events, !IO),
        Frame(Keys, Events, !IO),
        frame_runner(DieMVar, Frame, MakeCurrent, KeyMVar, EventChannel, !IO)
    ).

:- pred run_threaded_event(
    thread.mvar.mvar(unit.unit)::in,
    thread.mvar.mvar(unit.unit)::in,
    thread.mvar.mvar(list(string))::in,
    thread.channel.channel(window_event)::in,
    Window::in,
    io.io::di, io.io::uo) is det <= window(Window).

run_threaded_event(DieMVar0, DieMVar1, KeysMVar, EventChannel, Window, !IO) :-
    wait(Window, Event, !IO),
    ( Event = quit ->
        thread.mvar.put(DieMVar0, unit.unit, !IO),
        thread.mvar.put(DieMVar1, unit.unit, !IO)
    ;
        ( Event = key(Press, Name) ->
            handle_keys(Press, Name, KeysIn, KeysOut),
            thread.mvar.take(KeysMVar, KeysIn, !IO),
            thread.mvar.put(KeysMVar, KeysOut, !IO)
        ;
            true
        ),
        thread.channel.put(EventChannel, Event, !IO),
        run_threaded_event(DieMVar0, DieMVar1, KeysMVar, EventChannel, Window, !IO)
    ).


run_threaded(Render, Frame, MakeCurrent, RenderCtx, FrameCtx, Window, IOi, IOo) :-
    IO0 = IOi,
    thread.mvar.init(RenderDieMVar, IO0, IO1),
    thread.mvar.init(FrameDieMVar, IO1, IO2),
    thread.mvar.init(KeysMVar, IO2, IO3),
    thread.channel.init(EventChannel, IO3, IO4),
    
    promise_equivalent_solutions [IO5] (
        RenderMakeCurrent = (pred(IOn0::di, IOn1::uo) is det :- MakeCurrent(RenderCtx, IOn0, IOn1)),
        RenderRunner = render_runner(RenderDieMVar, Render, RenderMakeCurrent),
        thread.spawn_native(RenderRunner, _, IO4, IO5)
    ),
    
    promise_equivalent_solutions [IO6] (
        FrameMakeCurrent = (pred(IOn0::di, IOn1::uo) is det :- MakeCurrent(FrameCtx, IOn0, IOn1)),
        FrameRunner = frame_runner(FrameDieMVar, Frame, FrameMakeCurrent, KeysMVar, EventChannel),
        thread.spawn(FrameRunner, IO5, IO6)
    ),
    
    thread.mvar.put(KeysMVar, [], IO6, IO7),
    run_threaded_event(RenderDieMVar, FrameDieMVar, KeysMVar, EventChannel, Window, IO7, IOo).
    
