:- module perlin.
%==============================================================================%
:- interface.
%==============================================================================%

% perlin(Seed, X, Y, W, H) = Value.
:- func perlin(int, float, float, int, int) = (float).

% Arranged in XY as so:
%
% V0 V1 
% V2 V3
%
% val(Seed, X, Y, W, OutV0, OutV1, OutV2, OutV3)
:- pred val(int, int, int, int, float, float, float, float).
:- mode val(in, in, in, in, out, out, out, out) is det.

% Used to convert from an integer to an angle
:- func range(int, float, float) = float.
:- func angle(int) = float.
:- func lerp(float, float, float) = float.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module int.
:- import_module float.
:- use_module math.

:- use_module xorshift.

%------------------------------------------------------------------------------%

% seed(!State, X, Y, TargetX, TargetY, W, OutV0, OutV1).
:- pred seed(xorshift.state, xorshift.state, int, int, int, int, int, int, int).
:- mode seed(mdi, muo, in, in, in, in, in, out, out) is det.

%------------------------------------------------------------------------------%

:- pragma foreign_export("C", perlin(in, in, in, in, in) = out,
    "Cinnabar_Perlin").
:- pragma foreign_export("C", val(in, in, in, in, out, out, out, out),
    "Cinnabar_PerlinVal").
:- pragma foreign_export("C", seed(mdi, muo, in, in, in, in, in, out, out),
    "Cinnabar_PerlinSeed").
:- pragma foreign_export("C", lerp(in, in, in) = out,
    "Cinnabar_PerlinLerp").
:- pragma foreign_export("C", angle(in) = out,
    "Cinnabar_PerlinAngle").

%------------------------------------------------------------------------------%

seed(!State, X, Y, TargetX, TargetY, W, OutV0, OutV1) :-
    ( X >= TargetX, Y >= TargetY ->
        xorshift.next(OutV0, !State),
        xorshift.next(OutV1, !State)
    ; X >= W ->
        seed(!State, 0, Y+1, TargetX, TargetY, W, OutV0, OutV1)
    ;
        xorshift.next(_, !State),
        seed(!State, X+1, Y, TargetX, TargetY, W, OutV0, OutV1)
    ).

%------------------------------------------------------------------------------%

val(Seed, X, Y, W, angle(I0), angle(I1), angle(I2), angle(I3)) :-
    State0 = xorshift.init(Seed, Seed, Seed, Seed),
    seed(State0, State1, 0, 0, X, Y, W, I0, I1),
    ( X + 1 < W ->
        seed(State1, _, X+2, Y, X, Y+1, W, I2, I3)
    ;
        State2 = xorshift.init(Seed, Seed, Seed, Seed),
        seed(State2, _, 0, 0, X, Y+1, W, I2, I3)
    ).

%------------------------------------------------------------------------------%

:- func dot(float::in, float::in, int::di, int::di, float::in) =
    (float::uo) is det.
dot(X, Y, GridX, GridY, Angle) = (DX*math.sin(Angle)) + (DY*math.cos(Angle)) :-
    DX = X - float(GridX),
    DY = Y - float(GridY).

%------------------------------------------------------------------------------%

perlin(Seed, X, Y, W, _) = Value :-
    GridX = floor_to_int(X), GridY = floor_to_int(Y),
    val(Seed, GridX, GridY, W, A0, A1, A2, A3),
    Dot0 = dot(X, Y, GridX+0, GridY+0, A0),
    Dot1 = dot(X, Y, GridX+1, GridY+0, A1),
    Dot2 = dot(X, Y, GridX+0, GridY+1, A2),
    Dot3 = dot(X, Y, GridX+1, GridY+1, A3),
    SX = X - float(GridX),
    SY = Y - float(GridY),
    VX0 = lerp(SX, Dot0, Dot1),
    VX1 = lerp(SX, Dot2, Dot3),
    Value = lerp(SY, VX0, VX1).

%------------------------------------------------------------------------------%

:- func i16 = int.
i16 = 0xFFFF.

:- func i16(int) = int.
i16(I) = int.xor(int.unchecked_right_shift(I, 16), I) /\ i16.

range(I, A, B) = float.min(A, B) +
    (float.abs(B - A) * (float(i16(I)) / float(i16))).
angle(I) = (float(i16(I)) / float(i16)) * 6.283185307.

lerp(T, A, B) = ((1.0 - T) * A) + (T * B).

