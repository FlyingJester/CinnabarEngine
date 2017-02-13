:- module sinetest.
%==============================================================================%
% Test for OpenAL to output a sinewave.
:- interface.
%==============================================================================%

:- use_module io.

:- pred main(io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module mopenal.
:- use_module mchrono.
:- use_module buffer.
:- use_module sinegen.

:- use_module exception.
:- import_module list.
:- import_module int.

% Test length in seconds.
:- func test_length = int.
test_length = 3.

:- pred create_samples(pred(int, int, list(T), list(T)), pred(list(T), buffer.buffer), buffer.buffer).
:- mode create_samples(pred(in, in, di, uo) is det, pred(in, uo) is det, uo) is det.

create_samples(Generator, FromList, Output) :-
    % Create a 600 Hz freq at 48000 Hz.
    % Samples per period: 48000 / 600 = 80.
    % Num Samples (3 seconds) = test_length * 48000
    Generator(80, 144000, [], Samples),
    FromList(Samples, Output).

:- pred do_test(pred(mopenal.loader, io.io, io.io), buffer.buffer, io.io, io.io).
:- mode do_test(pred(uo, di, uo) is det, di, di, uo) is det.

do_test(CreateLoader, Buffer, !IO) :-
    CreateLoader(LoaderEmpty, !IO),
    mopenal.put_data(LoaderEmpty, LoaderFull, Buffer),
    mopenal.finalize(LoaderFull, Sound),
    mopenal.play(Sound, !IO),
    mchrono.micro_sleep(!IO, mchrono.seconds_to_ms(test_length)),
    mopenal.stop(Sound, !IO).

main(!IO) :-
    mopenal.open_device(DevResult, !IO),
    (
        DevResult = io.error(Err),
        exception.throw(exception.software_error(io.error_message(Err)))
    ;
        DevResult = io.ok(Dev),
        (
            % Parse command line arguments.
            mopenal.create_context(Dev, CtxResult, !IO),
            (
                CtxResult = io.error(Err),
                exception.throw(exception.software_error(io.error_message(Err)))
            ;
                CtxResult = io.ok(Ctx),
                mopenal.make_current(Ctx, !IO),
                
                mopenal.listener_ctl(mopenal.position, 0.0, 0.0, 0.0, !IO),
                mopenal.listener_ctl(mopenal.velocity, 0.0, 0.0, 0.0, !IO),
                mopenal.listener_ctl(mopenal.orientation, 0.0, 0.0, 0.0, !IO),
                
                % Perform integer test.
                io.write_string("Beginning Int16 test.\n", !IO),
                create_samples(sinegen.gen_int, buffer.from_list_16, IntSamples),
                do_test(mopenal.create_loader(mopenal.mono_16, 48000, Ctx),
                    IntSamples, !IO),
                ( mopenal.supports_float(Dev) ->
                    io.write_string("Beginning float test.\n", !IO),
                    create_samples(sinegen.gen_float, buffer.from_list_float, FloatSamples),
                    do_test(mopenal.create_loader(mopenal.mono_float, 48000, Ctx),
                        FloatSamples, !IO)
                ;
                    io.write_string("System does not float audio.\n", !IO)
                )
            )
        )
    ).
