:- module gl2.skybox.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module opengl.
:- use_module mglow.
:- use_module render.
%------------------------------------------------------------------------------%

% draw(Pitch, Yaw, Texture, !Window)
:- pred draw(float, float, opengl.texture, mglow.window, mglow.window).
:- mode draw(in, in, in, di, uo) is det.

:- instance render.skybox(gl2, opengl.texture).

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module float.

:- func sin_quarter_pi = float.
sin_quarter_pi = 0.707106781.

:- pred outer_edge(mglow.window::di, mglow.window::uo) is det.
outer_edge(!Window) :-
    SQP = sin_quarter_pi * 10.0,
    gl2.tex_coord(1.0, 0.5, !Window),
    gl2.vertex3(10.0, 0.0, 0.0, !Window),

    gl2.tex_coord(1.0, 1.0, !Window),
    gl2.vertex3(SQP, 0.0, -SQP, !Window),
    
    gl2.tex_coord(0.5, 1.0, !Window),
    gl2.vertex3(0.0, 0.0, -10.0, !Window),
    
    gl2.tex_coord(0.0, 1.0, !Window),
    gl2.vertex3(-SQP, 0.0, -SQP, !Window),

    gl2.tex_coord(0.0, 0.5, !Window),
    gl2.vertex3(-10.0, 0.0, 0.0, !Window),

    gl2.tex_coord(0.0, 0.0, !Window),
    gl2.vertex3(-SQP, 0.0, SQP, !Window),
    
    gl2.tex_coord(0.5, 0.0, !Window),
    gl2.vertex3(0.0, 0.0, 10.0, !Window),
    
    gl2.tex_coord(1.0, 0.0, !Window),
    gl2.vertex3(SQP, 0.0, SQP, !Window),

    gl2.tex_coord(1.0, 0.5, !Window),
    gl2.vertex3(10.0, 0.0, 0.0, !Window).
        

draw(Pitch, Yaw, Texture, !Window) :-
    SQP = sin_quarter_pi * 10.0,
    opengl.disable_depth(!Window),
    opengl.bind_texture(Texture, !Window),
    gl2.push_matrix(!Window),
    gl2.rotate(Pitch, 1.0, 0.0, 0.0, !Window),
    gl2.rotate(Yaw,   0.0, 1.0, 0.0, !Window),
    
    gl2.begin(opengl.triangle_fan, !Window),

    gl2.tex_coord(0.5, 0.5, !Window),
    gl2.vertex3(0.0, SQP, 0.0, !Window),
    outer_edge(!Window),

    gl2.end(!Window),

    gl2.begin(opengl.triangle_fan, !Window),

    gl2.tex_coord(0.5, 0.5, !Window),
    gl2.vertex3(0.0, -SQP, 0.0, !Window),
    outer_edge(!Window),

    gl2.end(!Window),
    
    gl2.pop_matrix(!Window),

    opengl.enable_depth(!Window),
    opengl.clear_depth(!Window).

:- instance render.skybox(gl2, opengl.texture) where [
    (render.draw_skybox(_, Pitch, Yaw, Tex, !Window) :- draw(Pitch, Yaw, Tex, !Window))
].
