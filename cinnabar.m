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
:- use_module mchrono.
:- use_module mglow.

:- use_module mopenal.
:- use_module audio_loader.
:- use_module upload_aimg.
:- use_module opengl.
:- use_module gl2.
:- use_module gl2.skybox.
:- use_module gl2.heightmap.
:- use_module aimg.
:- use_module heightmap.
:- use_module render.

:- use_module vector.
:- use_module softshape.
:- use_module wavefront.

:- use_module scene.
:- use_module scene.matrix_tree.
:- use_module scene.node_tree.
:- use_module camera.

:- import_module list.
:- import_module float.
:- import_module int.
:- use_module string.
:- use_module maybe.

:- instance heightmap.heightmap(aimg.texture) where [
    (heightmap.get(Texture, X, Y, Value) :-
        aimg.pixel(Texture, X, Y, Color),
        aimg.rf(Color) + aimg.bf(Color) + aimg.gf(Color) = Value
    ),
    func(heightmap.w/1) is (aimg.width),
    func(heightmap.h/1) is (aimg.height)
].

%------------------------------------------------------------------------------%
:- pred frame(scene.scene(Model, Heightmap, Texture)::in, Renderer::in,
    mglow.window::di, mglow.window::uo, io.io::di, io.io::uo) is det
    <= (render.render(Renderer),
        render.model(Renderer, Model),
        render.skybox(Renderer, Texture),
        render.heightmap(Renderer, Heightmap, Texture)).

:- func w = int.
w = 480.
:- func h = int.
h = 320.
:- func tex_path = string.
tex_path = "sword.png".
:- func skybox_path = string.
skybox_path = "skybox.png".
:- func shape_path = string.
shape_path = "sword.obj".

%------------------------------------------------------------------------------%
:- pred setup_gl2(gl2.gl2::in, mglow.window::di, mglow.window::uo) is det.
setup_gl2(_, !Window) :-
    gl2.matrix_mode(gl2.modelview, !Window),
    gl2.load_identity(!Window),
    gl2.matrix_mode(gl2.projection, !Window),
    AspectRatio = float(w) / float(h),
    gl2.frustum(1.0, 100.0, -0.5 * AspectRatio, 0.5 * AspectRatio, -0.5, 0.5, !Window),
    opengl.viewport(0, 0, w, h, !Window).

:- pred load_texture(string::in, io.io::di, io.io::uo,
    mglow.window::di, mglow.window::uo, maybe.maybe(opengl.texture)::out) is det.

load_texture(Path, !IO, !Window, Output) :-
    upload_aimg.load(!IO, string.append("res/", Path), UploadResult, !Window),
    (
        UploadResult = upload_aimg.ok(Tex),
        Output = maybe.yes(Tex)
    ;
        UploadResult = upload_aimg.badfile,
        Output = maybe.no,
        io.write_string("Could not load texture file: ", !IO),
        io.write_string(tex_path, !IO),
        io.nl(!IO)
    ;
        UploadResult = upload_aimg.nofile,
        Output = maybe.no,
        io.write_string("Missing texture file: ", !IO),
        io.write_string(tex_path, !IO),
        io.nl(!IO)
    ).

