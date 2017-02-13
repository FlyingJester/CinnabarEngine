:- module sinegen.
%==============================================================================%
% Generates a sinewave at a certain frequency for a given number of samples.
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
:- use_module math.

:- pred prepend(T::di, list(T)::di, list(T)::uo) is det.
prepend(I, ListIn, [I|ListIn]).

:- pragma inline(prepend/3).

gen_int(SamplesPerPeriod, NumSamples, !Samples) :-
    Phase = unchecked_rem(NumSamples, SamplesPerPeriod),
    SineT = (float.float(Phase) / float.float(SamplesPerPeriod) * math.pi),
    
    % Note that we multiply by 7 less than the max, and then add 3. This keeps
    % us from generating pure 0x0000 and pure 0x7FFF, and makes a nicer tone.
    Sample = (((math.sin(SineT) + 1.0) / 2.0) * 32760.0) + 3.0,
    prepend(float.round_to_int(Sample)+0, !Samples),
    ( NumSamples > 0 ->
        gen_int(SamplesPerPeriod, NumSamples - 1, !Samples)
    ;
        true % Pass.
    ).

gen_float(SamplesPerPeriod, NumSamples, !Samples) :-
    Phase = int.unchecked_rem(NumSamples, SamplesPerPeriod),
    Sample = math.sin(float.float(Phase) / float.float(SamplesPerPeriod)),
    prepend(Sample+0.0, !Samples),
    ( NumSamples > 0 ->
        gen_float(SamplesPerPeriod, NumSamples - 1, !Samples)
    ;
        true % Pass.
    ).
