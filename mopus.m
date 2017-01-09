:- module mopus.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
:- use_module maybe.
:- use_module buffer.

%------------------------------------------------------------------------------%

:- type decoder.

% Shorthand
:- type io_input == io.binary_input_stream.

%------------------------------------------------------------------------------%

% init(SampleRate, Channels, Decoder).
:- pred init(int::in, int::in, decoder::uo) is semidet.

% Uses the first packet of an Ogg stream to initialize the decoder
:- pred init(buffer.buffer::in, decoder::uo) is semidet.

% Reads in the first packet of an Ogg stream to initialize the decoder
:- pred init(io_input, int, maybe.maybe(decoder), io.io, io.io).
:- mode init(in, in, uo, di, uo) is det.

% decode_16(EncodedInput, PCM16Output, !Decoder)
:- pred decode_16(buffer.buffer, buffer.buffer, decoder, decoder).
:- mode decode_16(in, uo, di, uo) is det.

:- pred decode_16(int, buffer.buffer, decoder, decoder, io.io, io.io).
:- mode decode_16(in, uo, di, uo, di, uo) is det.

:- pred decode_16(int, io_input, buffer.buffer, decoder, decoder, io.io, io.io).
:- mode decode_16(in, in, uo, di, uo, di, uo) is det.

% decode_float(EncodedInput, PCMFloatOutput, !Decoder)
:- pred decode_float(buffer.buffer, buffer.buffer, decoder, decoder).
:- mode decode_float(in, uo, di, uo) is det.

:- pred decode_float(int, buffer.buffer, decoder, decoder, io.io, io.io).
:- mode decode_float(in, uo, di, uo, di, uo) is det.

