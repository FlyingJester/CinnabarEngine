:- module scene.node_tree.
%==============================================================================%
% Data type to handle the actual scene. It's simple because the actual node
% implemention is as simple as possible.
:- interface.
%==============================================================================%

:- use_module scene.matrix_tree.
%------------------------------------------------------------------------------%

% Scene graph tree structure.
% The types are:
%  - transform: Specifies a transformation that affects all of its child nodes.
%  - model: Leaf node which contains model data to draw.
%  - group: Expands to two nodes.
:- type node(Model) --->
    transform(scene.matrix_tree.transformation, node(Model)) ;
    model(Model) ;
    group(node(Model), node(Model)).

%==============================================================================%
:- implementation.
%==============================================================================%
