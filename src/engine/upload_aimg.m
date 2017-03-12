:- module upload_aimg.
%==============================================================================%
% Helper glue between AImg and OpenGL.
:- interface.
%==============================================================================%

:- use_module io.
:- use_module opengl.
:- use_module opengl.texture.
:- use_module aimg.
%------------------------------------------------------------------------------%

:- type result ---> ok(opengl.texture.texture) ; nofile ; badfile.

:- pred load_path(string::in, result::out,
    io.io::di, io.io::uo) is det.

:- pred upload(aimg.texture::in, opengl.texture.texture::out,
    io.io::di, io.io::uo) is det.

:- pred load(aimg.result::in, result::out,
    io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

load(aimg.nofile, nofile, !IO).
load(aimg.badfile, badfile, !IO).
load(aimg.ok(AImgTex), ok(GLTex), !IO) :- upload(AImgTex, GLTex, !IO).

load_path(Path, Result, !IO) :-
    aimg.load(!IO, Path, AImgResult),
    load(AImgResult, Result, !IO).

upload(AImgTex, Tex, !IO) :-
    Pix = aimg.pixels(AImgTex),
    W = aimg.width(AImgTex),
    H = aimg.height(AImgTex),
    opengl.texture.upload_texture(Tex, Pix, W, H, !IO),
    opengl.texture.bind_texture(Tex, !IO),
    opengl.tex_parameter(opengl.texture_min_filter, opengl.nearest, !IO),
    opengl.tex_parameter(opengl.texture_mag_filter, opengl.linear, !IO).
