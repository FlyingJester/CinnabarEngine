:- module mopenal.
%==============================================================================%
% Note that this is not entirely equal to OpenAL, but rather contains some of
% the limitations imposed by Cinnamon to make other backends simpler (see the
% loader type, for instance).
:- interface.
%==============================================================================%

:- use_module io.
:- use_module buffer.
:- use_module vector.

:- type context.
:- type device.
:- type loader.
:- type sound.

:- type listener_ctl ---> position ; velocity ; orientation.
:- type format ---> mono_16 ; stereo_16 ; mono_float ; stereo_float.

:- pred open_device(io.res(device), io.io, io.io).
:- mode open_device(uo, di, uo) is det.

:- pred create_context(device, io.res(context), io.io, io.io).
:- mode create_context(in, uo, di, uo) is det.

:- pred supports_float(device::in) is semidet.

:- pred context_supports_float(context::in) is semidet.

:- pred make_current(context::in, io.io::di, io.io::uo) is det.

:- pred listener_ctl(listener_ctl, vector.vector3, io.io, io.io).
:- mode listener_ctl(in, in, di, uo) is det.

:- pred listener_ctl(listener_ctl, float, float, float, io.io, io.io).
:- mode listener_ctl(in, in, in, in, di, uo) is det.

:- pred create_loader(format, int, context, loader, io.io, io.io).
:- mode create_loader(in, in, in, uo, di, uo) is det.
:- pred put_data(loader::di, loader::uo, buffer.buffer::in) is det.
:- pred finalize(loader::di, sound::uo) is det.

:- pred play(sound::in, io.io::di, io.io::uo) is det.
:- pred play_looping(sound::in, io.io::di, io.io::uo) is det.
:- pred set_looping(sound::in, io.io::di, io.io::uo) is det.
:- pred unset_looping(sound::in, io.io::di, io.io::uo) is det.
:- pred stop(sound::in, io.io::di, io.io::uo) is det.
:- pred pause(sound::in, io.io::di, io.io::uo) is det.

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
    ").

:- pragma foreign_import_module("C", buffer).

:- pragma foreign_type("C", context, "ALCcontext*const*").
:- pragma foreign_type("C", device, "ALCdevice*const*").
:- pragma foreign_type("C", sound, "ALuint*"). % Size of 1.
:- pragma foreign_type("C", loader, "ALuint*"). % { Snd, Format, Rate }

:- pragma foreign_enum("C", format/0,
    [
        mono_16 - "AL_FORMAT_MONO16",
        stereo_16 - "AL_FORMAT_STEREO16",
        mono_float - "0x10010", % Can't trust these will really exist.
        stereo_float - "0x10011"
    ]).

:- pragma foreign_enum("C", listener_ctl/0,
    [
        position - "AL_POSITION",
        velocity - "AL_VELOCITY",
        orientation - "AL_ORIENTATION"
    ]).

