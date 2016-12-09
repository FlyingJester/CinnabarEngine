:- module wavefront.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
:- import_module list.
:- use_module model.

%------------------------------------------------------------------------------%
:- type point == model.point.
:- type normal == model.normal.
:- type tex == model.tex.
:- type vertex ---> vertex(vert_index::int, tex_index::int).
:- type face ---> face(list(vertex)).

%------------------------------------------------------------------------------%
:- typeclass model(Model) where [
    pred putpoint(model.point::in, Model::in, Model::out) is det,
    pred puttex(model.tex::in, Model::in, Model::out) is det,
    pred putnormal(model.normal::in, Model::in, Model::out) is det,
    % Specifies a model with an added face.
    % face(Vert, Tex, In, Out)
    pred putface(face::in, Model::in, Model::out) is det
].

%------------------------------------------------------------------------------%
% A generic shape type used either as an intermediate form or for testing.
% Can also be used when full-software processing is appropriate.
:- type shape --->
    shape(vertices::list(model.point),
        tex_coords::list(model.tex),
        normals::list(model.normal),
        faces::list.list(face)).

:- pred write_vertex(vertex::in, io.io::di, io.io::uo) is det.
:- pred write_point(model.point::in, io.io::di, io.io::uo) is det.

%------------------------------------------------------------------------------%
:- instance model(shape).

:- func init_shape = shape.

:- pred load(string::in, T::in, T::out) is det <= model(T).

%==============================================================================%
:- implementation.
%==============================================================================%

:- instance model(shape) where [
    (putpoint(Point, shape(Points, Tex, Nmls, Faces), shape(Out, Tex, Nmls, Faces)) :-
        list.append(Points, [Point|[]], Out)),
    (puttex(TexCoord, shape(Points, Tex, Nmls, Faces), shape(Points, Out, Nmls, Faces)) :-
        list.append(Tex, [TexCoord|[]], Out)),
    (putnormal(Normal, shape(Points, Tex, Nmls, Faces), shape(Points, Tex, Out, Faces)) :-
        list.append(Nmls, [Normal|[]], Out)),
    putface(Face, shape(Points, Tex, Nmls, Faces), shape(Points, Tex, Nmls, [Face | Faces]))
].

init_shape = shape([], [], [], []).

:- use_module string.
:- import_module char.
:- import_module int.
:- import_module float.

:- type cinparser ---> cinparser(src::string, at::int, len::int).
:- func cinparser(string) = cinparser.
cinparser(Src) = cinparser(Src, 0, string.length(Src)).

:- pred remaining(cinparser::in) is semidet.
remaining(P) :- P ^ at < P ^ len.

:- pred get(cinparser::in, cinparser::out, char::out) is semidet.
get(cinparser(Src, At, Len), cinparser(Src, At + 1, Len), Char) :-
    string.index(Src, At, Char).

:- pred find_newline(cinparser::in, cinparser::out) is det.
find_newline(!Parser) :-
    ( get(!Parser, Char), not Char = '\n' ->
        find_newline(!Parser)
    ;
        true % Pass
    ).

:- pred skip_whitespace(cinparser::in, cinparser::out) is det.
skip_whitespace(!Parser) :-
    ( get(!Parser, Char), (Char = ' ' ; Char = '\t') ->
        skip_whitespace(!Parser)
    ;
        true % Pass
    ).

:- pred is_numeric(char::in) is semidet.
is_numeric('0').
is_numeric('1').
is_numeric('2').
is_numeric('3').
is_numeric('4').
is_numeric('5').
is_numeric('6').
is_numeric('7').
is_numeric('8').
is_numeric('9').

:- pred skip_number(cinparser::in, cinparser::out) is det.
skip_number(!Parser) :-
    ( get(!Parser, Char), ( is_numeric(Char) ; Char = ('.') ; Char = ('-')) ->
        skip_number(!Parser)
    ;
        true % Pass
    ).

:- pred get_number(pred(string, T), T, cinparser, cinparser, T).
:- mode get_number(pred(in, out) is semidet, in, in, out, out) is det.
get_number(Parse, Default, Cin, cinparser(Src, End, Len), Num) :-
    Cin = cinparser(Src, At, Len),
    skip_number(Cin, cinparser(_, End, _)),
    string.between(Src, At, End, Str),
    ( Parse(Str, X) ->
        Num = X
    ;
        Num = Default
    ).

