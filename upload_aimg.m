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

:- pred load(io.io::di, io.io::uo, string::in, result::out,
    mglow.window::di, mglow.window::uo) is det.

:- pred upload(aimg.texture::in, opengl.texture::out,
    mglow.window::di, mglow.window::uo) is det.

:- pred load(aimg.result::in, result::out,
    mglow.window::di, mglow.window::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

load(aimg.nofile, nofile, !Window).
load(aimg.badfile, badfile, !Window).
load(aimg.ok(AImgTex), ok(GLTex), !Window) :- upload(AImgTex, GLTex, !Window).

load(!IO, Path, Result, !Window) :-
    aimg.load(!IO, Path, AImgResult),
    load(AImgResult, Result, !Window).

:- func convert_pixels(aimg.pixels) = opengl.pixels.

:- pragma foreign_proc("C", convert_pixels(In::in) = (Out::out),
    [will_not_call_mercury, promise_pure, thread_safe, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "Out = In;").

:- pragma foreign_proc("Java", convert_pixels(In::in) = (Out::out),
    [will_not_call_mercury, promise_pure, thread_safe, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "Out = In;").

:- pragma inline(convert_pixels/1).

upload(AImgTex, Tex, !Window) :-
    Pix = convert_pixels(aimg.pixels(AImgTex)),
    W = aimg.width(AImgTex),
    H = aimg.height(AImgTex),
    opengl.upload_texture(Tex, Pix, W, H, !Window),
    opengl.bind_texture(Tex, !Window),
    opengl.texture_filter(opengl.min_filter, opengl.linear, !Window),
    opengl.texture_filter(opengl.mag_filter, opengl.linear, !Window).