:- pragma foreign_decl("C", "void MOpenAL_DevFinalizer(void *dev, void *arg);").
:- pragma foreign_code("C",
    "
        void MOpenAL_DevFinalizer(void *dev, void *arg){
            (void)arg;
            alcCloseDevice(*((ALCdevice **)dev));
        }
    ").

:- pragma foreign_decl("C", "void MOpenAL_CtxFinalizer(void *ctx, void *arg);").
:- pragma foreign_code("C",
    "
        void MOpenAL_CtxFinalizer(void *ctx, void *arg){
            alcDestroyContext(*((ALCcontext **)ctx));
        }
    ").

:- pragma foreign_decl("C", "void MOpenAL_SndFinalizer(void *snd, void *arg);").
:- pragma foreign_code("C",
    "
        void MOpenAL_SndFinalizer(void *snd, void *arg){
            alDeleteSources(1, (ALuint*)snd);
        }
    ").

:- pragma foreign_decl("C", "int MOpenAL_CleanSound(ALuint snd, ALuint *out);").
:- pragma foreign_code("C", 
    "
        int MOpenAL_CleanSound(ALuint snd, ALuint *out){
            ALint i;
            alGetSourcei(snd, AL_BUFFERS_PROCESSED, &i);
            if(i > 0){
                if(out != NULL){
                    i--;
                    alSourceUnqueueBuffers(snd, 1, out);
                }
                ALuint buffers[16];
                do{
                    const unsigned to_delete = (i >= 16) ? 16 : i;
                    alSourceUnqueueBuffers(snd, to_delete, buffers);
                    alDeleteBuffers(to_delete, buffers);
                    i -= to_delete;
                }while(i > 0);
                return 1;
            } /* if(i > 0) */
            return 0;
        }
    ").

% Wrappers for use inside the foreign procs.
:- func create_dev_error(string) = io.res(device).
create_dev_error(Err) = io.error(io.make_io_error(Err)).
:- pragma foreign_export("C", create_dev_error(in) = (out), "MOpenAL_CreateDevError").

:- func create_dev_ok(device) = io.res(device).
create_dev_ok(Dev) = io.ok(Dev).
:- pragma foreign_export("C", create_dev_ok(in) = (out), "MOpenAL_CreateDevOK").

:- func create_ctx_error(string) = io.res(context).
create_ctx_error(Err) = io.error(io.make_io_error(Err)).
:- pragma foreign_export("C", create_ctx_error(in) = (out), "MOpenAL_CreateCtxError").

:- func create_ctx_ok(context) = io.res(context).
create_ctx_ok(Ctx) = io.ok(Ctx).
:- pragma foreign_export("C", create_ctx_ok(in) = (out), "MOpenAL_CreateCtxOK").

:- pragma foreign_proc("C", open_device(Out::uo, IO0::di, IO1::uo),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        IO1 = IO0;
        ALCdevice *const device = alcOpenDevice(NULL);
        if(device){
            ALCdevice **const dev_ptr = MR_GC_malloc_atomic(sizeof(void*));
            dev_ptr[0] = device;
            Out = MOpenAL_CreateDevOK(dev_ptr);
            MR_GC_register_finalizer(dev_ptr, MOpenAL_DevFinalizer, NULL);
        }
        else{
            const char err[] = ""Could not open device"";
            char *const m_err = MR_GC_malloc_atomic(sizeof(err));
            memcpy(m_err, err, sizeof(err));
            Out = MOpenAL_CreateDevError(m_err);
        }
    ").

:- pragma foreign_proc("C", create_context(Dev::in, Out::uo, IO0::di, IO1::uo),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        IO1 = IO0;
        ALCcontext *const ctx = alcCreateContext(*Dev, NULL);
        if(ctx){
            ALCcontext **const ctx_ptr = MR_GC_malloc_atomic(sizeof(void*));
            ctx_ptr[0] = ctx;
            Out = MOpenAL_CreateCtxOK(ctx_ptr);
            MR_GC_register_finalizer(ctx_ptr, MOpenAL_CtxFinalizer, (void*)Dev);
        }
        else{
            const char err[] = ""Could not open context"";
            char *const m_err = MR_GC_malloc_atomic(sizeof(err));
            memcpy(m_err, err, sizeof(err));
            Out = MOpenAL_CreateCtxError(m_err);
        }
    ").

:- pragma foreign_proc("C", supports_float(Dev::in),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe],
    "
        const ALboolean exists = alcIsExtensionPresent(*Dev, ""AL_EXT_FLOAT32"");
        SUCCESS_INDICATOR = (exists == AL_TRUE);
    ").

:- pragma foreign_proc("C", context_supports_float(Ctx::in),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe],
    "
        ALCdevice *const dev = alcGetContextsDevice(*Ctx);
        const ALboolean exists = alcIsExtensionPresent(dev, ""AL_EXT_FLOAT32"");
        SUCCESS_INDICATOR = (exists == AL_TRUE);
    ").

:- pragma foreign_proc("C", make_current(Ctx::in, IO0::di, IO1::uo),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe, tabled_for_io],
    "
        IO1 = IO0;
        alcMakeContextCurrent(*Ctx);
    ").

listener_ctl(Ctl, vector.vector(X, Y, Z), !IO) :- listener_ctl(Ctl, X, Y, Z, !IO).

:- pragma foreign_proc("C",
    listener_ctl(Ctl::in, X::in, Y::in, Z::in, IO0::di, IO1::uo),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe, tabled_for_io],
    "
        IO1 = IO0;
        alListener3f(Ctl, X, Y, Z);
    ").

:- pragma foreign_proc("C",
    create_loader(Format::in, Rate::in, Ctx::in, Out::uo, IO0::di, IO1::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        IO1 = IO0;
        Out = MR_GC_malloc_atomic(sizeof(ALuint) * 3);
        alcMakeContextCurrent(*Ctx);
        alGenSources(1, Out);
        Out[1] = Format;
        Out[2] = Rate;
        MR_GC_register_finalizer(Out, MOpenAL_SndFinalizer, (void*)Ctx);
    ").


:- pragma foreign_proc("C", put_data(In::di, Out::uo, Buffer::in),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        Out = In;
        ALuint buffer;
        if(!MOpenAL_CleanSound(*In, &buffer)){
            alGenBuffers(1, &buffer);
        }
        alBufferData(buffer, In[1], Buffer->data, Buffer->size, In[2]);
        alSourceQueueBuffers(*In, 1, &buffer);
    ").

:- pragma foreign_proc("C", finalize(Loader::di, Sound::uo),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe],
    "
        Sound = Loader;
        alSourcef(*Sound, AL_PITCH, 1.0f);
        alSourcef(*Sound, AL_GAIN, 1.0f);
        alSource3f(*Sound, AL_POSITION, 1.0f, 1.0f, 1.0f);
        alSource3f(*Sound, AL_VELOCITY, 1.0f, 1.0f, 1.0f);
        alSourcei(*Sound, AL_LOOPING, AL_FALSE);
    ").

:- pragma foreign_proc("C", play(Snd::in, IO0::di, IO1::uo),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe, tabled_for_io],
    " 
        IO1 = IO0; 
        alSourcei(*Snd, AL_LOOPING, AL_FALSE);
        alSourcePlay(*Snd); 
    ").

:- pragma foreign_proc("C", stop(Snd::in, IO0::di, IO1::uo),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe, tabled_for_io],
    " IO1 = IO0; alSourceStop(*Snd); ").

:- pragma foreign_proc("C", pause(Snd::in, IO0::di, IO1::uo),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe, tabled_for_io],
    " IO1 = IO0; alSourcePause(*Snd); ").

:- pragma foreign_proc("C", set_looping(Snd::in, IO0::di, IO1::uo),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe, tabled_for_io],
    " IO1 = IO0; alSourcei(*Snd, AL_LOOPING, AL_TRUE); ").

:- pragma foreign_proc("C", unset_looping(Snd::in, IO0::di, IO1::uo),
    [will_not_call_mercury, does_not_affect_liveness, will_not_throw_exception,
    promise_pure, thread_safe, tabled_for_io],
    " IO1 = IO0; alSourcei(*Snd, AL_LOOPING, AL_FALSE); ").

play_looping(Snd, !IO) :- stop(Snd, !IO), set_looping(Snd, !IO), play(Snd, !IO).
