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
:- use_module string.
:- use_module buffer.

:- import_module list.

:- type list_pair == pair.pair(list.list(int), list.list(int)).
:- type list_pair_float == pair.pair(list.list(float), list.list(float)).

:- pred append_producer(pred(list(T), buffer.buffer), pair.pair(list(T), list(T)), buffer.buffer).
:- mode append_producer(pred(in, uo) is det, in, out) is det.
append_producer(FromList, P, Buffer) :-
    FromList(pair.fst(P), B1),
    FromList(pair.snd(P), B2),
    buffer.append(B1, B2, Buffer).

:- pred test_output(pred(buffer.buffer, list(T)), pair.pair(list(T), list(T)), buffer.buffer).
:- mode test_output(pred(in, uo) is det, in, in) is semidet.
test_output(ToList, P, Buffer) :-
    ToList(Buffer, L3),
    list.append(pair.fst(P), pair.snd(P), L3).

:- func nine_to_one = list(int).
nine_to_one = [9|[8|[7|[6|[5|[4|[3|[2|[1|[]]]]]]]]]].

:- func nine_to_one_float = list(float).
nine_to_one_float = [9.0|[8.0|[7.0|[6.0|[5.0|[4.0|[3.0|[2.0|[1.0|[]]]]]]]]]].

:- func one_to_nine = list(int).
one_to_nine = [1|[2|[3|[4|[5|[6|[7|[8|[9|[]]]]]]]]]].

:- func one_to_nine_float = list(float).
one_to_nine_float = [1.0|[2.0|[3.0|[4.0|[5.0|[6.0|[7.0|[8.0|[9.0|[]]]]]]]]]].

:- func empty = list_pair.
empty = pair.pair([], []).

:- func empty_float = list_pair_float.
empty_float = pair.pair([], []).

:- func half_empty0 = list_pair.
half_empty0 = pair.pair([], [1|[2|[]]]).

:- func half_empty0_float = list_pair_float.
half_empty0_float = pair.pair([], [1.0|[2.0|[]]]).

:- func half_empty1 = list_pair.
half_empty1 = pair.pair([1|[2|[]]], []).

:- func half_empty1_float = list_pair_float.
half_empty1_float = pair.pair([1.0|[2.0|[]]], []).

:- func append_test1 = list_pair.
append_test1 = pair.pair([1|[]], nine_to_one).

:- func append_test1_float = list_pair_float.
append_test1_float = pair.pair([1.0|[]], nine_to_one_float).

:- pred append_test(string, io.io, io.io,
    pred(list(int), buffer.buffer),
    pred(buffer.buffer, list(int)),
    int, int, int, int).
:- mode append_test(in, di, uo,
    pred(in, uo) is det,
    pred(in, uo) is det,
    di, uo, di, uo) is det.

:- pred append_test_float(string, io.io, io.io,
    pred(list(float), buffer.buffer),
    pred(buffer.buffer, list(float)),
    int, int, int, int).
:- mode append_test_float(in, di, uo,
    pred(in, uo) is det,
    pred(in, uo) is det,
    di, uo, di, uo) is det.

:- pred reverse_test(string, io.io, io.io,
    pred(list(int), buffer.buffer),
    pred(buffer.buffer, list(int)),
    int, int, int, int).
:- mode reverse_test(in, di, uo,
    pred(in, uo) is det,
    pred(in, uo) is det,
    di, uo, di, uo) is det.

:- pred reverse_test_float(string, io.io, io.io,
    pred(list(float), buffer.buffer),
    pred(buffer.buffer, list(float)),
    int, int, int, int).
:- mode reverse_test_float(in, di, uo,
    pred(in, uo) is det,
    pred(in, uo) is det,
    di, uo, di, uo) is det.

:- pred lists_equal(list(T)::in, list(T)::in) is semidet.
lists_equal(I, I).

:- pred buffer_equals_list(list(T), pred(buffer.buffer, list(T)), buffer.buffer).
:- mode buffer_equals_list(in, pred(in, uo) is det, in) is semidet.
% :- mode buffer_equals_list(in, pred(in, uo) is det, di) is semidet.
buffer_equals_list(List, ToList, Buffer) :- ToList(Buffer, List).

