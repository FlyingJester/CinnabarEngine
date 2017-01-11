:- module vector.
%==============================================================================%
:- interface.
%==============================================================================%

%------------------------------------------------------------------------------%
:- type vector2 ---> vector(float, float).
:- type vector3 ---> vector(float, float, float).
:- type vector4 ---> vector(float, float, float, float).

% :- func dot(vector3, vector3) = (vector3).

:- func normalize2(vector2) = vector2.
:- func normalize3(vector3) = vector3.
:- func normalize4(vector4) = vector4.

:- func magnitude2(vector2) = float. 
:- func magnitude3(vector3) = float.
:- func magnitude4(vector4) = float.

:- func multiply2(vector2, float) = vector2.
:- func multiply3(vector3, float) = vector3.
:- func multiply4(vector4, float) = vector4.

:- func divide2(vector2, float) = vector2.
:- func divide3(vector3, float) = vector3.
:- func divide4(vector4, float) = vector4.

:- func add2(vector2, vector2) = vector2.
:- func add3(vector3, vector3) = vector3.
:- func add4(vector4, vector4) = vector4.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module float.
:- use_module math.

normalize2(V) = Out :-
    M = magnitude2(V),
    ( M = 0.0 ->
        Out = vector(0.0, 0.0)
    ;
        divide2(V, M) = Out
    ).

normalize3(V) = Out :-
    M = magnitude3(V),
    ( M = 0.0 ->
        Out = vector(0.0, 0.0, 0.0)
    ;
        divide3(V, M) = Out
    ).

normalize4(V) = Out :-
    M = magnitude4(V),
    ( M = 0.0 ->
        Out = vector(0.0, 0.0, 0.0, 0.0)
    ;
        divide4(V, M) = Out
    ).

magnitude2(vector(X,Y)) = math.sqrt((X*X) + (Y*Y)).
magnitude3(vector(X,Y,Z)) = math.sqrt((X*X) + (Y*Y) + (Z*Z)).
magnitude4(vector(X,Y,Z,W)) = math.sqrt((X*X) + (Y*Y) + (Z*Z) + (W*W)).

multiply2(vector(X,Y), N) = vector(X*N, Y*N).
multiply3(vector(X,Y,Z), N) = vector(X*N, Y*N, Z*N).
multiply4(vector(X,Y,Z,W), N) = vector(X*N, Y*N, Z*N, W*N).

divide2(vector(X,Y), N) = vector(X/N, Y/N).
divide3(vector(X,Y,Z), N) = vector(X/N, Y/N, Z/N).
divide4(vector(X,Y,Z,W), N) = vector(X/N, Y/N, Z/N, W/N).

add2(vector(X0, Y0), vector(X1, Y1)) = vector(X0 + X1, Y0 + Y1).
add3(vector(X0, Y0, Z0), vector(X1, Y1, Z1)) = vector(X0 + X1, Y0 + Y1, Z0 + Z1).
add4(vector(X0, Y0, Z0, W0), vector(X1, Y1, Z1, W1)) =
    vector(X0 + X1, Y0 + Y1, Z0 + Z1, W0 + W1).



