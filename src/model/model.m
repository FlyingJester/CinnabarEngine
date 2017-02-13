:- module model.
%==============================================================================%
% A simple internal model format that is intended to be used with index-based 
% rendering setups, while still being simple to examine in software.
:- interface.
%==============================================================================%

:- use_module vector.
:- import_module list.

:- type point ---> point(x::float, y::float, z::float).
:- type normal ---> normal(vx::float, vy::float, vz::float).
:- type tex ---> tex(u::float, v::float).

:- type vertex ---> vertex(point, tex, normal).

:- type model(Texture) --->
    model(vertices::list.list(vertex), indices::list.list(int), texture::Texture).

:- typeclass loadable(Model) where [
    pred next(vertex, Model, Model),
    mode next(in, in, out) is det
].

:- func point(vector.vector3) = point.
:- func normal(vector.vector3) = normal.
:- func tex(vector.vector2) = tex.

%==============================================================================%
:- implementation.
%==============================================================================%

point(vector.vector(X, Y, Z)) = point(X, Y, Z).
normal(vector.vector(X, Y, Z)) = normal(X, Y, Z).
tex(vector.vector(U, V)) = tex(U, V).
