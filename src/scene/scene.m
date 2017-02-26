:- module scene.
%==============================================================================%
% Contains the implementation of a scene using the render backend.
:- interface.
%==============================================================================%

:- import_module list.
:- use_module io.
:- use_module render.

:- include_module scene.matrix_tree.
:- use_module scene.matrix_tree.

:- type node(Model) --->
    end ;
    group(node(Model), node(Model)) ;
    model(Model) ;
    transform(scene.matrix_tree.id, node(Model)).

:- type scene_light == {render.light, list(scene.matrix_tree.id)}.

% scene(Scene, Skybox, Lights, Heightmaps)
:- type scene(Model, Texture, Heightmap) --->
    scene(node(Model), Texture, list(scene_light), list({Heightmap, Texture})).

% Draws the skybox, applies all light data, draws all heightmaps, then
% recursively draws the scene.
:- pred draw(Render,
    scene(Model, Texture, Heightmap),
    scene.matrix_tree.matrix_tree,
    float, float, io.io, io.io)
    <= (render.render(Render),
        render.skybox(Render, Texture),
        render.model(Render, Model),
        render.heightmap(Render, Heightmap, Texture)).
:- mode draw(in, in, in, in, in, di, uo) is det.

% Recursively draws the scene.
:- pred draw(Render,
    node(Model),
    scene.matrix_tree.matrix_tree,
    io.io, io.io)
    <= (render.model(Render, Model), render.render(Render)).
:- mode draw(in, in, in, di, uo) is det.

:- pred draw_heightmap(Render, {Heightmap, Texture}, io.io, io.io)
    <= (render.heightmap(Render, Heightmap, Texture), render.render(Render)).
:- mode draw_heightmap(in, in, di, uo) is det.

:- pred lights(Render, list(scene_light), io.io, io.io)
    <= render.render(Render).
:- mode lights(in, in, di, uo) is det.

% Similar to draw. First applies the given transformation without pushing
% matrices on the renderer, and will pass any further transfom nodes into 
% another call to apply_transformation. This is an optimization to use a 
% single matrix stack entry to handle multiple transformations in a row.
:- pred apply_transformation_and_draw(Render::in,
    scene.matrix_tree.transformation::in,
    node(Model)::in,
    scene.matrix_tree.matrix_tree::in,
    io.io::di, io.io::uo) is det
    <= (render.model(Render, Model), render.render(Render)).

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module int.
:- use_module exception.

draw_heightmap(Render, {Heightmap, Texture}, !IO) :-
    render.draw_heightmap(Render, Heightmap, Texture, !IO).

:- pred lights(Render, int, list(scene_light), io.io, io.io)
    <= render.render(Render).
:- mode lights(in, in, in, di, uo) is det.

lights(Render, Lights, !IO) :- lights(Render, 0, Lights, !IO).

lights(_, _, [], !IO).
lights(Render, N, [{Light, _}|List], !IO) :-
    ( N < render.max_lights(Render) ->
        render.light(Render, N, Light, !IO),
        lights(Render, N-1, List, !IO)
    ;
        true % Pass.
    ).

draw(Render, scene(Scene, Skybox, Lights, Heightmaps), Tree, Pitch, Yaw, !IO) :-
    render.draw_skybox(Render, Pitch, Yaw, Skybox, !IO),
    lights(Render, Lights, !IO),
    foldl(draw_heightmap(Render), Heightmaps, !IO),
    draw(Render, Scene, Tree, !IO).

draw(_, end, _, !IO).
draw(Render, group(Node0, Node1), Tree, !IO) :-
    draw(Render, Node0, Tree, !IO), draw(Render, Node1, Tree, !IO).
draw(Render, model(Model), _, !IO) :- render.draw(Render, Model, !IO).
draw(Render, transform(TransformId, Node), Tree, !IO) :-
    ( scene.matrix_tree.find(TransformId, Tree, Transform) ->
        render.push_matrix(Render, !IO),
        apply_transformation_and_draw(Render, Transform, Node, Tree, !IO),
        render.pop_matrix(Render, !IO)
    ;
        exception.throw(exception.software_error("Invalid matrix ID"))
    ).
    
apply_transformation_and_draw(Render, Transformation, Node, Tree, !IO) :-
    (
        Transformation = scene.matrix_tree.scale(X, Y, Z),
        render.scale(Render, X, Y, Z, !IO)
    ;
        Transformation = scene.matrix_tree.translate(X, Y, Z),
        render.translate(Render, X, Y, Z, !IO)
    ;
        Transformation = scene.matrix_tree.rotate_x(A),
        render.rotate_x(Render, A, !IO)
    ;
        Transformation = scene.matrix_tree.rotate_y(A),
        render.rotate_y(Render, A, !IO)
    ;
        Transformation = scene.matrix_tree.rotate_z(A),
        render.rotate_z(Render, A, !IO)
    ),
    % Check if the next node is also a transformation, and apply it if so.
    ( Node = transform(NextTransformationId, NextNode) ->
        ( scene.matrix_tree.find(NextTransformationId, Tree, NextTransformation) ->
            apply_transformation_and_draw(Render, NextTransformation, NextNode, Tree, !IO)
        ;
            exception.throw(exception.software_error("Invalid matrix ID"))
        )
    ;
        draw(Render, Node, Tree, !IO)
    ).

