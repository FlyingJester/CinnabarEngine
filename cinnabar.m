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
:- use_module scene.
:- use_module matrix.
:- use_module wavefront.
:- use_module renderer.
:- use_module gl2renderer.
:- use_module aimg.
:- use_module mchrono.
:- use_module maybe.

% This helper is to make a non-polymorphic scene.node that is also empty.
:- func wavefront_node = scene.node(wavefront.shape).
wavefront_node = scene.empty.

% TEST ONLY
:- func test_shape = string.
test_shape = " # Test shape.
vt 0.0 0.0
v 0.0 0.0 0.0
v 0.0 1.0 0.0
v 1.0 0.0 0.0
f 0/0 1/0 2/0
".

:- pred frame(Renderer::in, scene.node(Model)::in,
    scene.matrixtree::in,
    io.io::di, io.io::uo,
    mglow.window::di, mglow.window::uo) is det
        <= (renderer.model(Renderer, Model), renderer.renderer(Renderer)).

main(!IO) :-
    mglow.create_window(!IO, mglow.size(480, 320), mglow.gl_version(4, 1), "Cinnabar", Window),
    gl2renderer.init(Renderer, Window, WindowRender),
    wavefront.load(test_shape, wavefront.init_shape, Shape),
    frame(Renderer, scene.shape(Shape), scene.init_matrixtree, !IO, WindowRender, WindowEnd),
    mglow.destroy_window(!IO, WindowEnd).

frame(Renderer, Scene, MatrixTree, !IO, !Window) :-
    mchrono.micro_ticks(!IO, FrameStart),
    
    mglow.get_event(!Window, MaybeEvent),
    ( 
        MaybeEvent = maybe.yes(Event),
        (
            Event = mglow.quit
        )
    ;
        MaybeEvent = maybe.no,
        
        scene.draw(Scene, matrix.identity, MatrixTree, Renderer, !Window),
        renderer.end_frame(Renderer, !Window),
        mglow.flip_screen(!Window),

        mchrono.subtract(!IO, FrameStart, FrameEnd),
        mchrono.micro_sleep(!IO, FrameEnd),

        frame(Renderer, Scene, MatrixTree, !IO, !Window)
    ).