:- pred skip_to_whitespace(cinparser::in, cinparser::out) is det.
skip_to_whitespace(Cin, Out) :-
    Cin = cinparser(Src, At, Len),
    ( string.index(Src, At, Char), ( Char = ' ' ; Char = '\t' ) ->
        Out = Cin
    ;
        skip_to_whitespace(cinparser(Src, At + 1, Len), Out)
    ).

:- pred accumulate_face(cinparser::in, cinparser::out, list(vertex)::in, list(vertex)::out) is det.
accumulate_face(!Parser, FaceIn, FaceOut) :-
    GetInt = get_number(string.to_int, 0), % Create a curried pred for shorthand
    skip_whitespace(!Parser),
    ( get(!Parser, Char), ( Char = '\n' ; Char = '\v' ; Char = '#') ->
        FaceOut = FaceIn
    ;
        list.append(FaceIn, [vertex(V, T) |[]], FaceMid),
        GetInt(!Parser, V),
        ( get(!Parser, '/') ->
            GetInt(!Parser, T),
            ( get(!Parser, '/') -> % Skip any normal specification.
                GetInt(!Parser, _)
            ;
                true % Pass
            )
        ;
            T = 0
        ),
        accumulate_face(!Parser, FaceMid, FaceOut)
    ).

:- pred line(cinparser::in, cinparser::out, T::in, T::out) is det <= model(T).
line(!Parser, !Model) :-
    GetFloat = get_number(string.to_float, 0.0), % Create a curried pred for shorthand
    ( get(!Parser, Char) ->
        ( Char = 'v' ->
            ( get(!Parser, Char2) ->
                ( Char2 = 't' ->
                    skip_whitespace(!Parser),
                    GetFloat(!Parser, U),
                    skip_whitespace(!Parser),
                    GetFloat(!Parser, V),
                    puttex(model.tex(U, V), !Model)
                ; Char2 = 'n' ->
                    skip_whitespace(!Parser),
                    GetFloat(!Parser, X),
                    skip_whitespace(!Parser),
                    GetFloat(!Parser, Y),
                    skip_whitespace(!Parser),
                    GetFloat(!Parser, Z),
                    putnormal(model.normal(X, Y, Z), !Model)
                ;
                    skip_whitespace(!Parser),
                    GetFloat(!Parser, X),
                    skip_whitespace(!Parser),
                    GetFloat(!Parser, Y),
                    skip_whitespace(!Parser),
                    GetFloat(!Parser, Z),
                    putpoint(model.point(X, Y, Z), !Model)
                )
            ;
                skip_whitespace(!Parser),
                GetFloat(!Parser, X),
                skip_whitespace(!Parser),
                GetFloat(!Parser, Y),
                skip_whitespace(!Parser),
                GetFloat(!Parser, Z),
                putpoint(model.point(X, Y, Z), !Model)
            )
        ; Char = 'f' ->
            accumulate_face(!Parser, [], Face),
            ( Face = [] ->
                true % Pass
            ;
                putface(face(Face), !Model)
            )
        ;
            % On unknown char, just skip the line.
            true
        )
    ;
        true
    ),
    find_newline(!Parser).

:- pred load(cinparser::in, cinparser::out, T::in, T::out) is det <= model(T).
load(Src, !Model) :-
    load(cinparser(Src), _, !Model).

load(ParserIn, ParserOut, !Model) :-
    ( get(ParserIn, ParserAfterWhite, Char) ->
        ( ( Char = ' ' ; Char = '\t' ; Char = '\n' ; Char = '\r' ; Char = '\v' ) ->
            load(ParserAfterWhite, ParserOut, !Model)
        ; Char = '#' ->
            find_newline(ParserIn, ParserNextLine),
            load(ParserNextLine, ParserOut, !Model)
        ;
            line(ParserIn, ParserNextLine, !Model),
            load(ParserNextLine, ParserOut, !Model)
        )
    ;
        ParserIn = ParserOut
    ).

write_vertex(vertex(V, T), !IO) :-
    io.write_string("Vertex Index: ", !IO),
    io.write_int(V, !IO),
    io.write_string(" TexCoord Index: ", !IO),
    io.write_int(T, !IO).

write_point(model.point(X, Y, Z), !IO) :-
    io.write_string("X ", !IO),
    io.write_float(X, !IO),
    io.write_string("Y ", !IO),
    io.write_float(Y, !IO),
    io.write_string("Z ", !IO),
    io.write_float(Z, !IO).
