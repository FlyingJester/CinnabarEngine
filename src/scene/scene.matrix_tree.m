:- module scene.matrix_tree.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module matrix.
%------------------------------------------------------------------------------%

:- type transformation --->
    scale(float, float, float) ;
    translate(float, float, float) ;
    rotate_x(float) ;
    rotate_y(float) ;
    rotate_z(float).

%    matrix(matrix.matrix).

:- type matrix_tree.
:- type id == int.

%------------------------------------------------------------------------------%

:- func init = matrix_tree.

:- pred insert(transformation, matrix_tree, matrix_tree, id).
% :- mode insert(mdi, mdi, muo, uo) is semidet.
:- mode insert(in, in, out, uo) is semidet.

:- pred find(id, matrix_tree, transformation).
:- mode find(in, in, out) is semidet.
%:- mode find(in, mdi, muo) is semidet.

% :- pred find(id::in, matrix_tree::mdi, matrix_tree::muo, transformation::uo) is semidet.

:- pred remove(id, matrix_tree, matrix_tree).
:- mode remove(in, in, out) is semidet.
%:- mode remove(in, mdi, muo) is semidet.

:- pred remove_det(id, matrix_tree, matrix_tree).
:- mode remove_det(in, in, out) is det.
%:- mode remove_det(in, mdi, muo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module rbtree.
:- use_module counter.
:- import_module int.
%------------------------------------------------------------------------------%

:- type container == rbtree.rbtree(id, transformation).
:- type matrix_tree == {container, counter.counter}.
%------------------------------------------------------------------------------%

init = {rbtree.init, counter.init(1)}.

insert(That, {TreeIn, CounterIn}, {TreeOut, CounterOut}, ID+0) :-
    counter.allocate(ID, CounterIn, CounterOut),
    rbtree.insert(ID, That, TreeIn, TreeOut).

find(ID, {Tree, _}, Out) :- rbtree.search(Tree, ID, Out).

% TODO: If the ID was the last allocated, we may want to decrement the counter
%   to reuse the ID.
remove(ID, {TreeIn, Counter}, {TreeOut, Counter}) :-
    rbtree.remove(ID, _, TreeIn, TreeOut).

remove_det(ID, TreeIn, TreeOut) :-
    ( remove(ID, TreeIn, Tree) ->
        TreeOut = Tree
    ;
        TreeOut = TreeIn
).