%------------------------------------------------------------------------------%
main(!IO) :-
    mglow.create_window(!IO, 
        mglow.size(w, h), mglow.gl_version(2, 0), "Cinnabar", Win0),
    
    gl2.init(Win0, Win1, GL2),
    setup_gl2(GL2, Win1, Win2),
    
    io.write_string("[Cinnabar] Created Window\n", !IO),
    
    io.see(string.append("res/", shape_path), SeeResult, !IO),
    ( 
        SeeResult = io.ok,
        io.read_file_as_string(ShapeResult, !IO),
        (
            ShapeResult = io.ok(Src),
            wavefront.load(Src, wavefront.init_shape, Shape)
        ;
            ShapeResult = io.error(_, _),
            Shape = wavefront.init_shape,
            io.write_string("Could not load shape file: ", !IO),
            io.write_string(shape_path, !IO),
            io.nl(!IO)
        ),
        io.seen(!IO)
    ;
        SeeResult = io.error(_),
        Shape = wavefront.init_shape
    ),
    
    io.write_string("[Cinnabar] Loaded Shape\n", !IO),
    mopenal.open_device(DevResult, !IO),
    (
        DevResult = io.ok(Dev),
        mopenal.create_context(Dev, CtxResult, !IO),
        (
            CtxResult = io.ok(Ctx),
            mopenal.make_current(Ctx, !IO),
            Zero = vector.vector(0.0, 0.0, 0.0),
            mopenal.listener_ctl(mopenal.position, Zero, !IO),
            mopenal.listener_ctl(mopenal.velocity, Zero, !IO),
            mopenal.listener_ctl(mopenal.orientation, Zero, !IO)
            %audio_loader.load("res/spiders.opus", Ctx, SndResult, !IO),
            %(
            %    SndResult = io.ok(Snd),
            %    mopenal.play(Snd, !IO)
            %;
            %    SndResult = io.error(Err),
            %    io.error_message(Err, ErrMsg),
            %    io.write_string("Could not open res/spiders.opus: ", !IO),
            %    io.write_string(ErrMsg, !IO), io.nl(!IO)
            %)
        ;
            CtxResult = io.error(Err),
            io.error_message(Err, ErrMsg),
            io.write_string("Could not open OpenAL context: ", !IO),
            io.write_string(ErrMsg, !IO), io.nl(!IO)
        )
    ;
        DevResult = io.error(Err),
        io.error_message(Err, ErrMsg),
        io.write_string("Could not open OpenAL device: ", !IO),
        io.write_string(ErrMsg, !IO), io.nl(!IO)
    ),
    io.write_string("[Cinnabar] Loaded Sound\n", !IO),
    load_texture(tex_path, !IO, Win2, Win3, MaybeTexture),
    load_texture(skybox_path, !IO, Win3, Win4, MaybeSkybox),
    load_texture("moldy.tga", !IO, Win4, Win5, MaybeGround),
    Win6 = Win5,
    aimg.load(!IO, "perlin.png", MaybeHeightmap),
    ( MaybeTexture = maybe.yes(Tex),
      MaybeGround = maybe.yes(Ground),
      MaybeHeightmap = aimg.ok(HeightmapIn),
      MaybeSkybox = maybe.yes(Skybox) ->
        
        MatrixTree = scene.matrix_tree.init,
        NodeTree = scene.node_tree.model(gl2.wavefront_shape(Shape, Tex)),
        Camera = camera.camera(3.0, -2.0, -10.0, 0.0, 0.0),
        heightmap.load(HeightmapIn, gl2.heightmap.init, HeightmapRaw),
        Heightmap = gl2.heightmap.heightmap(HeightmapRaw),
        Scene = scene.scene(MatrixTree, NodeTree, Camera, Skybox, Heightmap, Ground),
        io.write_string("[Cinnabar] Beginning Render\n", !IO),
        frame(Scene, GL2, Win6, Win7, !IO)
    ;
        Win6 = Win7,
        true % Pass, load_texture already reported errors.
    ),
    mglow.destroy_window(!IO, Win7).

:- func pitch_control(float) = float.
:- func yaw_control(float) = float.

pitch_control(TryPitch) = Pitch :-
    ( TryPitch > 3.0 ->
        Pitch = 3.0
    ; TryPitch < 0.0 ->
        Pitch = 0.0
    ;
        Pitch = TryPitch
    ).

yaw_control(TryYaw) = Yaw :-
    ( TryYaw > 2.0 * 3.1415 ->
        Yaw = TryYaw - 2.0 * 3.1415
    ; TryYaw < 0.0 ->
        Yaw = TryYaw + 2.0 * 3.1415
    ;
        Yaw = TryYaw
    ).

