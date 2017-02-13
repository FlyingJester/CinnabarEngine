:- module render.
%==============================================================================%
:- interface.
%==============================================================================%

%:- use_module matrix.
:- use_module softshape.
:- use_module wavefront.

%------------------------------------------------------------------------------%

% TODO: Ideally, a renderer would also be dependant on the window type. This
% would much more easily allow something like a software renderer, or a GL2
% renderer that can use FLTK or Glow, for instance.
:- typeclass render(T, Window) where [

    % frustum(Renderer, NearZ, FarZ, Left, Right, Top, Bottom)
    pred frustum(T,
        float, float, float, float, float, float, Window, Window),
    mode frustum(in, in, in, in, in, in, in, di, uo) is det,
    
    % Disables or enables depth test.
    pred disable_depth(T::in, Window::di, Window::uo) is det,
    pred enable_depth(T::in, Window::di, Window::uo) is det,
    
    % Purely experimental, we probably don't want to have a matrix stack like
    % OpenGL does in the end. Depending on how the scene graph works out, it may
    % just become clear which matrix to use where without keeping track of
    % previous states.
    pred push_matrix(T::in, Window::di,Window::uo) is det,
    pred pop_matrix(T::in, Window::di, Window::uo) is det,

    % Translates by the specified amount.
    % translate(Renderer, X, Y, Z, !Window)
    pred translate(T, float, float, float, Window, Window),
    mode translate(in, in, in, in, di, uo) is det,

    pred rotate_x(T, float, Window, Window),
    mode rotate_x(in, in, di, uo) is det,
    pred rotate_y(T, float, Window, Window),
    mode rotate_y(in, in, di, uo) is det,
    pred rotate_z(T, float, Window, Window),
    mode rotate_z(in, in, di, uo) is det,
    pred rotate_about(T, float, float, float, float, Window, Window),
    mode rotate_about(in, in, in, in, in, di, uo) is det,

    pred scale(T, float, float, float, Window, Window),
    mode scale(in, in, in, in, di, uo) is det,
    
    % Draws a given 32-bit RGBA image at X, Y. This may be somewhat slow, so it
    % is recommended only for bridging some software rendering with the
    % hardware renderer.
    % draw_image(X, Y, W, H, Pixels, !Window)
    pred draw_image(T, int, int, int, int, c_pointer, Window, Window),
    mode draw_image(in, in, in, in, in, in, di, uo) is det
%    pred matrix(T, matrix.matrix, Window, Window),
%    mode matrix(in, in, di, uo) is det

].

:- typeclass model_compiler(Renderer, Model) where [
    pred compile_wavefront(Renderer, wavefront.shape, Model),
    mode compile_wavefront(in, in, out) is det,
    pred compile_softshape(Renderer, softshape.shape3d, Model),
    mode compile_softshape(in, in, out) is det
].

:- typeclass model(Renderer, Model, Window)
    <= (render(Renderer, Window), model_compiler(Renderer, Model)) where [
    pred draw(Renderer, Model, Window, Window),
    mode draw(in, in, di, uo) is det
].

:- typeclass skybox(Renderer, Texture, Window)
    <= render(Renderer, Window) where [
    % draw(Renderer, Pitch, Yaw, Tex, !Window)
    pred draw_skybox(Renderer, float, float, Texture, Window, Window),
    mode draw_skybox(in, in, in, in, di, uo) is det
].

:- typeclass heightmap(Renderer, Heightmap, Texture, Window)
     <= render(Renderer, Window) where[
    pred draw_heightmap(Renderer, Heightmap, Texture, Window, Window),
    mode draw_heightmap(in, in, in, di, uo) is det
].

%==============================================================================%
:- implementation.
%==============================================================================%
