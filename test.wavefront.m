:- module test.wavefront.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
%------------------------------------------------------------------------------%

:- pred test(io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module wavefront.
:- use_module model.
:- import_module list.
%------------------------------------------------------------------------------%

:- type vt == wavefront.vertex.
:- type tx == model.tex.
%------------------------------------------------------------------------------%

:- func test1src = string.
:- func test1src_comment = string.
:- pred test1ver(wavefront.shape::in) is semidet.
:- pred wavefront_tester(string::in, wavefront.shape::out) is det.
wavefront_tester(Src, Out) :- wavefront.load(Src, wavefront.init_shape, Out).

test1src = "
v 0.0 0.0 0.0
v 0.0 1.0 0.0
v 1.0 0.0 0.0
f 0 1 2
".

test1src_comment = "
v 0.0 0.0 0.0 # This is a comment.
v 0.0 1.0 0.0
v 1.0 0.0 0.0
# A comment here, too.
# v 0.0 0.0 0.0
f 0 1 2
".

test1ver(Shape) :-
    Shape = wavefront.shape(
        [model.point(0.0, 0.0, 0.0) |
        [model.point(0.0, 1.0, 0.0) |
        [model.point(1.0, 0.0, 0.0) | []]]],
        [],
        [],
        [wavefront.face([
            wavefront.vertex(0, 0) | [
            wavefront.vertex(1, 0) | [
            wavefront.vertex(2, 0) | []]]])|[]]).

%------------------------------------------------------------------------------%
:- pred test(io.io::di, io.io::uo, int::di, int::uo, int::di, int::uo) is det.
test(!IO) :- test(!IO, 0, OK, 0, Sum), sum_suite(!IO, "Wavefront", OK, Sum).
test(!IO, !N, !Sum) :-
    run_test(!IO, "Triangle", test1src, test1ver, wavefront_tester, !N, !Sum),
    run_test(!IO, "Comment", test1src_comment, test1ver, wavefront_tester, !N, !Sum),

    % Do a full reflective test.
    io.write_string("\nREFLECTIVE TEST: \n", !IO),
    wavefront.load(test1src, wavefront.init_shape, Out),
    io.write_string("Num faces: ", !IO),
    io.write_int(list.length(Out ^ wavefront.faces), !IO),
    io.nl(!IO),
    ( Out ^ wavefront.faces = [wavefront.face([P0|[P1|[P2|[]]]]) | []] ->
        io.write_string("Face 1: ", !IO), io.nl(!IO),
        wavefront.write_vertex(P0, !IO), io.nl(!IO),
        wavefront.write_vertex(P1, !IO), io.nl(!IO),
        wavefront.write_vertex(P2, !IO), io.nl(!IO)
    ;
        true
    ),
    ( Out ^ wavefront.vertices = [V0 | [ V1 | [ V2 | [] ] ] ] ->
        io.write_string("Points: ", !IO), io.nl(!IO), 
        wavefront.write_point(V0, !IO), io.nl(!IO), 
        wavefront.write_point(V1, !IO), io.nl(!IO), 
        wavefront.write_point(V2, !IO), io.nl(!IO)
    ;
        true
    ).
