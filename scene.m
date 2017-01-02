:- module scene.
%==============================================================================%
% Scene Graph implementation.
% See scene.node_tree for the actual graph implementation, and scene.matrix_tree
% for the handling of transformations on the nodes. The main module here handles
% drawing the scene in terms of a renderer.
:- interface.
%==============================================================================%

:- use_module render.
:- use_module camera.
:- use_module mglow.
%------------------------------------------------------------------------------%

:- include_module scene.matrix_tree.
:- include_module scene.node_tree.

:- use_module scene.matrix_tree.
:- use_module scene.node_tree.
%------------------------------------------------------------------------------%

:- type scene(Model, Texture) --->
    scene(scene.matrix_tree.matrix_tree,
        scene.node_tree.node(Model),
        camera.camera, skybox::Texture).
%------------------------------------------------------------------------------%

% Recursively draws all nodes in the tree.
:- pred draw(
    scene.matrix_tree.matrix_tree::in,
    scene.node_tree.node(Model)::in,
    Render::in, mglow.window::di, mglow.window::uo) is det
      <= (render.model(Render, Model)).

:- pred draw(scene(Model, Texture)::in, Render::in,
    mglow.window::di, mglow.window::uo) is det <=
        (render.model(Render, Model), render.skybox(Render, Texture)).

% Similar to draw. First applies the given transformation without pushing
% matrices on the renderer, and will pass any further transfom nodes into 
% another call to apply_transformation. This is an optimization to use a 
% single matrix stack entry to handle multiple transformations in a row.
:- pred apply_transformation_and_draw(scene.matrix_tree.matrix_tree::in,
    Render::in, scene.matrix_tree.transformation::in,
    scene.node_tree.node(Model)::in, mglow.window::di, mglow.window::uo) is det
      <= render.model(Render, Model).

% Translates scene.matrix_tree.transformation types into calls to render
% typeclass predicates.
:- pred apply_transformation(scene.matrix_tree.transformation::in, Render::in,
    mglow.window::di, mglow.window::uo) is det <= render.render(Render).

%==============================================================================%
:- implementation.
%==============================================================================%

apply_transformation_and_draw(Tree, Render, Transformation, Node, !Window) :-
    apply_transformation(Transformation, Render, !Window),
    ( Node = scene.node_tree.transform(NextTransformation, NextNode) ->
        apply_transformation_and_draw(Tree,
            Render, NextTransformation, NextNode, !Window)
    ;
        draw(Tree, Node, Render, !Window)
    ).

draw(Tree, scene.node_tree.transform(Transformation, Node), Render, !Window) :-
    render.push_matrix(Render, !Window),
    apply_transformation_and_draw(Tree, Render, Transformation, Node, !Window),
    render.pop_matrix(Render, !Window).

draw(_, scene.node_tree.model(Model), Render, !Window) :-
    render.draw(Render, Model, !Window).

draw(Tree, scene.node_tree.group(NodeA, NodeB), Render, !Window) :-
    draw(Tree, NodeA, Render, !Window),
    draw(Tree, NodeB, Render, !Window).

draw(scene(MatrixTree, NodeTree, Camera, Skybox), Render, !Window) :-
    Pitch = Camera ^ camera.pitch,
    Yaw = Camera ^ camera.yaw,
    render.draw_skybox(Render, Pitch, Yaw, Skybox, !Window),
    render.push_matrix(Render, !Window),
    render.rotate_x(Render, Pitch, !Window),
    render.rotate_y(Render, Yaw,   !Window),
    X = Camera ^ camera.x, Y = Camera ^ camera.y, Z = Camera ^ camera.z,
    render.translate(Render, X, Y, Z, !Window),
    
    % If the first node is a transformation, we can avoid another matrix stack
    % manipulation and just ride on the push and pop in this outer function.
    ( NodeTree = scene.node_tree.transform(Transformation, Node) ->
        apply_transformation(Transformation, Render, !Window),
        draw(MatrixTree, Node, Render, !Window)
    ;
        draw(MatrixTree, NodeTree, Render, !Window)
    ),
    render.pop_matrix(Render, !Window).

% TODO
apply_transformation(scene.matrix_tree.scale(_, _, _), _, !Window).
% TODO
apply_transformation(scene.matrix_tree.matrix(_), _, !Window).

apply_transformation(scene.matrix_tree.translate(X, Y, Z), Render, !Window) :-
    render.translate(Render, X, Y, Z, !Window).

apply_transformation(scene.matrix_tree.rotate_x(A), Render, !Window) :-
    render.rotate_x(Render, A, !Window).

apply_transformation(scene.matrix_tree.rotate_y(A), Render, !Window) :-
    render.rotate_y(Render, A, !Window).

apply_transformation(scene.matrix_tree.rotate_z(A), Render, !Window) :-
render.rotate_z(Render, A, !Window).