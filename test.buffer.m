:- module test.buffer.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
%------------------------------------------------------------------------------%

:- pred test(io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module pair.
:- use_module buffer.

:- import_module list.

:- type list_pair == pair.pair(list.list(int), list.list(int)).

% run_test(!IO, TestName, Input, OutputIsValid, Producer, OK_In, OK_Out, Sum_In, Sum_Out)
%:- pred run_test(io.io, io.io, string, T, pred(O), pred(T, O), int, int, int, int).
%:- mode run_test(di, uo, in, in, pred(in) is semidet, pred(in, out) is semidet, di, uo, di, uo) is det.

:- pred append_producer(list_pair, buffer.buffer).
:- mode append_producer(in, out) is det.
append_producer(P, Buffer) :-
    buffer.from_list_8(pair.fst(P), B1),
    buffer.from_list_8(pair.snd(P), B2),
    buffer.append(B1, B2, Buffer).

:- pred test_output(list_pair, buffer.buffer).
:- mode test_output(in, in) is semidet.
test_output(pair.pair(L1, L2), Buffer) :-
    buffer.to_list_8(Buffer, L3),
    list.append(L1, L2, L3).

:- func empty = list_pair.
empty = pair.pair([], []).

:- func half_empty0 = list_pair.
half_empty0 = pair.pair([], [1|[2|[]]]).

:- func half_empty1 = list_pair.
half_empty1 = pair.pair([1|[2|[]]], []).

:- func append_test1 = list_pair.
append_test1 = pair.pair([1|[]], [9|[8|[7|[6|[5|[4|[3|[2|[1|[0|[]]]]]]]]]]]).

:- pred test(io.io::di, io.io::uo, int::di, int::uo, int::di, int::uo) is det.
test(!IO) :- test(!IO, 0, OK, 0, Sum), sum_suite(!IO, "Buffer", OK, Sum).
test(!IO, !N, !Sum) :-
    run_test(!IO, "Empty Append", empty, test_output(empty), append_producer, !N, !Sum),
    run_test(!IO, "First Half Empty", half_empty0, test_output(half_empty0), append_producer, !N, !Sum),
    run_test(!IO, "Second Half Empty", half_empty1, test_output(half_empty1), append_producer, !N, !Sum),
    run_test(!IO, "Full Append Test", append_test1, test_output(append_test1), append_producer, !N, !Sum).
