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
:- use_module opengl.
:- use_module softshape.

:- import_module list.
:- import_module float.
:- use_module maybe.

%------------------------------------------------------------------------------%
:- pred frame(list(Model)::in, Renderer::in,
    mglow.window::di, mglow.window::uo, io.io::di, io.io::uo) is det
    <= (render.render(Renderer), render.model(Renderer, Model)).

:- func w = int.
w = 480.
:- func h = int.
h = 320.

%------------------------------------------------------------------------------%
main(!IO) :-
    mglow.create_window(!IO, mglow.size(w, h), mglow.gl_version(2, 0), "Cinnabar", Window),
    
    gl2.ortho(1.0, 1.0, Window, WindowOrtho),
    gl2.init(WindowOrtho, WindowRender, GL2),
    
    Rect = softshape.rectangle(0.1, 0.1, 0.8, 0.8),
    frame([gl2.shape2d(Rect)|[]], GL2, WindowRender, WindowEnd, !IO),
    
    mglow.destroy_window(!IO, WindowEnd).

%------------------------------------------------------------------------------%
frame(Models, Renderer, !Window, !IO) :-
    mchrono.micro_ticks(!IO, FrameStart),
    
    mglow.get_event(MaybeEvent, !Window),
    (
        MaybeEvent = maybe.yes(Event),
        (
            Event = mglow.quit
        )
    ;
        MaybeEvent = maybe.no,
        render.push_matrix(Renderer, !Window),
        
        mglow.get_mouse_location(MouseX, MouseY, !Window),
        
        X = float(MouseX) / float(w),
        Y = float(MouseY) / float(h),
        render.translate(Renderer, X, Y, 0.0, !Window),
        
        list.foldl(render.draw(Renderer), Models, !Window),
        mglow.flip_screen(!Window),

        render.pop_matrix(Renderer, !Window),

        mchrono.subtract(!IO, FrameStart, FrameEnd),
        mchrono.micro_sleep(!IO, FrameEnd),

        frame(Models, Renderer, !Window, !IO)
    ).