:- pred decode_float(int, io_input, buffer.buffer, decoder, decoder, io.io, io.io).
:- mode decode_float(in, in, uo, di, uo, di, uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module int.

:- pragma foreign_import_module("C", buffer).
:- pragma foreign_import_module("C", io).
:- pragma foreign_decl("C", "#include <opus/opus.h>").
:- pragma foreign_decl("C", "struct MOpus_Decoder{OpusDecoder*dec;int nchan;};").
:- pragma foreign_type("C", decoder, "struct MOpus_Decoder *").

:- pragma foreign_export("C", decode_16(in, uo, di, uo), "MOpus_Decode16").
:- pragma foreign_export("C", decode_16(in, uo, di, uo, di, uo), "MOpus_Decode16IO").
:- pragma foreign_export("C", decode_float(in, uo, di, uo), "MOpus_DecodeFloat").
:- pragma foreign_export("C", decode_float(in, uo, di, uo, di, uo), "MOpus_DecodeFloatIO").

init(Input, Len, MaybeDecoder, !IO) :-
    buffer.read(Input, Len, MaybeBuffer, !IO),
    (
        MaybeBuffer = io.error(Buffer, _)
    ;
        MaybeBuffer = io.ok(Buffer)
    ),
    % Enough data for a head packet...
    ( buffer.length(Buffer) >= 19, init(Buffer, Decoder) ->
        MaybeDecoder = maybe.yes(Decoder)
    ;
        MaybeDecoder = maybe.no
    ).

:- pragma foreign_proc("C", init(SampleRate::in, Chans::in, Out::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        const unsigned size = sizeof(struct MOpus_Decoder) + opus_decoder_get_size(Chans);
        Out = MR_GC_malloc_atomic(size);
        Out->dec = (OpusDecoder*)(Out+1);
        Out->nchan = Chans;
        SUCCESS_INDICATOR = opus_decoder_init(Out->dec, SampleRate, Chans) == OPUS_OK;
    ").

:- pragma foreign_proc("C", init(Buffer::in, Out::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        const char sig[] = ""OpusHead"";
        if(Buffer->size < 19 || memcmp(Buffer->data, sig, sizeof(sig)-1) != 0){
            SUCCESS_INDICATOR = 0;
        }
        else{
            const unsigned char *const uchar_data = (unsigned char *)Buffer->data;
            const unsigned nchan = uchar_data[9];
            const unsigned ver = uchar_data[8];
            if(ver != 1 || nchan == 0 || nchan > 2){
                SUCCESS_INDICATOR = 0;
            }
            else{ /* Very evil. Stash the decoder at the end of the struct. */
                const unsigned size = sizeof(struct MOpus_Decoder) + opus_decoder_get_size(nchan);
                Out = MR_GC_malloc_atomic(size);
                Out->dec = (OpusDecoder*)(Out+1);
                Out->nchan = nchan;
                SUCCESS_INDICATOR = opus_decoder_init(Out->dec, 48000, nchan) == OPUS_OK;
                if(!SUCCESS_INDICATOR){
                    MR_GC_free(Out);
                    Out = NULL;
                }
            }
        }
    ").

:- pragma foreign_proc("C", decode_16(In::in, Out::uo, Decoder0::di, Decoder1::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        const unsigned nchan = Decoder0->nchan;
        const unsigned max_samples =  5760 * nchan,
            max_bytes = max_samples << 1;
        struct M_Buffer *buffer = M_Buffer_Allocate(max_bytes);
        OpusDecoder *const dec = Decoder0->dec;
        const int num =
            opus_decode(dec, In->data, In->size, buffer->data, max_samples, 0);
        buffer->size = num * (nchan << 1);
        if(num < 0)
            buffer->size = 0;
        Decoder1 = Decoder0;
        Out = buffer;
    ").

:- pragma foreign_proc("C", decode_16(Size::in, Out::uo, Decoder0::di, Decoder1::uo, IO0::di, IO1::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        struct M_Buffer buffer;
        buffer.size = Size;
        buffer.data = (Size < 8192) ? malloc(Size) : alloca(Size);
        MercuryFile *const stream = mercury_current_binary_output();
        MR_READ(*stream, buffer.data, Size);
        MOpus_Decode16(&buffer, &Out, Decoder0, &Decoder1);
        if(Size < 8192)
            free(buffer.data);
        IO1 = IO0;
    ").

% Much slower since it needs to make a list of bytes as 32- or 64-bit ints, but
% doesn't need language backend.
decode_16(Size, Out, !Decoder, !IO) :-
    binary_input_stream(Stream, !IO),
    buffer.read(Stream, Size, MaybeBuffer, !IO),
    ( MaybeBuffer = io.error(Buffer, _) ; MaybeBuffer = io.ok(Buffer) ),
    decode_16(Buffer, Out, !Decoder).

decode_16(Size, Input, BufferOut, !Decoder, !IO) :-
    io.set_binary_input_stream(Input, OriginalInput, !IO),
    decode_16(Size, BufferOut, !Decoder, !IO),
    io.set_binary_input_stream(OriginalInput, _, !IO).

:- pragma foreign_proc("C", decode_float(In::in, Out::uo, Decoder0::di, Decoder1::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        const unsigned nchan = Decoder0->nchan;
        const unsigned max_samples =  5760 * nchan,
            max_bytes = max_samples << 2;
        struct M_Buffer *buffer = M_Buffer_Allocate(max_bytes);
        OpusDecoder *const dec = Decoder0->dec;
        const int num =
            opus_decode_float(dec, In->data, In->size, buffer->data, max_samples, 0);
        buffer->size = num * (nchan << 2);
        if(num < 0)
            buffer->size = 0;
        Decoder1 = Decoder0;
        Out = buffer;
    ").

:- pragma foreign_proc("C", decode_float(Size::in, Out::uo, Decoder0::di, Decoder1::uo, IO0::di, IO1::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        struct M_Buffer buffer;
        buffer.size = Size;
        buffer.data = (Size < 8192) ? malloc(Size) : alloca(Size);
        MercuryFile *const stream = mercury_current_binary_output();
        MR_READ(*stream, buffer.data, Size);
        MOpus_DecodeFloat(&buffer, &Out, Decoder0, &Decoder1);
        if(Size < 8192)
            free(buffer.data);
        IO1 = IO0;
    ").

% Much slower since it needs to make a list of bytes as 32- or 64-bit ints, but
% doesn't need language backend.
decode_float(Size, Out, !Decoder, !IO) :-
    binary_input_stream(Stream, !IO),
    buffer.read(Stream, Size, MaybeBuffer, !IO),
    ( MaybeBuffer = io.error(Buffer, _) ; MaybeBuffer = io.ok(Buffer) ),
    decode_float(Buffer, Out, !Decoder).

decode_float(Size, Input, BufferOut, !Decoder, !IO) :-
    io.set_binary_input_stream(Input, OriginalInput, !IO),
    decode_float(Size, BufferOut, !Decoder, !IO),
    io.set_binary_input_stream(OriginalInput, _, !IO).
