:- module render.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module matrix.
:- use_module mglow.

:- typeclass render(T) where [
    pred frustum(T,
        float, float, float, float, float, float,
        mglow.window, mglow.window),
    mode frustum(in, in, in, in, in, in, in, di, uo) is det

%    pred matrix(T, matrix.matrix, mglow.window, mglow.window),
%    mode matrix(in, in, di, uo) is det
].

:- typeclass model(Renderer, Model) <= render(Renderer) where [
    pred draw(Renderer, Model, mglow.window, mglow.window),
    mode draw(in, in, di, uo) is det
].

%==============================================================================%
:- implementation.
%==============================================================================%
