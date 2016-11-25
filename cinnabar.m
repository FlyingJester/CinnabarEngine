:- module cinnabar.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
%------------------------------------------------------------------------------%

:- pred main(io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%
:- use_module maudio.
:- use_module mglow.
:- use_module mchrono.
:- use_module render.
:- use_module gl2.

:- use_module maybe.

:- pred frame(io.io::di, io.io::uo,
    mglow.window::di, mglow.window::uo) is det.

main(!IO) :-
    mglow.create_window(!IO, mglow.size(480, 320), mglow.gl_version(4, 1), "Cinnabar", Window),
    gl2.ortho(1.0, 1.0, Window, WindowRender),
    frame(!IO, WindowRender, WindowEnd),
    mglow.destroy_window(!IO, WindowEnd).

frame(!IO, !Window) :-
    mchrono.micro_ticks(!IO, FrameStart),
    
    mglow.get_event(!Window, MaybeEvent),
    ( 
        MaybeEvent = maybe.yes(Event),
        (
            Event = mglow.quit
        )
    ;
        MaybeEvent = maybe.no,

        gl2.begin(gl2.triangle_strip, !Window),
        gl2.color(1.0, 1.0, 1.0, 1.0, !Window),
        gl2.vertex(0.0, 0.0, 0.0,!Window),
        gl2.vertex(0.0, 1.0, 0.0,!Window),
        gl2.vertex(1.0, 0.0, 0.0, !Window),
        gl2.end(!Window),

        mglow.flip_screen(!Window),
%        renderer.end_frame(Renderer, !Window),

        mchrono.subtract(!IO, FrameStart, FrameEnd),
        mchrono.micro_sleep(!IO, FrameEnd),

        frame(!IO, !Window)
    ).
