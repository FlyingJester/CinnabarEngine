:- module mchrono.
:- interface.

:- import_module io.

:- type microseconds ---> microseconds(int).

:- func ms_to_int(microseconds) = (int).
:- func int_to_ms(int) = (microseconds).

:- func seconds_to_ms(int) = microseconds.

:- pred micro_sleep(io::di, io::uo, microseconds::in) is det.
:- pred micro_ticks(io::di, io::uo, microseconds::uo) is det.

:- pred subtract(io::di, io::uo, microseconds::in, microseconds::uo) is det.

:- implementation.

:- import_module int.

:- pragma foreign_decl("C", "#include ""chrono/chrono.h"" ").

ms_to_int(microseconds(I)) = I.
:- pragma foreign_export("C", ms_to_int(in)=(out), "ms_to_int").

int_to_ms(I) = microseconds(I).
:- pragma foreign_export("C", int_to_ms(in)=(out), "int_to_ms").

seconds_to_ms(Seconds) = microseconds(Seconds * 1000000).

:- pragma foreign_proc("C",
    micro_sleep(IOin::di, IOout::uo, MS::in),
    [promise_pure, will_not_throw_exception],
    " Lightning_MicrosecondsSleep(ms_to_int(MS)); IOout = IOin; ").

:- pragma foreign_proc("C",
    micro_ticks(IOin::di, IOout::uo, MS::uo),
    [promise_pure, will_not_throw_exception],
    " MS = int_to_ms(Lightning_GetMicrosecondsTime()); IOout = IOin; ").

subtract(!IO, microseconds(Min), microseconds(Mout)) :-
    micro_ticks(!IO, microseconds(Mmid)),
    ( Mmid > Min ->
        Mout = 0
    ;
        Mout = Min - Mmid
    ).
