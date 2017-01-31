:- module mopus.
%==============================================================================%
% Bindings for the Opus audio codec reference implementation.
% This is partially tailored for Opus inside Ogg containers, as the decode preds
% will skip packets that start with the string "OpusTags", which is metadata in
% Ogg+Opus streams, and the init preds that accept buffers or binary input look
% for the "OpusHead" packet which is the first packet in Ogg+Opus streams.
:- interface.
%==============================================================================%

:- use_module io.
:- use_module maybe.
:- import_module pair.
:- use_module buffer.

%------------------------------------------------------------------------------%

:- type decoder.

% Shorthand
:- type io_input == io.binary_input_stream.

%------------------------------------------------------------------------------%

% TODO: Expose Opus error codes!

% Uses the first packet of an Ogg stream to initialize the decoder
% init(Packet, Decoder, NumChannels)
:- pred init(buffer.buffer::in, decoder::uo, int::uo) is semidet.

% Reads in the first packet of an Ogg stream to initialize the decoder
:- pred init(io_input, int, maybe.maybe(pair(decoder, int)), io.io, io.io).
:- mode init(in, in, uo, di, uo) is det.

% init2(SampleRate, Channels, Decoder, Channels).
:- pred init2(int::in, int::in, decoder::uo, int::uo) is semidet.

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

:- type error --->
    ok ;
    bad_arg ;
    buffer_too_small ;
    internal_error ;
    invalid_packet ;
    unimplemented ;
    invalid_state ;
    alloc_fail.

:- pragma foreign_decl("C", "#include ""buffer.mh"" ").
:- pragma foreign_import_module("C", buffer).
:- pragma foreign_import_module("C", io).
:- pragma foreign_decl("C", "#include <opus/opus.h>").
:- pragma foreign_decl("C", "struct MOpus_Decoder{OpusDecoder*dec;int nchan;};").

:- pragma foreign_enum("C", error/0,
    [ok - "OPUS_OK",
    bad_arg - "OPUS_BAD_ARG",
    buffer_too_small - "OPUS_BUFFER_TOO_SMALL",
    internal_error - "OPUS_INTERNAL_ERROR",
    invalid_packet - "OPUS_INVALID_PACKET",
    unimplemented - "OPUS_UNIMPLEMENTED",
    invalid_state - "OPUS_INVALID_STATE",
    alloc_fail - "OPUS_ALLOC_FAIL"]).

:- pragma foreign_decl("C", "const char *MOpus_NameError(int);").

:- pragma foreign_type("C", decoder, "struct MOpus_Decoder *").

