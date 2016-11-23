:- module audio.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
%------------------------------------------------------------------------------%

:- type sound.
:- type context.
%------------------------------------------------------------------------------%

:- pred create_context(io.io::di, io.io::uo, context::uo) is det.
:- pred destroy_context(io.io::di, io.io::uo, context::uo) is det.

:- type result ---> ok(sound) ; error.

% Loads a sound
:- pred load_sound(context::di, context::uo,
    io.io::di, io.io::uo,
    string::in, result::uo) is det.

:- pred destroy_sound(context::di, context::uo, sound::di) is det.

:- pred play_sound(io.io::di, io.io::uo, sound::di, sound::uo) is det.
:- pred stop_sound(io.io::di, io.io::uo, sound::di, sound::uo) is det.
:- pred pause_sound(io.io::di, io.io::uo, sound::di, sound::uo) is det.
:- pred rewind_sound(io.io::di, io.io::uo, sound::di, sound::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module mfile.
:- use_module mopenal.
:- use_module mogg.
:- use_module mopus.
:- use_module bool.
%------------------------------------------------------------------------------%

:- type sound == mopenal.source.

:- type context ---> context(mopenal.device, mopenal.context).


:- func samplerate = (int).
samplerate = (48000).

create_context(!IO, context(Dev, Ctx)) :-
    mopenal.open_device(!IO, DevI),
    mopenal.create_context(DevI, Dev, Ctx0),
    mopenal.position(Ctx0, Ctx1, 0.0, 0.0, 0.0),
    mopenal.velocity(Ctx1, Ctx2, 0.0, 0.0, 0.0),
    mopenal.orientation(Ctx2, Ctx,  0.0, 0.0, 0.0).

destroy_context(!IO, context(DevIn, Ctx)) :-
    mopenal.destroy_context(DevIn, Dev, Ctx),
    mopenal.close_device(!IO, Dev).

:- pred push_stream(mopenal.context::di, mopenal.context::uo,
    mopenal.source::di, mopenal.source::uo,
    mogg.sync::mdi, mogg.sync::muo,
    mogg.page::mdi, mogg.page::muo,
    mogg.stream::mdi, mogg.stream::muo,
    mopus.decoder::mdi, mopus.decoder::muo) is det.

push_stream(!Ctx, !Src, !State, !Page, !Stream, !Decoder) :-
    ( mogg.packetout(!Stream, Packet) ->
        mogg.packet_to_buffer(Packet, PacketBuffer),
        mopus.decode(!Decoder, PacketBuffer, 23040, Buffer, _),
        mopenal.generate_buffer(!Ctx, ALBuffer),
        mopenal.buffer_data(!Ctx, ALBuffer, ALBufferOut, Buffer, samplerate),
        mopenal.queue_buffer(!Ctx, !Src, ALBufferOut),
        push_stream(!Ctx, !Src, !State, !Page, !Stream, !Decoder)
    ;
        _ = samplerate
    ).

:- pred load_sound(mopenal.context::di, mopenal.context::uo, sound::di, sound::uo,
    io.io::di, io.io::uo, mfile.file::di, mfile.file::uo,
    mopus.decoder::di, mogg.sync::di) is det.

load_sound(context(Dev, CtxIn), context(Dev, CtxOut), !IO, Path, Output) :-
    mfile.open(!IO, Path, Res),
    (
        Res = mfile.error,
        Output = error
    ;
        Res = mfile.ok(File),
        
        ( mopus.init_decoder(samplerate, Decoder) ->    
            mogg.init_stream(mogg.sync_init, Sync), 
            mopenal.generate_sources(CtxIn, CtxMid, Source),
            load_sound(CtxMid, CtxOut,
                Source, Output, !IO, File, FileEnd, Decoder, Sync)
        ;
            Output = error,
            CtxOut = CtxIn
        ),
        mfile.close(!IO, FileEnd)
    ).
