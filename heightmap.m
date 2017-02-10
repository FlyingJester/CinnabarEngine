:- module heightmap.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module model.
:- import_module list.

%------------------------------------------------------------------------------%

:- typeclass heightmap(T) where [
    pred get(T, int, int, float),
    mode get(in, in, in, out) is semidet,
    
    func w(T) = int,
    func h(T) = int
].

:- pred load(Heightmap::in, Model::in, list(Model)::out) is det
    <= (model.loadable(Model), heightmap(Heightmap)).

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module vector.
:- import_module float.
:- import_module int.

% Calculate the normal plane between the two points which is flat in the final
% dimension, and a given direction X/Y only) between those points.
% normal(CenterHeight, OtherHeight, DirectionBetween)
:- func normal(float, float, vector.vector3) = vector.vector3.
normal(Za, Zb, Normal0) = vector.cross(NormalCross, Normal1) :-
    vector.cross(Normal0, vector.vector(0.0, 0.0, 1.0), NormalCross),
    vector.add3(vector.vector(0.0, 0.0, Za - Zb), Normal0) = Normal1.

:- pragma inline(normal/3).

% \
:- func normal04 = vector.vector3.
normal04 = vector.vector(-0.7071068, 0.7071068, 0.0).
% |
:- func normal15 = vector.vector3.
normal15 = vector.vector(0.0, 1.0, 0.0).
% /
:- func normal26 = vector.vector3.
normal26 = vector.vector(0.7071068, 0.7071068, 0.0).
% -
:- func normal37 = vector.vector3.
normal37 = vector.vector(1.0, 0.0, 0.0).

% Calculates out all the normals for the triangle fan. This is all in one pred
% because DO IT! JUST DO IT!
:- pred normals(float, float, float, float, float, float, float, float, float,
    vector.vector3, vector.vector3, vector.vector3, vector.vector3,
    vector.vector3, vector.vector3, vector.vector3, vector.vector3).
:- mode normals(in, in, in, in, in, in, in, in, in,
    out, out, out, out, out, out, out, out) is det.
normals(V, V0, V1, V2, V3, V4, V5, V6, V7, 
    normal(V, V0, normal04),
    normal(V, V1, normal15),
    normal(V, V2, normal26),
    normal(V, V3, normal37),
    normal(V, V4, vector.negate3(normal04)),
    normal(V, V5, vector.negate3(normal15)),
    normal(V, V6, vector.negate3(normal26)),
    normal(V, V7, vector.negate3(normal37))).

% load(Heightmap, X, Y, W, H, !Model)
:- pred load(Heightmap::in, int::in, int::in, int::in, int::in,
    Model::in, list(Model)::in, list(Model)::out) is det
    <= (model.loadable(Model), heightmap(Heightmap)).

load(Heightmap, Model, Out) :-
    load(Heightmap, 0, 0, w(Heightmap), h(Heightmap), Model, [], Out).

% A bit disgusting. I spent some time thinking about using an abstracting type
% to represent the positional relatiosn between the points in the triangle fan,
% but that ended up being almost twice as much code and requiring a lot of work
% to work with integers and two different scale of floats.
load(Heightmap, X, Y, W, H, Blank, ModelsIn, ModelsOut) :-
    ( X >= W ->
        ( Y >= H ->
            ModelsOut = ModelsIn
        ;
            load(Heightmap, 0, Y+1, W, H, Blank, ModelsIn, ModelsOut)
        )
    ; ( get(Heightmap, X, Y, Value),
      get(Heightmap, X-1, Y-1, Value0),
      get(Heightmap, X+0, Y-1, Value1),
      get(Heightmap, X+1, Y-1, Value2),
      get(Heightmap, X+1, Y+0, Value3),
      get(Heightmap, X+1, Y+1, Value4),
      get(Heightmap, X+0, Y+1, Value5),
      get(Heightmap, X-1, Y+1, Value6),
      get(Heightmap, X-1, Y+0, Value7) )->
        normals(Value,
            Value0, Value1, Value2, Value3, Value4, Value5, Value6, Value7,
            Normal0, Normal1, Normal2, Normal3, Normal4, Normal5, Normal6, Normal7),
        FX = float(X), FY = float(Y),
        MP = vector.midpoint3(Pt),
        Pt = vector.vector(FX, Value, FY),
        Pt0 = vector.vector(FX-1.0, Value0, FY-1.0),
        Pt1 = vector.vector(FX+0.0, Value1, FY-1.0),
        Pt2 = vector.vector(FX+1.0, Value2, FY-1.0),
        Pt3 = vector.vector(FX+1.0, Value3, FY+0.0),
        Pt4 = vector.vector(FX+1.0, Value4, FY+1.0),
        Pt5 = vector.vector(FX+0.0, Value5, FY+1.0),
        Pt6 = vector.vector(FX-1.0, Value6, FY+1.0),
        Pt7 = vector.vector(FX-1.0, Value7, FY+0.0),
        BaseNormal = model.normal(
          vector.add3(
            vector.add3(Pt1, Pt3),
            vector.add3(Pt5, Pt7)
          )
        ),
        model.next(model.vertex(model.point(Pt), model.tex(0.5, 0.5), BaseNormal), Blank, ModelBase),
        V0 = model.vertex(model.point(MP(Pt0)), model.tex(0.0, 0.0), model.normal(Normal0)),
        model.next(V0, ModelBase, Model0),
        V1 = model.vertex(model.point(MP(Pt1)), model.tex(0.5, 0.0), model.normal(Normal1)),
        model.next(V1, Model0, Model1),
        V2 = model.vertex(model.point(MP(Pt2)), model.tex(1.0, 0.0), model.normal(Normal2)),
        model.next(V2, Model1, Model2),
        V3 = model.vertex(model.point(MP(Pt3)), model.tex(1.0, 0.5), model.normal(Normal3)),
        model.next(V3, Model2, Model3),
        V4 = model.vertex(model.point(MP(Pt4)), model.tex(1.0, 1.0), model.normal(Normal4)),
        model.next(V4, Model3, Model4),
        V5 = model.vertex(model.point(MP(Pt5)), model.tex(0.5, 1.0), model.normal(Normal5)),
        model.next(V5, Model4, Model5),
        V6 = model.vertex(model.point(MP(Pt6)), model.tex(0.0, 1.0), model.normal(Normal6)),
        model.next(V6, Model5, Model6),
        V7 = model.vertex(model.point(MP(Pt7)), model.tex(0.0, 0.5), model.normal(Normal7)),
        model.next(V7, Model6, Model7),
        load(Heightmap, X+1, Y, W, H, Blank, [Model7|ModelsIn], ModelsOut)
    ;
        load(Heightmap, X+1, Y, W, H, Blank, ModelsIn, ModelsOut)
    ).
