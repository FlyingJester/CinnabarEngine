:- module sawgen.
%==============================================================================%
% Generates a sawtooth at a certain frequency for a given number of samples.
:- interface.
%==============================================================================%

:- import_module list.

% Generate the waves in reverse, since it's much faster to prepend to the list,
% and the sinewave is the same forward and backwards.
% generate_sinewave(SamplesPerPeriod, NumSamples, !Wave)

% Generates signed 16-bit samples.
:- pred gen_int(int, int, list(int), list(int)).
:- mode gen_int(in, in, di, uo) is det.

% Generates float samples from 0.0 to 1.0.
:- pred gen_float(int, int, list(float), list(float)).
:- mode gen_float(in, in, di, uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module float.
:- import_module int.

:- pred prepend(T::di, list(T)::di, list(T)::uo) is det.
prepend(I, ListIn, [I|ListIn]).

:- pragma inline(prepend/3).

% dlerp(TValue, MaxT, From, To, Out)
:- pred dlerp_float(int::in, int::in, float::in, float::in, float::uo) is det.
dlerp_float(T, Max, From, To, Out) :-
    LerpVal = float.unchecked_quotient(float.float(T), float.float(Max)),
    Out = From + LerpVal*(To - From).

:- pragma inline(dlerp_float/5).

:- pred dlerp_int(int::in, int::in, int::in, int::in, int::uo) is det.
dlerp_int(T, Max, From, To, Out) :-
    LerpVal = float.unchecked_quotient(float.float(T), float.float(Max)),
    Out = From + floor_to_int(LerpVal*float.float(To - From)).

:- pragma inline(dlerp_int/5).

gen_int(SamplesPerPeriod, NumSamples, !Samples) :-
    dlerp_int(NumSamples, SamplesPerPeriod, 0, 0xFFFF, Sample),
    prepend(Sample, !Samples),
    ( NumSamples > 0 ->
        gen_int(SamplesPerPeriod, NumSamples - 1, !Samples)
    ;
        true % Pass.
    ).

gen_float(SamplesPerPeriod, NumSamples, !Samples) :-
    dlerp_float(NumSamples, SamplesPerPeriod, 0.0, 1.0, Sample),
    prepend(Sample, !Samples),
    ( NumSamples > 0 ->
        gen_float(SamplesPerPeriod, NumSamples - 1, !Samples)
    ;
        true % Pass.
    )