test(!IO) :-
    % 8 bit
    append_test("8 bit", !IO, buffer.from_list_8, buffer.to_list_8, 0, OK8, 0, Sum8),
    append_test("16 bit", !IO, buffer.from_list_16, buffer.to_list_16, OK8, OK16, Sum8, Sum16),
    append_test("32 bit", !IO, buffer.from_list_32, buffer.to_list_32, OK16, OK32, Sum16, Sum32),
    append_test_float("float", !IO, buffer.from_list_float, buffer.to_list_float, OK32, OKfloat, Sum32, Sumfloat),
    append_test_float("double", !IO, buffer.from_list_double, buffer.to_list_double, OKfloat, OKdouble, Sumfloat, Sumdouble),
    sum_suite(!IO, "Buffer Append", OKdouble, Sumdouble),
    reverse_test("8 bit", !IO, buffer.from_list_8, buffer.to_list_8_reverse, 0, OK8r, 0, Sum8r),
    reverse_test("16 bit", !IO, buffer.from_list_16, buffer.to_list_16_reverse, OK8r, OK16r, Sum8r, Sum16r),
    reverse_test("32 bit", !IO, buffer.from_list_32, buffer.to_list_32_reverse, OK16r, OK32r, Sum16r, Sum32r),
    sum_suite(!IO, "Buffer Reverse", OK32r, Sum32r).

:- func str_append(string, string) = string.
str_append(A, B) = string.append(A, B).

append_test(Name, !IO, FromList, ToList, !N, !Sum) :-
    Producer = append_producer(FromList),
    Namer = str_append(string.append(Name, " ")),
    run_test(!IO, Namer("Empty Append"),
        empty, test_output(ToList, empty), Producer, !N, !Sum),
    run_test(!IO, Namer("First Half Empty"),
        half_empty0, test_output(ToList, half_empty0), Producer, !N, !Sum),
    run_test(!IO, Namer("Second Half Empty"),
        half_empty1, test_output(ToList, half_empty1), Producer, !N, !Sum),
    run_test(!IO, Namer("Full Append Test"),
        append_test1, test_output(ToList, append_test1), Producer, !N, !Sum).

append_test_float(Name, !IO, FromList, ToList, !N, !Sum) :-
    Producer = append_producer(FromList),
    Namer = str_append(string.append(Name, " ")),
    run_test(!IO, Namer("Empty Append"),
        empty_float, test_output(ToList, empty_float), Producer, !N, !Sum),
    run_test(!IO, Namer("First Half Empty"),
        half_empty0_float, test_output(ToList, half_empty0_float), Producer, !N, !Sum),
    run_test(!IO, Namer("Second Half Empty"),
        half_empty1_float, test_output(ToList, half_empty1_float), Producer, !N, !Sum),
    run_test(!IO, Namer("Full Append Test"),
        append_test1_float, test_output(ToList, append_test1_float), Producer, !N, !Sum).

reverse_test(Name, !IO, FromList, ToListReverse, !N, !Sum) :-
    Namer = str_append(string.append(Name, " ")),
    run_test(!IO, Namer("Reverse Test 1"),
        one_to_nine, buffer_equals_list(nine_to_one, ToListReverse), FromList, !N, !Sum),
    run_test(!IO, Namer("Reverse Test 2"),
        nine_to_one, buffer_equals_list(one_to_nine, ToListReverse), FromList, !N, !Sum),
    run_test(!IO, Namer("Reverse Empty Test"),
        [], buffer_equals_list([], ToListReverse), FromList, !N, !Sum).

reverse_test_float(Name, !IO, FromList, ToListReverse, !N, !Sum) :-
    Namer = str_append(string.append(Name, " ")),
    run_test(!IO, Namer("Reverse Test 1"),
        one_to_nine_float, buffer_equals_list(nine_to_one_float, ToListReverse), FromList, !N, !Sum),
    run_test(!IO, Namer("Reverse Test 2"),
        nine_to_one_float, buffer_equals_list(one_to_nine_float, ToListReverse), FromList, !N, !Sum),
    run_test(!IO, Namer("Reverse Empty Test"),
        [], buffer_equals_list([], ToListReverse), FromList, !N, !Sum).