:- pred eat_others(maybe.maybe(mglow.glow_event)::out,
    mglow.window::di, mglow.window::uo) is det.
eat_others(Out, !Window) :-
    mglow.get_event(MaybeEvent, !Window),
    (
        MaybeEvent = maybe.no, Out = maybe.no
    ;
        MaybeEvent = maybe.yes(Event),
        ( Event = mglow.other ->
            eat_others(Out, !Window)
        ;
            Out = MaybeEvent
        )
    ).

%------------------------------------------------------------------------------%
frame(Scene, Renderer, !Window, !IO) :-
    
    Scene = scene.scene(MatrixTree, NodeTree, Cam, Skybox, Heightmap, Ground),
    mchrono.micro_ticks(!IO, FrameStart),
    
    eat_others(MaybeEvent, !Window),
%    mglow.get_event(MaybeEvent, !Window),
    (
        MaybeEvent = maybe.yes(Event),
        (
            Event = mglow.quit
        ;
            Event = mglow.other,
            frame(Scene, Renderer, !Window, !IO)
        )
    ;
        MaybeEvent = maybe.no,
        render.push_matrix(Renderer, !Window),
        
        mglow.get_mouse_location(MouseX + (w / 2), MouseY + (h / 2), !Window),
        
        mglow.key_pressed("w", Forward, !Window),
        mglow.key_pressed("a", Left, !Window),
        mglow.key_pressed("s", Backward, !Window),
        mglow.key_pressed("d", Right, !Window),
        mglow.key_pressed("q", Up, !Window),
        mglow.key_pressed("e", Down, !Window),
        ( not Forward = Backward ->
            ( Forward = mglow.press ->
                CamZ = Cam ^ camera.z + 0.1
            ; Backward = mglow.press ->
                CamZ = Cam ^ camera.z - 0.1
            ;
                CamZ = Cam ^ camera.z
            )
        ;
            CamZ = Cam ^ camera.z
        ),
        ( not Left = Right ->
            ( Left = mglow.press ->
                CamX = Cam ^ camera.x - 0.1
            ; Right = mglow.press ->
                CamX = Cam ^ camera.x + 0.1
            ;
                CamX = Cam ^ camera.x
            )
        ;
            CamX = Cam ^ camera.x
        ),
        (not Up = Down ->
            ( Up = mglow.press ->
                CamY = Cam ^ camera.y - 0.1
            ; Down = mglow.press ->
                CamY = Cam ^ camera.y + 0.1
            ;
                CamY = Cam ^ camera.y
            )
        ;
            CamY = Cam ^ camera.y
        ),
        ( ( MouseX > w / 2 ; MouseX < -w / 2 ; MouseY > h / 2 ; MouseY < -h / 2 ) -> 
            Pitch = Cam ^ camera.pitch, Yaw = Cam ^ camera.yaw
        ;
            Yaw = yaw_control(Cam ^ camera.yaw - (float.float(MouseX) / 200.0)),
            Pitch = pitch_control(Cam ^ camera.pitch - (float.float(MouseY) / 200.0)),
            mglow.center_mouse(!Window)
        ),
        NewCam = camera.camera(CamX, CamY, CamZ, Pitch, Yaw),
        NewScene = scene.scene(MatrixTree, NodeTree, NewCam, Skybox, Heightmap, Ground),
%        io.write_string("[Cinnabar] Drawing Scene\n", !IO),
        scene.draw(Scene, Renderer, !Window),
%        io.write_string("[Cinnabar] Flip Screen\n", !IO),
        mglow.flip_screen(!Window),
%        io.write_string("[Cinnabar] Cleanup\n", !IO),
        render.pop_matrix(Renderer, !Window),

        mchrono.subtract(!IO, FrameStart, FrameEnd),
        mchrono.micro_sleep(!IO, FrameEnd),

        frame(NewScene, Renderer, !Window, !IO)
    ).
