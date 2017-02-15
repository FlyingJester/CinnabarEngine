:- module readdir.
%==============================================================================
% Implements an iterating interface to read the names of all files in a
% directory.
:- interface.
%==============================================================================

:- type readdir.

:- type result ---> more(readdir, size::int, path::string) ; end.

:- pred init(string::in, result::uo) is det.
:- pred next(readdir::di, result::uo) is det.

:- func result_more(readdir::di, int::di, string::di) = (result::uo) is det.
:- func result_end = (result::uo) is det.

%==============================================================================
:- implementation.
%==============================================================================

:- pragma foreign_type("C", readdir, "struct Lantern_FileFinder*").

result_more(R, S, P) = more(R, S, P).
result_end = end.

:- pragma foreign_export("C", result_more(di, di, di) = (uo), "Lantern_CreateResultMore").
:- pragma foreign_export("C", result_end = (uo), "Lantern_CreateResultEnd").

:- pragma foreign_proc("C", init(Path::in, Result::uo),
    [promise_pure, tabled_for_io, will_not_throw_exception],
    "
        struct Lantern_FileFinder *finder = MR_GC_malloc(Lantern_FileFinderSize());
        if(Lantern_InitFileFinder(finder, Path))
            Result = Lantern_CreateResultMore(finder,
                Lantern_FileFinderFileSize(finder),
                Lantern_FileFinderPath(finder));
        else
            Result = Lantern_CreateResultEnd();
    ").

:- pragma foreign_proc("C", next(Input::di, Result::uo),
    [promise_pure, tabled_for_io, will_not_throw_exception],
    "
        if(Lantern_FileFinderNext(Input))
            Result = Lantern_CreateResultMore(Input,
                Lantern_FileFinderFileSize(Input),
                Lantern_FileFinderPath(Input));
        else
            Result = Lantern_CreateResultEnd();
    ").

:- pragma foreign_decl("C", "#include ""readdir_h.h"" ").
:- pragma foreign_code("C", "#include ""readdir_c.c"" ").
