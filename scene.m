:- module scene.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module matrix.
:- use_module mglow.
:- use_module rbtree.
:- use_module renderer.
:- import_module list.

:- type matrixtree == rbtree.rbtree(int, matrix.matrix).

:- type node(Model) --->
    empty ;
    group(list.list(node(Model))) ;
    matrix(matrix_id::int, node(Model)) ;
    shader(renderer.shader, node(Model)) ;
    shape(Model).

:- func init_matrixtree = matrixtree.

:- pred draw(node(Model), matrix.matrix, matrixtree, Renderer,
    mglow.window, mglow.window) <= (renderer.model(Renderer, Model)).
:- mode draw(in, in, in, in, di, uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

init_matrixtree = rbtree.init.

draw(empty, _, _, _, !Window).

draw(group([]), _, _, _, !Window).
draw(group([Node|List]), Matrix, Tree, Renderer, !Window) :-
    draw(Node, Matrix, Tree, Renderer, !Window),
    draw(group(List), Matrix, Tree, Renderer, !Window).

draw(matrix(ID, Node), Matrix, Tree, Renderer, !Window) :-
    rbtree.lookup(Tree, ID, NewMatrix),
    draw(Node, matrix.multiply(Matrix, NewMatrix), Tree, Renderer, !Window).

draw(shape(Model), Matrix, _, Renderer, !Window) :-
    renderer.get_shader(Renderer, Shader, !Window),
    renderer.matrix(Matrix, Renderer, Shader, !Window),
    renderer.draw(Model, Renderer, !Window). 

draw(shader(Shader, Node), Matrix, Tree, Renderer, !Window) :-
    renderer.get_shader(Renderer, OldShader, !Window),
    renderer.set_shader(Renderer, RendererNew, Shader, !Window),
    draw(Node, Matrix, Tree, RendererNew, !Window),
    renderer.set_shader(RendererNew, _, OldShader, !Window).
