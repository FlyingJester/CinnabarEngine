:- module cell_load.
%==============================================================================%
% In-engine cell loader.
:- interface.
%==============================================================================%

:- use_module bufferfile.
:- use_module buffer.
:- import_module list.

:- type cell --->
    interior(i_ilibs::list(string),
        i_clibs::list(string),
        i_statics::list(cell.static) ;
    exterior(e_ilibs::list(string),
        e_clibs::list(string),
        e_statics::list(cell.static) ;
        heightmap::string).

:- pred load_cell(bufferfile.file, cell).
:- mode load_cell(in, out) is semidet.

:- pred load_cell(buffer.buffer, int, int, cell).
:- mode load_cell(in, in, out, out) is semidet.

:- func ilibs(cell) = list(string).
:- func clibs(cell) = list(string).
:- func statics(cell) = list(string).
:- func cell_type(cell) = cell.cell_type.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module char.
:- import_module int.

:- pred get_buffer_byte(buffer.buffer, int, int, int).
:- mode get_buffer_byte(in, in, out, out) is semidet.
:- mode get_buffer_byte(in, di, uo, out) is semidet.

:- pred load_statics(buffer.buffer, int, int, int, list(static), list(static)).
:- pred load_statics(in, in, in, out, in, out) is semidet.

:- pred load_libs(buffer.buffer, int, int, int, list(string), list(string)).
:- pred load_libs(in, in, in, out, in, out) is semidet.

get_buffer_byte(Buffer, N, N+1, Byte) :- buffer.get_8(Buffer, N, Byte).

load_statics(Buffer, N, !I, In, Out) :-
    N >= 0,
    ( N = 0 ->
        Out = In
    ;
        cell.read_static(Buffer, !I, Static),
        load_statics(Buffer, N-1, !I, [Static|In], Out)
    ).

load_libs(Buffer, N, !I, In, Out) :-
    N >= 0,
    ( N = 0 ->
        Out = In
    ;
        cell.read_lib(Buffer, !I, cell.lib(Str),
        load_libs(Buffer, N-1, !I, [Str|In], Out)
    ).

load_cell(File, Cell) :-
    bufferfile.map(File, Buffer),
    load_cell(Buffer, 0, _, Cell).

load_cell(Buffer, !I, Cell) :-
    get_buffer_byte(Buffer, !I, char.to_int('.')),
    get_buffer_byte(Buffer, !I, char.to_int('c')),
    get_buffer_byte(Buffer, !I, char.to_int('e')),
    get_buffer_byte(Buffer, !I, char.to_int('l')),
    cell.read_header(Buffer, !I,
        cell.header(CellX, CellY, CellType, NumClibs, NumIlibs, NumStatics, NumTriggers)),
    load_statics(Buffer, NumStatics, !I, [], Statics),
    load_libs(Buffer, NumIlibs, !I, [], Ilibs),
    load_libs(Buffer, NumClibs, !I, [], Clibs),
    (
        CellType = cell.interior,
        Cell = interior(Ilibs, Clibs, Statics)
    ;
        CellType = cell.exterior,
        read_heightmap(Buffer, !I, cell.heightmap(Heightmap)),
        Cell = exterior(Ilibs, Clibs, Statics, Heightmap)
    ).

ilibs(C) = C ^ i_ilibs.
ilibs(C) = C ^ e_ilibs.
clibs(C) = C ^ i_clibs.
clibs(C) = C ^ e_clibs.
statics(C) = C ^ e_statics.
statics(C) = C ^ i_statics.
cell_type(interior(_, _, _)) = cell.interior.
cell_type(exterior(_, _, _, _, _)) = cell.exterior.
