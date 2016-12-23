:- module model.
%==============================================================================%
% A simple internal model format that is intended to be used with index-based 
% rendering setups, while still being simple to examine in software.
:- interface.
%==============================================================================%

:- import_module list.

:- type point ---> point(x::float, y::float, z::float).
:- type normal ---> normal(vx::float, vy::float, vz::float).
:- type tex ---> tex(u::float, v::float).

:- type vertex ---> vertex(point, tex, normal).

:- type model(Texture) --->
    model(vertices::list.list(vertex), indices::list.list(int), texture::Texture).

:- typeclass loadable(Model) where [
    pred next(Model, Model, vertex),
    mode next(in, out, out) is semidet
].

% :- pred load(Model::in, Texture::in, model(Texture)::out) is det <= loadable(Model).

%==============================================================================%
:- implementation.
%==============================================================================%

%:- pred load_inner(Model::in,
%    list(vertex)::in, list(vertex)::out,
%    list(int)::in, list(int)::out) is det
%    <= loadable(Model).

%load(In, Tex, model(OutList, OutIndices, Tex)) :-
%    load_inner(In, [], List, [], Indices),
%    list.reverse(List, OutList),
%    list.reverse(Indices, OutIndices).
