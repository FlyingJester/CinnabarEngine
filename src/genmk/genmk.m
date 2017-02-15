:- module genmk.
%==============================================================================
% Iterates through a list of directories, creating .mk files for the Mercury
% sources in each directory that are not listed in a test.mk file as a target
% for a tester.
:- interface.
%==============================================================================

:- use_module io.

:- pred main(io.io::di, io.io::uo) is det.
:- pred genmk(string::in, io.io::di, io.io::uo) is det.

%==============================================================================
:- implementation.
%==============================================================================

:- import_module list.
:- import_module int.
:- use_module string.
:- use_module maybe.
:- use_module exception.
:- use_module readdir.
:- use_module makefile_parser.

:- func path_append(string, string) = string.
path_append(A, B) = Out :-
    ( string.remove_suffix(A, "/", AC) ->
        ANoSlash = AC
    ;
        ANoSlash = A
    ),
    ( string.remove_prefix("/", B, BC) ->
        BNoSlash = BC
    ;
        BNoSlash = B
    ),
    Out = string.append(string.append(ANoSlash, "/"), BNoSlash).

:- pred collect_source_files(readdir.result::di, list(string)::out, maybe.maybe(string)::out) is det.

:- pred collect_source_files(readdir.result::di,
    list(string)::in, list(string)::out,
    maybe.maybe(string)::in, maybe.maybe(string)::out) is det.

collect_source_files(In, Files, Makefile) :- collect_source_files(In, [], Files, maybe.no, Makefile).

collect_source_files(readdir.end, !Files, !Makefile).
collect_source_files(readdir.more(Dir, _, Name), In, Out, !Makefile) :-
    readdir.next(Dir, Next),
    ( string.suffix(Name, "test.mk") ->
        collect_source_files(Next, In, Out, maybe.yes(Name), !:Makefile)
    ; string.remove_suffix(Name, ".m", Prefix) ->
        collect_source_files(Next, [Prefix|In], Out, !Makefile)
    ;
        collect_source_files(Next, In, Out, !Makefile)
    ).

:- pred filter_sources(list(string)::in, list(string)::in, list(string)::out) is det.
:- pred filter_sources(list(string)::in, list(string)::in, list(string)::in, list(string)::out) is det.

filter_sources(TestTargets, AllSource, OutSource) :- filter_sources(TestTargets, AllSource, [], OutSource).

filter_sources([], _, !Source).
filter_sources([_|_], [], !Source).
filter_sources(TestTargets, [Source|List], InSource, OutSource) :-
    TestTargets = [_|_],
    ( delete_first(TestTargets, Source, OtherTargets) ->
        filter_sources(OtherTargets, List, InSource, OutSource)
    ;
        filter_sources(TestTargets, List, [Source|InSource], OutSource)
    ).

:- pred find_final_slash(string::in, int::in, int::in, int::in, int::out) is det.
find_final_slash(Str, Len, Previous, At, Out) :-
    ( At + 1 >= Len ->
        Out = Previous
    ; string.unsafe_index(Str, At, ('/')) ->
        find_final_slash(Str, Len, At+1, At+1, Out)
    ;
        find_final_slash(Str, Len, Previous, At+1, Out)
    ).

:- pred write_source_file(string::in, string::in, io.io::di, io.io::uo) is det.
write_source_file(Path, Name, !IO) :-
    path_append(Path, string.append(Name, ".m ")) = File,
    io.write_string(File, !IO).

genmk(PathIn, !IO) :-
    string.replace_all(PathIn, ("\\"), ("/"), Path),
    string.length(Path, Len),
    find_final_slash(Path, Len, 0, 0, LastSlash),
    string.unsafe_between(Path, LastSlash, Len, Tail),
    readdir.init(Path, Dir),
    collect_source_files(Dir, AllSourceFiles, MaybeMakefile),
    ( MaybeMakefile = maybe.yes(Makefile) ->
        io.open_input(string.join_list("/", [Path|[Makefile|[]]]), StreamResult, !IO),
        (
            StreamResult = io.ok(Stream),
            io.set_input_stream(Stream, OldStream, !IO),
            makefile_parser.targets(Targets, !IO),
            io.set_input_stream(OldStream, _, !IO),
            filter_sources(Targets, AllSourceFiles, SourceFiles)
        ;
            StreamResult = io.error(SErr),
            exception.throw(exception.software_error(
                string.append("A test.mk file was detected, but could not be opened:",
                    io.error_message(SErr))))
        )
    ;
        SourceFiles = AllSourceFiles
    ),
    MakefilePath = path_append(Path, string.append(Tail, ".mk")),
    io.open_output(MakefilePath, MaybeOutput, !IO),
    (
        MaybeOutput = io.ok(Output),
        io.set_output_stream(Output, OldOutput, !IO),
        io.write_string(string.to_upper(Tail), !IO),
        io.write_string("_SRC= ", !IO),
        foldl(write_source_file(Tail), SourceFiles, !IO),
        io.set_output_stream(OldOutput, _, !IO)
    ;
        MaybeOutput = io.error(OErr),
        exception.throw(exception.software_error(
            string.append(string.append("Cannot open makefile ", MakefilePath),
                io.error_message(OErr))))
    ).

main(!IO) :-
    io.command_line_arguments(Args, !IO),
    foldl(genmk, Args, !IO).
    
