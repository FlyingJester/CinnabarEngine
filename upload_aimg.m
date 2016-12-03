:- module upload_aimg.
%==============================================================================%
% Helper glue between AImg and OpenGL.
:- interface.
%==============================================================================%

:- use_module io.
:- use_module opengl.
:- use_module mglow.
:- use_module aimg.
%------------------------------------------------------------------------------%

:- type result ---> ok(opengl.texture) ; nofile ; badfile.

:- pred load(io.io::di, io.io::uo, string::in, result::uo, mglow.window::di, mglow.window::uo) is det.
:- pred upload(aimg.texture::in, opengl.texture::uo, mglow.window::di, mglow.window::uo) is det.
:- pred load(aimg.result::in, result::uo, mglow.window::di, mglow.window::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

load(aimg.nofile, nofile, !Window).
load(aimg.badfile, badfile, !Window).
load(aimg.ok(AImgTex), ok(GLTex), !Window) :- upload(AImgTex, GLTex, !Window).

load(!IO, Path, Result, !Window) :-
    aimg.load(!IO, Path, AImgResult),
    load(AImgResult, Result, !Window).

upload(AImgTex, Tex, !Window) :-
    Pix = aimg.pixels(AImgTex),
    W = aimg.width(AImgTex),
    H = aimg.height(AImgTex),
    opengl.upload_texture(Tex, Pix, W, H, !Window).
