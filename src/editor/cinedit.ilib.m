:- module cinedit.ilib.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module ilib.
:- import_module list.

:- type item_library == list(ilib.item).

:- func create_item(string) = ilib.item.
:- func item_name(ilib.item) = string.
:- pred add_item(ilib.item::in, item_library::in, item_library::out) is det.
:- pred remove_item(int::in, item_library::in, item_library::out) is semidet.
:- pred remove_item(int::in, item_library::in, item_library::in, item_library::out) is semidet.

:- pred get_item(int::in, item_library::in, ilib.item::out) is semidet.
:- pred replace_item(int::in, item_library::in, ilib.item::in, item_library::out) is semidet.
:- pred replace_item(int::in, item_library::in, item_library::in, ilib.item::in, item_library::out) is semidet.

:- pred save_ilib(string::in, item_library::in, io.res::out, io.io::di, io.io::uo) is det.
:- pred load_ilib(string::in, io.res(item_library)::out, io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module int.
:- use_module string.

:- use_module bufferfile.
:- use_module buffer.

:- pragma foreign_export("C", item_name(in) = out, "CinEdit_M_ItemName").
:- pragma foreign_export("C", create_item(in) = out, "CinEdit_M_CreateItem").
:- pragma foreign_export("C", add_item(in, in, out), "CinEdit_M_AddItem").
:- pragma foreign_export("C", remove_item(in, in, out), "CinEdit_M_RemoveItem").
:- pragma foreign_export("C", get_item(in, in, out), "CinEdit_M_GetItem").
:- pragma foreign_export("C", replace_item(in, in, in, out), "CinEdit_M_ReplaceItem").
:- pragma foreign_export("C", save_ilib(in, in, out, di, uo), "CinEdit_M_SaveIlib").
:- pragma foreign_export("C", load_ilib(in, out, di, uo), "CinEdit_M_LoadIlib").

:- pred lib_ok(io.res(item_library)::in, item_library::out) is semidet.
lib_ok(io.ok(Lib), Lib).
:- pred lib_err(io.res(item_library)::in, string::out) is semidet.
lib_err(io.error(Err), io.error_message(Err)).
:- pragma foreign_export("C", lib_ok(in, out), "CinEdit_M_GetLoadedIlib").
:- pragma foreign_export("C", lib_err(in, out), "CinEdit_M_GetLoadError").

:- pred save_error(io.res::in, string::out) is semidet.
save_error(io.error(Err), io.error_message(Err)).
:- pragma foreign_export("C", save_error(in, out), "CinEdit_M_GetSaveError").

% Use consumable just because it is the easiest to initialize.
create_item(Name) =
    ilib.item(ilib.consumable(ilib.consumable), 100, "", "", Name, 1, 1).

item_name(ilib.item(_, _, _, _, Name, _, _)) = Name.

add_item(Item, List, list.reverse([Item|List])).

get_item(N, [Item|List], Out) :-
    N >= 0,
    ( N = 0 ->
        Out = Item
    ;
        get_item(N - 1, List, Out)
    ).

replace_item(N, LibIn, Item, Out) :-
    ( N =< 0 ->
        LibIn = [_|List],
        Out = [Item|List]
    ;
        replace_item(N, LibIn, [], Item, Out)
    ).

replace_item(N, [ItemIn|List], InList, Item, Out) :-
    ( N = 0 ->
        list.reverse(InList, RevList),
        list.append(RevList, [Item|List], Out)
    ;
        replace_item(N - 1, List, [ItemIn|InList], Item, Out)
    ).

remove_item(N, In, Out) :- remove_item(N, In, [], Out).

remove_item(0, [], !List).
remove_item(N, [Item|List], InList, Out) :-
    N >= 0,
    ( N = 0 ->
        list.reverse(InList, RevList),
        list.append(RevList, List, Out)
    ;
        remove_item(N - 1, List, [Item|InList], Out)
    ).

:- pred save_ilib_v1(item_library::in, io.io::di, io.io::uo) is det.
save_ilib_v1([], !IO).
save_ilib_v1([Item|List], !IO) :-
    ilib.write_item(Item, !IO),
    save_ilib_v1(List, !IO).

save_ilib(Path, Lib, Res, !IO) :-
    io.open_binary_output(Path, StreamResult, !IO),
    (
        StreamResult = io.error(Err),
        Res = io.error(Err)
    ;
        StreamResult = io.ok(Stream),
        io.write_byte(Stream, 105, !IO), % i
        io.write_byte(Stream, 108, !IO), % l
        io.write_byte(Stream, 105, !IO), % i
        io.write_byte(Stream, 98, !IO),  % b
        io.write_byte(Stream, 1, !IO), % version
        io.write_byte(Stream, 0xFF, !IO), % reserved
        
        list.length(Lib, N),
        io.write_byte(Stream, N /\ 0xFF, !IO), % Write the length...
        io.write_byte(Stream, unchecked_right_shift(N, 8) /\ 0xFF, !IO),

        % Reserved area....
        io.write_byte(Stream, 0, !IO), io.write_byte(Stream, 0, !IO),
        io.write_byte(Stream, 0, !IO), io.write_byte(Stream, 0, !IO),
        io.write_byte(Stream, 0, !IO), io.write_byte(Stream, 0, !IO),
        io.write_byte(Stream, 0, !IO), io.write_byte(Stream, 0, !IO),
        io.set_binary_output_stream(Stream, OldStream, !IO),
        save_ilib_v1(Lib, !IO),
        io.flush_binary_output(!IO),
        io.set_binary_output_stream(OldStream, _, !IO),
        io.close_binary_output(Stream, !IO),
        Res = io.ok
    ).

:- pred load_ilib_v1(buffer.buffer::in, int::in, int::in, int::in, item_library::in, io.res(item_library)::out) is det.
load_ilib_v1(Buffer, Total, N, Index, LibIn, Result) :-
    ( N = 0 ->
        list.reverse(LibIn, LibOut),
        Result = io.ok(LibOut)
    ;
        ( ilib.read_item(Buffer, Index, NewIndex, Item) ->
            load_ilib_v1(Buffer, Total, N - 1, NewIndex, [Item|LibIn], Result)
        ;
            Result = io.error(io.make_io_error(string.format(
                "Invalid item %i", [string.i(Total - N)|[]])))
        )
    ).

load_ilib(Path, Out, !IO) :-
    bufferfile.open(Path, MaybeFile, !IO),
    (
        MaybeFile = io.error(Err),
        Out = io.error(Err)
    ;
        MaybeFile = io.ok(File),
        ( bufferfile.size(File) >= 16 ->
            bufferfile.map(File, bufferfile.size(File), Buffer),
            ( buffer.get_native_8(Buffer, 0, 105),  % i
              buffer.get_native_8(Buffer, 1, 108),  % l
              buffer.get_native_8(Buffer, 2, 105),  % i
              buffer.get_native_8(Buffer, 3, 98) -> % b
                ( buffer.get_native_8(Buffer, 4, 1) ->
                    buffer.get_native_16(Buffer, 6, N),
                    load_ilib_v1(Buffer, N, N, 16, [], Out)
                ;
                    Out = io.error(io.make_io_error("Invalid version"))
                )
            ;
                Out = io.error(io.make_io_error("Invalid signature"))
            )
        ;
            Out = io.error(io.make_io_error("Invalid file (too small)"))
        )
    ).
