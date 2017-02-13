:- module audio_loader.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
:- use_module mopenal.

:- type input == io.binary_input_stream.

% load(Path, Ctx, Sound, !IO)
:- pred load(string, mopenal.context, io.res(mopenal.sound), io.io, io.io).
:- mode load(in, in, out, di, uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module maybe.
:- import_module pair.
:- import_module list.

:- use_module fjogg.
:- use_module mopus.
:- use_module buffer.

% Read in a page.
% Read out a packet.

:- pred read_page(input, mopenal.format, list(buffer.buffer),
    mopenal.loader, mopenal.loader,
    mopus.decoder, mopus.decoder, 
    io.io, io.io).
:- mode read_page(in, in, in, di, uo, di, uo, di, uo) is det.

:- pred read(input, mopenal.context, io.res(mopenal.sound), io.io, io.io).
:- mode read(in, in, out, di, uo) is det.

:- func format(mopenal.context, int) = mopenal.format.

% This one is a little ugly.
format(Ctx, NumChan) = Format :-
    ( mopenal.context_supports_float(Ctx) ->
        ( NumChan = 1 ->
            Format = mopenal.mono_float
        ;
            Format = mopenal.stereo_float
        )
    ;
        ( NumChan = 1 ->
            Format = mopenal.mono_16
        ;
            Format = mopenal.stereo_16
        )
    ).

load(Path, Ctx, Sound, !IO) :-
    io.open_binary_input(Path, InputResult, !IO),
    (
        InputResult = io.ok(Input),
        read(Input, Ctx, Sound, !IO)
    ;
        InputResult = io.error(Err),
        Sound = io.error(Err)
    ).

read(Input, Ctx, Result, !IO) :-
    fjogg.read_page(Input, PageResult, !IO),
    ( PageResult = io.ok(Page), fjogg.packet_out(Page, _, Size) ->
        mopus.init(Input, Size, MaybeDecoder, !IO),
        (
            MaybeDecoder = maybe.yes((Decoder - NumChan)),
            Format = format(Ctx, NumChan),
            mopenal.create_loader(Format, 48000, Ctx, LoaderIn, !IO),
            read_page(Input, Format, [], LoaderIn, LoaderOut, Decoder, _, !IO),
            mopenal.finalize(LoaderOut, Sound),
            Result = io.ok(Sound)
        ;
            MaybeDecoder = maybe.no,
            Result = io.error(io.make_io_error("Could not initialize Opus"))
        )
    ;
        Result = io.error(io.make_io_error("Invalid ogg file"))
    ).

:- pred read_from_page(input, mopenal.format, fjogg.page,
    list(buffer.buffer), list(buffer.buffer), 
    mopenal.loader, mopenal.loader,
    mopus.decoder, mopus.decoder, 
    io.io, io.io).
:- mode read_from_page(in, in, in, in, out, di, uo, di, uo, di, uo) is det.

% Shorthand just to allow us to use state variables for the lists.
:- pred append_list(list(buffer.buffer)::in,
    list(buffer.buffer)::in, list(buffer.buffer)::out) is det.
append_list(End, Start, Out) :- list.append(Start, End, Out).

% LastData is data from a continued packet on the last page, or nothing.
read_page(Input, Format, LastData, !Loader, !Decoder, !IO) :-
    fjogg.read_page(Input, PageResult, !IO),
    ( PageResult = io.ok(Page) ->
        read_from_page(Input, Format, Page, LastData, LeftOver, !Loader, !Decoder, !IO),
        % The last packet, if incomplete, is left for us to handle here.
        read_page(Input, Format, LeftOver, !Loader, !Decoder, !IO)
    ;
        true % Pass...TODO: Print error if Input is not empty.
    ).

read_from_page(Input, Format, PageIn, BufferIn, BufferOut, !Loader, !Decoder, !IO) :-
    ( fjogg.packet_out(PageIn, PageOut, Size) ->
        buffer.read(Input, Size, BufferResult, !IO),
        (
            BufferResult = io.ok(Buffer),
            ( fjogg.last_packet(PageOut) ->
                ( fjogg.packet_crosses_page(PageOut) ->
                    BufferOut = [Buffer|[]]
                ;
                    buffer.concatenate(BufferIn, AllBuffersIn),
                    buffer.append(AllBuffersIn, Buffer) = DataBuffer,
                    mopus.decode_16(DataBuffer, PCMBuffer, !Decoder),
                    mopenal.put_data(!Loader, PCMBuffer),
                    BufferOut = []
                )
            ;
                buffer.concatenate(BufferIn, AllBuffersIn),
                buffer.append(AllBuffersIn, Buffer, DataBuffer),
                (
                    (Format = mopenal.mono_16 ; Format = mopenal.stereo_16),
                    mopus.decode_16(DataBuffer, PCMBuffer, !Decoder)
                ;
                    (Format = mopenal.mono_float ; Format = mopenal.stereo_float),
                    mopus.decode_float(DataBuffer, PCMBuffer, !Decoder)                
                ),
                mopenal.put_data(!Loader, PCMBuffer),
                read_from_page(Input, Format, PageOut, [], BufferOut, !Loader, !Decoder, !IO)
            )
        ;
            BufferResult = io.error(_, Err),
            io.write_string("Error reading buffer ", !IO),
            io.write_string(io.error_message(Err), !IO),
            io.nl(!IO),
            BufferOut = []
        )
    ;
        BufferOut = []
    ).
