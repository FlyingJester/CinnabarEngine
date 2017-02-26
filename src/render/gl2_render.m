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
:- use_module io.

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

:- instance render.render(gl2_render).

:- instance render.model_compiler(gl2_render, model).

:- instance render.model(gl2_render, model).

%------------------------------------------------------------------------------%

% Model implementation.
% Since model is just a thin wrapper over wavefronts and softshapes, these are
% just implemented separately and the applicable pred is chosed with rules in
% the render.model typeclass implementation.
:- pred draw_wave(wavefront.shape::in, io.io::di, io.io::uo) is det.

:- pred draw_soft(softshape.shape3d::in, io.io::di, io.io::uo) is det.

% Used to implement the draw_wave pred
:- pred draw_wave_face(wavefront.face::in,
    wavefront.shape::in, wavefront.shape::out,
    io.io::di, io.io::uo) is det.

% Used to implement draw_wave and draw_wave_face
:- pred draw_wave_vertex(wavefront.vertex::in,
    wavefront.shape::in, wavefront.shape::out,
    io.io::di, io.io::uo) is det.

% Used to implement draw_wave and draw_wave_face
:- pred draw_model_vertex(model.vertex::in, io.io::di, io.io::uo) is det.

% Used to implement the draw_soft pred
:- pred draw_soft_vertex(softshape.vertex3d::in, io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module opengl2.
:- use_module upload_aimg.
:- use_module list.
:- use_module float.

:- instance render.render(gl2_render) where [
    ( frustum(gl2_render, Nz, Fz, L, R, T, B, !IO) :- 
        opengl2.frustum(L, R, B, T, Nz, Fz, !IO) ),
    % Disables or enables depth test.
    ( enable_depth(gl2_render, !IO) :- opengl.enable_depth_test(!IO)),
    ( disable_depth(gl2_render, !IO) :- opengl.disable_depth_test(!IO)),

    ( push_matrix(gl2_render, !IO) :- opengl2.push_matrix(!IO)),
    ( pop_matrix(gl2_render, !IO) :- opengl2.pop_matrix(!IO)),

    ( translate(gl2_render, X, Y, Z, !IO) :-
        opengl2.translate(X, Y, Z, !IO) ),

    ( rotate_x(gl2_render, A, !IO) :-
        opengl2.rotate(A, 1.0, 0.0, 0.0, !IO) ),
    ( rotate_y(gl2_render, A, !IO) :-
        opengl2.rotate(A, 0.0, 1.0, 0.0, !IO) ),
    ( rotate_z(gl2_render, A, !IO) :-
        opengl2.rotate(A, 0.0, 0.0, 1.0, !IO) ),
    ( rotate_about(gl2_render, X, Y, Z, A, !IO) :-
        opengl2.rotate(A, X, Y, Z, !IO) ),

    ( scale(gl2_render, X, Y, Z, !IO) :- opengl2.scale(X, Y, Z, !IO) ),

    ( draw_image(gl2_render, X, Y, W, H, Pix, !IO) :-
        opengl2.raster_pos(float.float(X), float.float(Y), !IO),
        opengl2.draw_pixels(W, H, Pix, !IO),
        opengl2.raster_pos(0.0, 0.0, !IO) )
].

:- instance render.model_compiler(gl2_render, model) where [
    compile_wavefront(Shape, gl2_render, wave(Shape)),
    compile_softshape(Shape, gl2_render, soft(Shape))
].

:- instance render.model(gl2_render, model) where [
    (render.draw(gl2_render, wave(Shape), !IO) :-
        opengl2.disable_texture(!IO), draw_wave(Shape, !IO) ),
    
    (render.draw(gl2_render, wave(Shape, Tex), !IO) :-
        opengl.texture.bind_texture(Tex, !IO),
        draw_wave(Shape, !IO) ),
    
    (render.draw(gl2_render, soft(Shape), !Window) :- draw_soft(Shape, !IO))
].

draw_wave(Shape, !IO) :-
    list.foldl2(draw_wave_face, Shape ^ wavefront.faces, Shape, _, !IO).

draw_wave_face(wavefront.face(Vertices), !Shape, !IO) :-
    opengl2.begin(opengl.triangle_fan, !Window),
    list.foldl2(draw_wave_vertex, Vertices, !Shape, !IO),
    opengl2.end(!Window).

draw_wave_vertex(Vertex, !Shape, !IO) :-
    Vertex = wavefront.vertex(PointIndex, TexIndex, NormalIndex),
    list.det_index0(!.Shape ^ wavefront.vertices, PointIndex, Point),
    list.det_index0(!.Shape ^ wavefront.tex_coords, TexIndex, Tex),
    list.det_index0(!.Shape ^ wavefront.normals, NormalIndex, Normal),
    draw_model_vertex(model.vertex(Point, Tex, Normal), !IO).

draw_model_vertex(model.vertex(Point, Tex, Normal), !IO) :-
    Point = model.point(X, Y, Z),
    Tex = model.tex(U, V),
    Normal = model.normal(NX, NY, NZ),
    opengl2.tex_coord(U, V, !IO),
    opengl2.normal(NX, NY, NZ, !IO),
    opengl2.vertex(X, Y, Z, !IO).

draw_soft(softshape.shape3d(Vertices), !IO) :-
    opengl2.disable_texture(!IO),
    opengl2.begin(opengl.triangle_strip, !IO),
    list.foldl(draw_soft_vertex, Vertices, !IO),
    opengl2.end(!IO).

draw_soft(softshape.shape3d(Vertices, R, G, B), !IO) :-
    opengl2.color(R, G, B, 1.0, !IO),
    draw_soft(softshape.shape3d(Vertices), !IO),
    opengl2.color(1.0, 1.0, 1.0, 1.0, !IO).

draw_soft_vertex(softshape.vertex(X, Y, Z, U, V), !IO) :-
    opengl2.tex_coord(U, V, !IO),
    opengl2.vertex(X, Y, Z, !IO).
