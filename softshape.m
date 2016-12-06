:- module softshape.
%==============================================================================%
:- interface.
%==============================================================================%

:- import_module list.

:- type vertex2d ---> vertex(x2::float, y2::float, u2::float, v2::float).
:- type vertex3d ---> vertex(x3::float, y3::float, z3::float, u3::float, v3::float).
:- type shape2d ---> shape2d(list(vertex2d)) ;
    shape2d(list(vertex2d), float, float, float).

:- type shape3d ---> shape3d(list(vertex3d)) ;
    shape3d(list(vertex3d), float, float, float).

% Abstraction for vertex2 and vertex3.
:- typeclass vertex(T) where [
    func x(T) = float,
    func y(T) = float,
    func z(T) = float,
    func u(T) = float,
    func v(T) = float
].

:- instance vertex(vertex2d).
:- instance vertex(vertex3d).

:- func rectangle(float, float, float, float) = shape2d.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module float.

rectangle(X, Y, W, H) = shape2d([vertex(X, Y, 0.0, 0.0)
    |[vertex(X+W, Y,   1.0, 0.0)
    |[vertex(X+W, Y+H, 1.0, 1.0)
    |[vertex(X,   Y+H, 0.0, 1.0)
    |[]]]]]).

:- instance vertex(vertex2d) where [
    x(V) = V ^ x2,
    y(V) = V ^ y2,
    z(_) = 0.0,
    u(V) = V ^ u2,
    v(V) = V ^ v2
].

:- instance vertex(vertex3d) where [
    x(V) = V ^ x3,
    y(V) = V ^ y3,
    z(V) = V ^ z3,
    u(V) = V ^ u3,
    v(V) = V ^ v3
].