:- pragma foreign_decl("C", "void MOpus_DecoderFinalizer(void *ptr, void *data);").
:- pragma foreign_code("C",
    "
    void MOpus_DecoderFinalizer(void *ptr, void *data){
        struct MOpus_Decoder *decoder = (struct MOpus_Decoder*)ptr;
        opus_decoder_destroy(decoder->dec);
    }
    ").

:- pragma foreign_code("C",
    "
    const char *MOpus_NameError(int err){
#define MOPUS_ERROR_CASE(WHAT) case OPUS_ ## WHAT: return #WHAT
        switch(err){
            MOPUS_ERROR_CASE(OK);
            MOPUS_ERROR_CASE(BAD_ARG);
            MOPUS_ERROR_CASE(BUFFER_TOO_SMALL);
            MOPUS_ERROR_CASE(INTERNAL_ERROR);
            MOPUS_ERROR_CASE(INVALID_PACKET);
            MOPUS_ERROR_CASE(UNIMPLEMENTED);
            MOPUS_ERROR_CASE(INVALID_STATE);
            MOPUS_ERROR_CASE(ALLOC_FAIL);
            default: return ""<UNKNOWN>"";
        }
#undef MOPUS_ERROR_CASE
    }
    ").

:- pragma foreign_export("C", decode_16(in, uo, di, uo), "MOpus_Decode16").
:- pragma foreign_export("C", decode_16(in, in, uo, di, uo, di, uo), "MOpus_Decode16IO").
:- pragma foreign_export("C", decode_float(in, uo, di, uo), "MOpus_DecodeFloat").
:- pragma foreign_export("C", decode_float(in, in, uo, di, uo, di, uo), "MOpus_DecodeFloatIO").

init(Input, Len, MaybeDecoder, !IO) :-
    buffer.read(Input, Len, MaybeBuffer, !IO),
    (
        MaybeBuffer = io.error(Buffer, Err),
        io.write_string("[MOpus] Read Error: ", !IO),
        io.write_string(io.error_message(Err), !IO),
        io.nl(!IO)
    ;
        MaybeBuffer = io.ok(Buffer)
    ),
    % Enough data for a head packet...
    ( init(Buffer, Decoder, C) ->
        MaybeDecoder = maybe.yes((Decoder - C))
    ;
        MaybeDecoder = maybe.no
    ).

:- pragma foreign_proc("C", init2(SampleRate::in, Chans::in, Out::uo, NChan::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        const unsigned size = sizeof(struct MOpus_Decoder) + opus_decoder_get_size(Chans);
        Out = MR_GC_malloc_atomic(size);
        Out->dec = (OpusDecoder*)(Out+1);
        Out->nchan = NChan = Chans;
        SUCCESS_INDICATOR = opus_decoder_init(Out->dec, SampleRate, Chans) == OPUS_OK;
    ").

:- pragma foreign_proc("C", init(Buffer::in, Out::uo, NChan::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        const char sig[] = ""OpusHead"";
        if(Buffer->size < 19){
#ifndef NDEBUG
            fputs(""[MOpus] Error: Buffer too small. Size is "", stderr);
            fprintf(stderr, ""%i\\n"", (int)Buffer->size);
#endif
            SUCCESS_INDICATOR = 0;
        }
        else if(memcmp(Buffer->data, sig, sizeof(sig)-1) != 0){
#ifndef NDEBUG
            unsigned i;
            fputs(""[MOpus] Error: Invalid signature in buffer of size "", stderr);
            fprintf(stderr, ""%i\\n"", (int)Buffer->size);
            fputs(""[MOpus] Error: Wanted "", stderr);
            for(i = 0; i < sizeof(sig) - 2; i++){
                fprintf(stderr, ""0x%X, "", sig[i]);
            }
            fprintf(stderr, ""0x%X\\n"", sig[7]);
            fputs(""[MOpus] Error: Got    "", stderr);
            for(i = 0; i < sizeof(sig) - 2; i++){
                fprintf(stderr, ""0x%X, "", ((unsigned char*)Buffer->data)[i]);
            }
            fprintf(stderr, ""0x%X\\n"", ((unsigned char*)Buffer->data)[7]);
            for(i = 0; i < 19; i++){
                fprintf(stderr, ""0x%X, "", ((unsigned char*)Buffer->data)[i]);
            }
#endif
            SUCCESS_INDICATOR = 0;
        }
        else{
            const unsigned char *const uchar_data = (unsigned char *)Buffer->data;
            const unsigned nchan = uchar_data[9];
            const unsigned ver = uchar_data[8];
            if(ver != 1 || nchan == 0 || nchan > 2){
#ifndef NDEBUG
                fputs(""[MOpus] Error: Invalid number of channels:"", stderr);
                fprintf(stderr, ""%i\\n"", nchan);
#endif
                SUCCESS_INDICATOR = 0;
            }
            else{ /* Very evil. Stash the decoder at the end of the struct. */
                const unsigned size = sizeof(struct MOpus_Decoder) + opus_decoder_get_size(nchan);
                Out = MR_GC_malloc_atomic(size);
                Out->dec = (OpusDecoder*)(Out+1);
                Out->nchan = nchan;

                {
                    const int err = opus_decoder_init(Out->dec, 48000, nchan);
                    if(err != OPUS_OK){
                        SUCCESS_INDICATOR = 0;
#ifndef NDEBUG
                        fputs(""[MOpus] Error: libopus error: "", stderr);
                        fputs(MOpus_NameError(err), stderr); fputc('\\n', stderr);
#endif
                        MR_GC_free(Out);
                        Out = NULL;
                    }
                    else{
                        SUCCESS_INDICATOR = 1;
                        NChan = nchan;
                        MR_GC_register_finalizer(Out, MOpus_DecoderFinalizer, NULL);
                    }
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
        buffer->size = 0;

        OpusDecoder *const dec = Decoder0->dec;

        if(!(In->size >= 8 && memcmp(In->data, ""OpusTags"", 8) == 0)){
            const int num =
                opus_decode(dec, In->data, In->size, buffer->data, max_samples, 0);
            if(num > 0)
                buffer->size = num * (nchan << 1);
        }
        
        Decoder1 = Decoder0;
        Out = buffer;
    ").

:- pragma foreign_proc("C", decode_16(Size::in, Out::uo, Decoder0::di, Decoder1::uo, IO0::di, IO1::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        struct M_Buffer buffer;
        buffer.size = Size;
        buffer.data = (Size < 8192) ? malloc(Size) : alloca(Size);
        MercuryFile *const stream = mercury_current_binary_input();
        buffer.size = MR_READ(*stream, buffer.data, Size);
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
        buffer->size = 0;

        OpusDecoder *const dec = Decoder0->dec;
        
        if(!(In->size >= 8 && memcmp(In->data, ""OpusTags"", 8) == 0)){
            const int num =
                opus_decode_float(dec, In->data, In->size, buffer->data, max_samples, 0);
            if(num > 0)
                buffer->size = num * (nchan << 2);
        }
        Decoder1 = Decoder0;
        Out = buffer;
    ").

:- pragma foreign_proc("C", decode_float(Size::in, Out::uo, Decoder0::di, Decoder1::uo, IO0::di, IO1::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        MercuryFile *const stream = mercury_current_binary_input();
        if(stream == NULL){
            struct M_Buffer *buffer = MR_GC_malloc_atomic(sizeof(struct M_Buffer));
            buffer->size = 0;
            Out = buffer;
        }
        else{
            struct M_Buffer buffer;
            char lbuffer[0xFF]; /* For small stuff, use the stack */
            buffer.size = Size;
            buffer.data = (Size > sizeof(lbuffer)) ? malloc(Size) : lbuffer;

            buffer.size = MR_READ(*stream, buffer.data, Size);
            MOpus_DecodeFloat(&buffer, &Out, Decoder0, &Decoder1);
            if(Size > sizeof(lbuffer))
                free(buffer.data);
        }
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
