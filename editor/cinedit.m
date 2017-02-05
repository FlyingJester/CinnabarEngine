:- module cinedit.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.

:- include_module cinedit.ilib.
:- include_module cinedit.clib.
:- include_module cinedit.cell.

:- use_module ilib.

:- pred main(io.io::di, io.io::uo) is det.
:- type window.
:- type state ---> ok ; end.

:- type editor.

:- pred begin(window::uo, io.io::di, io.io::uo) is det.
:- pred run(window::di, window::uo, editor::in, io.io::di, io.io::uo) is det.
:- pred end(window::di, io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module cinedit.ilib.
:- use_module cinedit.clib.
:- use_module cinedit.cell.

:- import_module list.

:- use_module aimg.

:- pragma foreign_decl("C", "enum CinEdit_EnumState { eCESOK, eCESEnd }; ").
:- pragma foreign_decl("C", "#include ""aimg.mh"" ").
:- pragma foreign_enum("C", state/0, [ok - "eCESOK", end - "eCESEnd"]).
:- pragma foreign_import_module("C", cinedit.ilib).
:- pragma foreign_decl("C", "#include ""cinedit_fltk_glue.h"" ").
:- pragma foreign_decl("C", "#include ""ilib_ui.h"" ").
:- pragma foreign_type("C", window, "void*").

:- type editor --->
    editor(ilib::cinedit.ilib.item_library).

:- func get_ilib(editor) = cinedit.ilib.item_library.
get_ilib(E) = E ^ ilib.

:- func create_ilib(cinedit.ilib.item_library) = editor.
create_ilib(L) = editor(L).

:- pragma foreign_export("C", get_ilib(in) = out, "CinEdit_M_GetIlib").
:- pragma foreign_export("C", create_ilib(in) = out, "CinEdit_M_CreateEditor").

:- pred wait(window::di, window::uo, editor::in, editor::out, state::uo, io.io::di, io.io::uo) is det.
:- pragma foreign_proc("C", wait(W0::di, W1::uo, E0::in, E1::out, S::uo, IO0::di, IO1::uo),
    [may_call_mercury, promise_pure, thread_safe],
    "
        CinEdit_SetIlib(CinEdit_M_GetIlib(E0));
        if(CinEdit_FlWait()){
            S = eCESOK;
        }
        else{
            S = eCESEnd;
        }
        MR_Word I = CinEdit_GetIlib();
        E1 = CinEdit_M_CreateEditor(I);
        W1 = W0;
        IO1 = IO0;
    ").

:- pragma foreign_proc("C", begin(Window::uo, IO0::di, IO1::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure,
     thread_safe, tabled_for_io],
    "
        Window = CinEdit_CreateEditorWindow();
        IO1 = IO0;
    ").

:- pragma foreign_proc("C", end(Window::di, IO0::di, IO1::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure,
     thread_safe, tabled_for_io],
    "
        CinEdit_DestroyEditorWindow(Window);
        IO1 = IO0;
    ").

run(!Window, Editor, !IO) :-
    wait(!Window, Editor, NewEditor, State, !IO),
    (
        State = ok,
        run(!Window, NewEditor, !IO)
    ;
        State = end
    ).

main(!IO) :-
    begin(WindowIn, !IO),
    Editor = editor([]),
    run(WindowIn, WindowOut, Editor, !IO),
    end(WindowOut, !IO).
