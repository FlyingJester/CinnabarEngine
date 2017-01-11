:- module maudio.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
%------------------------------------------------------------------------------%

:- type context.
:- type sound.
:- type load ---> ok(sound) ; badfile ; nofile ; internal_error.
%------------------------------------------------------------------------------%

:- func init_context = (context::uo) is det.
:- pred load(context::in, string::in, load::uo, io.io::di, io.io::uo) is det.

:- pred play(sound::in, io.io::di, io.io::uo) is det.
:- pred play_looping(sound::in, io.io::di, io.io::uo) is det.
:- pred stop(sound::in, io.io::di, io.io::uo) is det.
:- pred pause(sound::in, io.io::di, io.io::uo) is det.
:- pred rewind(sound::in, io.io::di, io.io::uo) is det.
:- pred volume(sound::in, float::in, io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- pragma foreign_decl("C",
    "
    #ifdef __APPLE__
        #include <OpenAL/al.h>
        #include <OpenAL/alc.h>
    #else
        #include <AL/al.h>
        #include <AL/alc.h>
    #endif
    
    #include <ogg/ogg.h>
    #include <opus/opus.h>
    
    #include <stdio.h>
    #include <stdlib.h>
    
    
    #define BUFFER_SIZE (5760 * 2)
    static const unsigned gSampleRate = 48000;
    
    struct AudioCtx {
        ALCdevice *device;
        ALCcontext *context;
    };

    struct Sound {
        struct AudioCtx *ctx;
        ALuint snd;
    };
    void CtxFinalizer(void *x, void *);
    void SndFinalizer(void *x, void *);
    ").

:- pragma foreign_code("C",
    "
    void CtxFinalizer(void *x, void *z){ (void)z;
        struct AudioCtx *const ctx = (struct AudioCtx*)x;
        alcDestroyContext(ctx->context);
        alcCloseDevice(ctx->device);
    }

    void SndFinalizer(void *x, void *z){ (void)z;
        struct Sound *const snd = (struct Sound*)x;
        ALint i;
        alcMakeContextCurrent(snd->ctx->context);
        alDeleteSources(1, &snd->snd);
        /* Free up buffers if possible. */
        alGetSourcei(snd->snd, AL_BUFFERS_PROCESSED, &i);
        /* If there are more than one buffers ready to be unqueued, we will simply
         * destroy them. This is mainly an issue with OS X's OpenAL. */
        if(i){
            ALuint other[16];
            while(i){
                const unsigned to_delete = (i >= 16) ? 16 : i;
                alSourceUnqueueBuffers(snd->snd, to_delete, other);
                alDeleteBuffers(to_delete, other);
                i -= to_delete;
            }
        }
    }
    
    ").

:- pragma foreign_type("C", context, "struct AudioCtx*").
:- pragma foreign_type("C", sound, "struct Sound*").

:- pragma foreign_proc("C", init_context = (Ctx::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe],
    "
        Ctx = MR_GC_malloc_atomic(sizeof(struct AudioCtx));
        MR_GC_register_finalizer(Ctx, CtxFinalizer, NULL);

        Ctx->device = alcOpenDevice(NULL);
        Ctx->context = alcCreateContext(Ctx->device, NULL);

        alcMakeContextCurrent(Ctx->context);

        alListener3f(AL_POSITION, 0.0f, 0.0f, 0.0f);
        alListener3f(AL_VELOCITY, 0.0f, 0.0f, 0.0f);
        alListener3f(AL_ORIENTATION, 0.0f, 0.0f, 0.0f);
    ").

:- func create_ok(sound::di) = (load::uo) is det.
create_ok(S) = ok(S).
:- pragma foreign_export("C", create_ok(di) = (uo), "M_CreateOK").

:- func create_badfile = (load::uo) is det.
create_badfile = badfile.
:- pragma foreign_export("C", create_badfile = (uo), "M_CreateBadFile").

:- func create_nofile = (load::uo) is det.
create_nofile = nofile.
:- pragma foreign_export("C", create_nofile = (uo), "M_CreateNoFile").

:- func create_internal_error = (load::uo) is det.
create_internal_error = internal_error.
:- pragma foreign_export("C", create_internal_error = (uo), "M_CreateInternalError").

:- pragma foreign_proc("C",
    load(Ctx::in, Path::in, Res::uo, IOi::di, IOo::uo),
    [may_call_mercury, will_not_throw_exception, promise_pure, thread_safe],
    "
    IOo = IOi;
    do{
        int erred = 0;
        void *buffer = NULL;
        int err = 0;
        struct Sound *snd = NULL;
        FILE *const file = fopen(Path, ""rb"");
        OpusDecoder *const decoder = opus_decoder_create(gSampleRate, 1, &err);
        
        ogg_sync_state state;
        ogg_page page;
        ogg_stream_state stream;
        int inited = 0, eofed = 0;
        
        if(!file){
            Res = M_CreateNoFile();
            break;
        }
        
        if(err != OPUS_OK){
            Res = M_CreateInternalError();
            break;
        }
        
        if(ogg_sync_init(&state) != 0){
            Res = M_CreateInternalError();
            break;
        }   
        
        snd = MR_GC_NEW(struct Sound);
        snd->ctx = Ctx;
        alGenSources(1, &snd->snd);
         
        do{ /* while(!eofed) */
            ogg_packet packet;
            while(ogg_sync_pageout(&state, &page) == 1){
                if(ogg_page_bos(&page)){
                    ogg_stream_init(&stream, ogg_page_serialno(&page));
                    inited = 1;
                }
                ogg_stream_pagein(&stream, &page);
            }

            eofed = feof(file);
            
            if(buffer == NULL)
                buffer = malloc(BUFFER_SIZE);
            
            {
                char *const ogg_buffer = ogg_sync_buffer(&state, 8192);
                const unsigned short readin = fread(ogg_buffer, 1, 8192, file);
                ogg_sync_wrote(&state, readin);
            }
            
            while(inited && ogg_stream_packetout(&stream, &packet) == 1){
                const int r = opus_decode(decoder, packet.packet, packet.bytes,
                    buffer, BUFFER_SIZE, 0);
              /* Get an OpenAL buffer. If there are any fully processed, reuse 
               * one of them. Otherwise, we will need to generate a new one. */
                if(r > 0){ /* r is the amount to read out, or a negative error */
                    ALuint albuffer = 0;
                    ALint i = 0;
                    alGetSourcei(snd->snd, AL_BUFFERS_PROCESSED, &i);
                    if(i > 0){
                        /* Grab one buffer for our use sending data. */
                        alSourceUnqueueBuffers(snd->snd, 1, &albuffer);

                        /* If there is more than one buffer, free the others. */
                        if(--i > 0){
                            ALuint others[16];
                            do{
                                const unsigned to_delete = (i >= 16) ? 16 : i;
                                alSourceUnqueueBuffers(snd->snd, to_delete, others);
                                alDeleteBuffers(to_delete, others);
                                i -= to_delete;
                            }while(i > 0);
                        } /* if(--i > 0) */
                    } /* if(i > 0) */
                    else
                        alGenBuffers(1, &albuffer);
                    
                    alBufferData(albuffer, AL_FORMAT_MONO16, buffer, r, gSampleRate);
                    alSourceQueueBuffers(snd->snd, 1, &albuffer);
                } /* if(r > 0) */
                else {
    #define MAUDIO_ERROR(WHAT, CALL)\
        case OPUS_ ## WHAT: Res = M_Create ## CALL(); break
                    switch(r){
                        MAUDIO_ERROR(ALLOC_FAIL, InternalError);
                        MAUDIO_ERROR(BAD_ARG, InternalError);
                        MAUDIO_ERROR(BUFFER_TOO_SMALL, InternalError);
                        MAUDIO_ERROR(INTERNAL_ERROR, InternalError);
                        MAUDIO_ERROR(INVALID_PACKET, BadFile);
                        MAUDIO_ERROR(UNIMPLEMENTED, BadFile);
                    }
    #undef MAUDIO_ERROR
                    MR_GC_free(snd);
                    erred = 1;
                    break;
                }
            } /* if(r > 0) */
        }while(!eofed);

        fclose(file);
        opus_decoder_destroy(decoder);
        if(buffer != NULL)
            free(buffer);

        if(!erred)
            Res = M_CreateOK(snd);
    }while(0);
    ").


:- pragma foreign_proc("C", play(Snd::in, IOi::di, IOo::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe],
    "
        IOo = IOi;
        alcMakeContextCurrent(Snd->ctx->context);
        alSourcei(Snd->snd, AL_LOOPING, AL_FALSE);
        alSourcePlay(Snd->snd);
    ").

:- pragma foreign_proc("C", play_looping(Snd::in, IOi::di, IOo::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe],
    "
        IOo = IOi;
        alcMakeContextCurrent(Snd->ctx->context);
        alSourcei(Snd->snd, AL_LOOPING, AL_TRUE);
        alSourcePlay(Snd->snd);
    ").

:- pragma foreign_proc("C", stop(Snd::in, IOi::di, IOo::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe],
    "
        IOo = IOi;
        alcMakeContextCurrent(Snd->ctx->context);
        alSourceStop(Snd->snd);
    ").

:- pragma foreign_proc("C", pause(Snd::in, IOi::di, IOo::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe],
    "
        IOo = IOi;
        alcMakeContextCurrent(Snd->ctx->context);
        alSourcePause(Snd->snd);
    ").

:- pragma foreign_proc("C", rewind(Snd::in, IOi::di, IOo::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe],
    "
        IOo = IOi;
        alcMakeContextCurrent(Snd->ctx->context);
        alSourceRewind(Snd->snd);
    ").

:- pragma foreign_proc("C", volume(Snd::in, Vol::in, IOi::di, IOo::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe],
    "
        IOo = IOi;
        alcMakeContextCurrent(Snd->ctx->context);
        alSourcef(Snd->snd, AL_GAIN, Vol);
    ").

