:- module xorshift.
%==============================================================================%
% Quick but somewhat inadequate RNG. Mostly useful for seeding procedural
% content, like Perlin noise.
:- interface.
%==============================================================================%

:- type state ---> state(a::int, b::int, c::int, d::int).
:- func init(int::in, int::in, int::in, int::in) = (state::uo) is det.
:- pred next(int::uo, state::mdi, state::muo) is det.
:- pred copy(state::in, state::uo, state::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module int.
:- import_module float.

:- pragma inline(next/3).
:- pragma inline(copy/3).

:- pragma foreign_export("C", init(in, in, in, in) = uo,
    "Cinnabar_M_CreateXORShiftRNG").

:- pragma foreign_export("C", next(uo, mdi, muo),
    "Cinnabar_M_XORShiftNext").

:- func i32 = int.
i32 = 0xFFFFFFFF.

:- func i32(int::in) = (int::uo) is det.
i32(I) = I /\ i32.

init(A, B, C, D) = state(i32(A), i32(B), i32(C), i32(D)).

:- func xor_left_shift(int, int) = int.
:- func xor_right_shift(int, int) = int.
xor_left_shift(A, B) = xor(i32(unchecked_left_shift(A, B)), A).
xor_right_shift(A, B) = xor(i32(unchecked_right_shift(A, B)), A).

copy(state(A, B, C, D), state(A+0, B+0, C+0, D+0), state(A+0, B+0, C+0, D+0)).
next(Out+0, state(A, B, C, D), state(Out+0, A+0, B+0, C+0)) :-
    T0 = xor_left_shift(D, 11),
    T1 = xor_right_shift(T0, 8),
    T2 = xor(A, T1),
    Out = xor(i32(unchecked_right_shift(A, 19)), T2).

