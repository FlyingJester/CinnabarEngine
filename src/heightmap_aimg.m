:- module heightmap_aimg.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module aimg.
:- use_module heightmap.

%------------------------------------------------------------------------------%

:- instance heightmap.heightmap(aimg.texture).

%==============================================================================%
:- implementation.
%==============================================================================%

:- instance heightmap.heightmap(aimg.texture) where [
    (heightmap.get(Texture, X, Y, Value) :-
        aimg.pixel(Texture, X, Y, Color),
        aimg.rf(Color) + aimg.bf(Color) + aimg.gf(Color) = Value
    ),
    func(heightmap.w/1) is (aimg.width),
    func(heightmap.h/1) is (aimg.height)
].
