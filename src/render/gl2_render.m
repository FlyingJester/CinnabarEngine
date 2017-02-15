:- module gl2_render.
%==============================================================================%
% Implements the Render typeclasses for the OpenGL2 bindings.
:- interface.
%==============================================================================%

:- use_module opengl.
:- use_module opengl.texture.
:- use_module wavefront.
:- use_module softshape.
:- use_module model.
:- use_module render.
:- use_module mglow.

:- include_module gl2_render.heightmap.

%------------------------------------------------------------------------------%

% The compiled model for the OpenGL2 renderer can be either a wavefront or a
% softshape. A wavefront will use slightly less memory, although the drawing
% will be slightly slower.
:- type model --->
    wave(wavefront.shape) ;
    wave(wavefront.shape, opengl.texture.texture) ;
    soft(softshape.shape3d).

:- type gl2_render ---> gl2_render.

%------------------------------------------------------------------------------%

% Although the render and model typeclasses are particularly implemented for
% glow.window right now, the actual preds that implement them to use a variable
% type rather than mglow. Most render preds call directly into opengl2.m
:- instance render.render(gl2_render, mglow.window).

:- instance render.model_compiler(gl2_render, model).

:- instance render.model(gl2_render, model, mglow.window).

%------------------------------------------------------------------------------%

% Model implementation.
% Since model is just a thin wrapper over wavefronts and softshapes, these are
% just implemented separately and the applicable pred is chosed with rules in
% the render.model typeclass implementation.
:- pred draw_wave(wavefront.shape::in, Window::di, Window::uo) is det.

:- pred draw_soft(softshape.shape3d::in, Window::di, Window::uo) is det.

% Used to implement the draw_wave pred
:- pred draw_wave_face(wavefront.face::in,
    wavefront.shape::in, wavefront.shape::out,
    Window::di, Window::uo) is det.

% Used to implement draw_wave and draw_wave_face
:- pred draw_wave_vertex(wavefront.vertex::in,
    wavefront.shape::in, wavefront.shape::out,
    Window::di, Window::uo) is det.

% Used to implement draw_wave and draw_wave_face
:- pred draw_model_vertex(model.vertex::in, Window::di, Window::uo) is det.

% Used to implement the draw_soft pred
:- pred draw_soft_vertex(softshape.vertex3d::in, Window::di, Window::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module opengl2.
:- use_module upload_aimg.
:- use_module list.
:- use_module float.

:- instance render.render(gl2_render, mglow.window) where [
    ( frustum(gl2_render, Nz, Fz, L, R, T, B, !Window) :- 
        opengl2.frustum(L, R, B, T, Nz, Fz, !Window) ),
    % Disables or enables depth test.
    ( enable_depth(gl2_render, !Window) :- opengl.enable_depth_test(!Window)),
    ( disable_depth(gl2_render, !Window) :- opengl.disable_depth_test(!Window)),

    ( push_matrix(gl2_render, !Window) :- opengl2.push_matrix(!Window)),
    ( pop_matrix(gl2_render, !Window) :- opengl2.pop_matrix(!Window)),

    ( translate(gl2_render, X, Y, Z, !Window) :-
        opengl2.translate(X, Y, Z, !Window) ),

    ( rotate_x(gl2_render, A, !Window) :-
        opengl2.rotate(A, 1.0, 0.0, 0.0, !Window) ),
    ( rotate_y(gl2_render, A, !Window) :-
        opengl2.rotate(A, 0.0, 1.0, 0.0, !Window) ),
    ( rotate_z(gl2_render, A, !Window) :-
        opengl2.rotate(A, 0.0, 0.0, 1.0, !Window) ),
    ( rotate_about(gl2_render, X, Y, Z, A, !Window) :-
        opengl2.rotate(A, X, Y, Z, !Window) ),

    ( scale(gl2_render, X, Y, Z, !Window) :- opengl2.scale(X, Y, Z, !Window) ),

    ( draw_image(gl2_render, X, Y, W, H, Pix, !Window) :-
        opengl2.raster_pos(float.float(X), float.float(Y), !Window),
        opengl2.draw_pixels(W, H, Pix, !Window),
        opengl2.raster_pos(0.0, 0.0, !Window) )
].

:- instance render.model_compiler(gl2_render, model) where [
    compile_wavefront(gl2_render, Shape, wave(Shape)),
    compile_softshape(gl2_render, Shape, soft(Shape))
].

:- instance render.model(gl2_render, model, mglow.window) where [
    (render.draw(gl2_render, wave(Shape), !Window) :-
        opengl2.disable_texture(!Window), draw_wave(Shape, !Window) ),
    (render.draw(gl2_render, wave(Shape, Tex), !Window) :-
        opengl.texture.bind_texture(Tex, !Window),
        draw_wave(Shape, !Window) ),
    (render.draw(gl2_render, soft(Shape), !Window) :- draw_soft(Shape, !Window))
].

draw_wave(Shape, !Window) :-
    list.foldl2(draw_wave_face, Shape ^ wavefront.faces, Shape, _, !Window).

draw_wave_face(wavefront.face(Vertices), !Shape, !Window) :-
    opengl2.begin(opengl.triangle_fan, !Window),
    list.foldl2(draw_wave_vertex, Vertices, !Shape, !Window),
    opengl2.end(!Window).

draw_wave_vertex(Vertex, !Shape, !Window) :-
    Vertex = wavefront.vertex(PointIndex, TexIndex, NormalIndex),
    list.det_index0(!.Shape ^ wavefront.vertices, PointIndex, Point),
    list.det_index0(!.Shape ^ wavefront.tex_coords, TexIndex, Tex),
    list.det_index0(!.Shape ^ wavefront.normals, NormalIndex, Normal),
    draw_model_vertex(model.vertex(Point, Tex, Normal), !Window).

draw_model_vertex(model.vertex(Point, Tex, Normal), !Window) :-
    Point = model.point(X, Y, Z),
    Tex = model.tex(U, V),
    Normal = model.normal(NX, NY, NZ),
    opengl2.tex_coord(U, V, !Window),
    opengl2.normal(NX, NY, NZ, !Window),
    opengl2.vertex(X, Y, Z, !Window).

draw_soft(softshape.shape3d(Vertices), !Window) :-
    opengl2.disable_texture(!Window),
    opengl2.begin(opengl.triangle_strip, !Window),
    list.foldl(draw_soft_vertex, Vertices, !Window),
    opengl2.end(!Window).

draw_soft(softshape.shape3d(Vertices, R, G, B), !Window) :-
    opengl2.color(R, G, B, 1.0, !Window),
    draw_soft(softshape.shape3d(Vertices), !Window),
    opengl2.color(1.0, 1.0, 1.0, 1.0, !Window).

draw_soft_vertex(softshape.vertex(X, Y, Z, U, V), !Window) :-
    opengl2.tex_coord(U, V, !Window),
    opengl2.vertex(X, Y, Z, !Window).
