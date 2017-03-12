:- module render.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module vector.
:- use_module color.
:- use_module io.
:- use_module softshape.
:- use_module wavefront.

:- type light --->
    diffuse(
        diffuse_color::color.color,
        diffuse_pos::vector.vector3,
        diffuse_intensity::float) ;
    ambient(
        ambient_color::color.color,
        ambient_pos::vector.vector3,
        ambient_intensity::float) ;
    directional(
        dir_color::color.color,
        dir_dir::vector.vector3,
        dir_intensity::float).

%------------------------------------------------------------------------------%

:- func light_color(light) = color.color.

%------------------------------------------------------------------------------%

:- func light_position(light) = vector.vector3.

%------------------------------------------------------------------------------%

:- func light_intensity(light) = float.

%------------------------------------------------------------------------------%

:- typeclass render(Ctx) where [

    % frustum(Ctx, NearZ, FarZ, Left, Right, Top, Bottom, !IO)
    pred frustum(Ctx, float, float, float, float, float, float, io.io, io.io),
    mode frustum(in, in, in, in, in, in, in, di, uo) is det,
    
    % Disables or enables depth test.
    pred disable_depth(Ctx::in, io.io::di, io.io::uo) is det,
    pred enable_depth(Ctx::in, io.io::di, io.io::uo) is det,
    
    % Purely experimental, we probably don't want to have a matrix stack like
    % OpenGL does in the end. Depending on how the scene graph works out, it may
    % just become clear which matrix to use where without keeping track of
    % previous states.
    pred push_matrix(Ctx::in, io.io::di, io.io::uo) is det,
    pred pop_matrix(Ctx::in, io.io::di, io.io::uo) is det,

    % Translates by the specified amount.
    % translate(Renderer, X, Y, Z, !IO)
    pred translate(Ctx, float, float, float, io.io, io.io),
    mode translate(in, in, in, in, di, uo) is det,

    pred rotate_x(Ctx, float, io.io, io.io),
    mode rotate_x(in, in, di, uo) is det,
    pred rotate_y(Ctx, float, io.io, io.io),
    mode rotate_y(in, in, di, uo) is det,
    pred rotate_z(Ctx, float, io.io, io.io),
    mode rotate_z(in, in, di, uo) is det,

    pred scale(Ctx, float, float, float, io.io, io.io),
    mode scale(in, in, in, in, di, uo) is det,

    func max_lights(Ctx) = int,
    pred light(Ctx, int, light, io.io, io.io),
    mode light(in, in, in, di, uo) is det

].

%------------------------------------------------------------------------------%

:- typeclass model_compiler(Ctx, Model) where [
    pred compile_wavefront(wavefront.shape, Ctx, Model),
    mode compile_wavefront(in, in, out) is det,
    pred compile_softshape(softshape.shape3d, Ctx, Model),
    mode compile_softshape(in, in, out) is det
].

%------------------------------------------------------------------------------%

:- typeclass model(Ctx, Model) where [
    pred draw(Ctx, Model, io.io, io.io),
    mode draw(in, in, di, uo) is det
].

%------------------------------------------------------------------------------%

% Texture is also called Skybox in other places.
:- typeclass skybox(Ctx, Texture) <= render(Ctx) where [
    % draw(Renderer, Pitch, Yaw, Tex, !Window)
    pred draw_skybox(Ctx, float, float, Texture, io.io, io.io),
    mode draw_skybox(in, in, in, in, di, uo) is det
].

%------------------------------------------------------------------------------%

:- typeclass heightmap(Ctx, Heightmap, Texture) <= render(Ctx) where[
    pred draw_heightmap(Ctx, Heightmap, Texture, io.io, io.io),
    mode draw_heightmap(in, in, in, di, uo) is det
].

%==============================================================================%
:- implementation.
%==============================================================================%

%------------------------------------------------------------------------------%

light_color(diffuse(C, _, _)) = C.
light_color(ambient(C, _, _)) = C.
light_color(directional(C, _, _)) = C.

%------------------------------------------------------------------------------%

light_position(diffuse(_, P, _)) = P.
light_position(ambient(_, P, _)) = P.
light_position(directional(_, P, _)) = P.

%------------------------------------------------------------------------------%

light_intensity(diffuse(_, _, I)) = I.
light_intensity(ambient(_, _, I)) = I.
light_intensity(directional(_,  _, I)) = I.
