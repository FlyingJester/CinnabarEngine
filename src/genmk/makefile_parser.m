:- module makefile_parser.
%==============================================================================
% Reads a makefile just enough to determine what the names of the targets are.
% Only works on single-file targets with non-macro names.
:- interface.
%==============================================================================

:- import_module string.
:- import_module list.
:- use_module io.

:- pred targets(list(string)::uo, io.io::di, io.io::uo) is det.
:- pred targets(list(string)::di, list(string)::uo, io.io::di, io.io::uo) is det.

%==============================================================================
:- implementation.
%==============================================================================

:- use_module maybe.

:- pred namebreaker(character::in) is semidet.
namebreaker('\t').
namebreaker('\n').
namebreaker('\r').
namebreaker('\v').
namebreaker('$').
namebreaker('#').
namebreaker('%').
namebreaker(')').
namebreaker('(').
namebreaker('!').
namebreaker('=').
namebreaker('+').
namebreaker(':').

:- pred parse_target_name(list(character)::in, maybe.maybe(string)::uo, io.io::di, io.io::uo) is det.
parse_target_name(In, Out, !IO) :-
    io.read_char(CharResult, !IO),
    (
        CharResult = io.ok(Char),
        ( Char = ' ' ->
            parse_target_name(In, Out, !IO)
        ; namebreaker(Char) ->
            string.from_rev_char_list(In, Str),
            Out = maybe.yes(Str)
        ;
            parse_target_name([Char|In], Out, !IO)
        )
    ;
        CharResult = io.eof,
        string.from_rev_char_list(In, Str),
        Out = maybe.yes(Str)
    ;
        CharResult = io.error(_),
        Out = maybe.no
    ).


targets(Out, !IO) :- targets([], Out, !IO).
targets(ListIn, ListOut, !IO) :-
    io.read_char(CharResult, !IO),
    ( CharResult = io.ok(Char) ->
        ( Char = ('\n') ->
            parse_target_name([], MaybeTarget, !IO),
            ( MaybeTarget = maybe.yes(Target) ->
                targets([Target|ListIn], ListOut, !IO)
            ;
                targets(ListIn, ListOut, !IO)
            )
        ;
            targets(ListIn, ListOut, !IO)
        )
    ;
        ListOut = ListIn
    ).
