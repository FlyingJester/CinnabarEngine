:- module test.
%==============================================================================%
% Test application for Cinnabar components.
%
% Includes a simple unit test framework, since there are no other open source
% test frameworks for Mercury.
:- interface.
%==============================================================================%

:- use_module io.
:- import_module list.
%------------------------------------------------------------------------------%

:- pred main(io.io::di, io.io::uo) is det.

% Test runners for submodules.
% The intention is that Producer will take in Input and produce some output that
% will cause OutputIsValid to succeed or fail, indicate the test worked or not.
%  
% As an example, to test an integer-pair summing function:
%
% > :- pred sum(pair(int, int)::in, int::uo) is det.
% > sum(pair(A, B), A + B).
%
% > :- pred equals(int::in, int::in) is semidet.
% > equals(I, I).
% 
% Then, to run the test:
% > run_test(!IO, "1 + 2", pair(1, 2), equal(3), sum, !OK, !Sum).
% 
% It's true that many simple cases don't need verification functions to test
% validity, but many more complex cases only test certain portions of a result.
%
%
% The point of OK and Sum are to sum up results for sum_suite.
% 
% run_test(!IO, TestName, Input, OutputIsValid, Producer, OK_In, OK_Out, Sum_In, Sum_Out)
:- pred run_test(io.io, io.io, string, T, pred(O), pred(T, O), int, int, int, int).
:- mode run_test(di, uo, in, in, pred(in) is semidet, pred(in, out) is semidet, di, uo, di, uo) is det.
:- mode run_test(di, uo, in, in, pred(in) is semidet, pred(in, out) is det, di, uo, di, uo) is det.
:- mode run_test(di, uo, in, in, pred(di) is semidet, pred(in, uo) is semidet, di, uo, di, uo) is det.
:- mode run_test(di, uo, in, in, pred(di) is semidet, pred(in, uo) is det, di, uo, di, uo) is det.
:- mode run_test(di, uo, in, di, pred(di) is semidet, pred(di, uo) is semidet, di, uo, di, uo) is det.
:- mode run_test(di, uo, in, di, pred(di) is semidet, pred(di, uo) is det, di, uo, di, uo) is det.

% Sums up test results for a suite
:- pred sum_suite(io.io::di, io.io::uo, string::in, int::in, int::in) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module int.

:- include_module test.wavefront.
:- use_module test.wavefront.

:- include_module test.buffer.
:- use_module test.buffer.

%------------------------------------------------------------------------------%
:- pred write_fail(io.io::di, io.io::uo, string::in, string::in, int::uo) is det.
write_fail(!IO, Description, TestName, 0) :-
    io.write_string("ERROR: ", !IO),
    io.write_string(Description, !IO),
    io.write_string(" in tester ", !IO),
    io.write_string(TestName, !IO),
    io.nl(!IO).

%------------------------------------------------------------------------------%
run_test(!IO, TestName, Input, OutputIsValid, Producer, OK_In, OK, SumIn, SumIn + 1) :-
    ( Producer(Input, Output) ->
        ( OutputIsValid(Output) ->
            OK = OK_In + 1,
            io.write_string("SUCCESS: ", !IO),
            io.write_string(TestName, !IO),
            io.nl(!IO)
        ;
            write_fail(!IO, "Test failed", TestName, OK_Out),
            OK = OK_In + OK_Out
        )
    ;
        write_fail(!IO, "Data production failed", TestName, OK_Out),
        OK = OK_In + OK_Out
    ).

%------------------------------------------------------------------------------%
sum_suite(!IO, SuiteName, OK, Total) :-
    io.write_strings([SuiteName | [ ": " | []]], !IO),
    ( OK = Total ->
        io.write_string("Success.\n", !IO)
    ;
        io.write_string("Fail: ", !IO),
        io.write_int(OK, !IO),
        io.write_char('/', !IO),
        io.write_int(Total, !IO),
        io.write_string(" tests passed.\n", !IO)
    ).

%------------------------------------------------------------------------------%
main(!IO) :-
    test.wavefront.test(!IO),
    test.buffer.test(!IO).
