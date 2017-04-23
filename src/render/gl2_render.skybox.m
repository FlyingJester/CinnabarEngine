:- module gl2_render.skybox.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module opengl.
:- use_module opengl.texture.
:- use_module render.

%------------------------------------------------------------------------------%

% draw(Pitch, Yaw, Texture, !IO)
:- pred draw(float, float, opengl.texture.texture, io.io, io.io).
:- mode draw(in, in, in, di, uo) is det.

:- instance render.skybox(gl2_render, opengl.texture.texture).

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module string.
:- import_module float.
:- use_module opengl2.
:- use_module upload_aimg.

%------------------------------------------------------------------------------%

:- func sin_quarter_pi = float.
sin_quarter_pi = 0.707106781.

%------------------------------------------------------------------------------%

:- pred outer_edge(io.io::di, io.io::uo) is det.
outer_edge(!IO) :-
    SQP = sin_quarter_pi * 10.0,
    opengl2.tex_coord(1.0, 0.5, !IO),
    opengl2.vertex(10.0, 0.0, 0.0, !IO),

    opengl2.tex_coord(1.0, 1.0, !IO),
    opengl2.vertex(SQP, 0.0, -SQP, !IO),
    
    opengl2.tex_coord(0.5, 1.0, !IO),
    opengl2.vertex(0.0, 0.0, -10.0, !IO),
    
    opengl2.tex_coord(0.0, 1.0, !IO),
    opengl2.vertex(-SQP, 0.0, -SQP, !IO),

    opengl2.tex_coord(0.0, 0.5, !IO),
    opengl2.vertex(-10.0, 0.0, 0.0, !IO),

    opengl2.tex_coord(0.0, 0.0, !IO),
    opengl2.vertex(-SQP, 0.0, SQP, !IO),
    
    opengl2.tex_coord(0.5, 0.0, !IO),
    opengl2.vertex(0.0, 0.0, 10.0, !IO),
    
    opengl2.tex_coord(1.0, 0.0, !IO),
    opengl2.vertex(SQP, 0.0, SQP, !IO),

    opengl2.tex_coord(1.0, 0.5, !IO),
    opengl2.vertex(10.0, 0.0, 0.0, !IO).

%------------------------------------------------------------------------------%

draw(Pitch, Yaw, Texture, !IO) :-
    SQP = sin_quarter_pi * 10.0,
    opengl.disable_depth_test(!IO),
    opengl.texture.bind_texture(Texture, !IO),
    opengl2.push_matrix(!IO),
    opengl2.rotate(Pitch, 1.0, 0.0, 0.0, !IO),
    opengl2.rotate(Yaw,   0.0, 1.0, 0.0, !IO),
    
    opengl2.begin(opengl.triangle_fan, !IO),

    opengl2.tex_coord(0.5, 0.5, !IO),
    opengl2.vertex(0.0, SQP, 0.0, !IO),
    outer_edge(!IO),

    opengl2.end(!IO),

    opengl2.begin(opengl.triangle_fan, !IO),

    opengl2.tex_coord(0.5, 0.5, !IO),
    opengl2.vertex(0.0, -SQP, 0.0, !IO),
    outer_edge(!IO),

    opengl2.end(!IO),
    
    opengl2.pop_matrix(!IO),

    opengl.enable_depth_test(!IO),
    opengl.clear_depth_buffer_bit(!IO).

%------------------------------------------------------------------------------%

:- instance render.skybox(gl2_render, opengl.texture.texture) where [
    (render.draw_skybox(gl2_render, Pitch, Yaw, Tex, !IO) :- draw(Pitch, Yaw, Tex, !IO)),
    (render.load_skybox(gl2_render, Path, Result, !IO) :- 
        upload_aimg.load_path(Path, TexResult, !IO),
        (
            TexResult = upload_aimg.ok(Tex),
            Result = io.ok(Tex)
        ;
            TexResult = upload_aimg.badfile,
            Err = string.append(Path, " is not valid"),
            Result = io.error(io.make_io_error(Err))
        ;
            TexResult = upload_aimg.nofile,
            Err = string.append(Path, " does not exist"),
            Result = io.error(io.make_io_error(Err))
        )
    )
].
