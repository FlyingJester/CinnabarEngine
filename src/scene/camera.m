:- module camera.
%==============================================================================%
% An abstract interface for a camera. Intentionally does not use the event
% system or mglow to determine what to do.
:- interface.
%==============================================================================%

:- type camera --->
    camera(x::float, y::float, z::float, pitch::float, yaw::float).

:- type mouse_settings --->
    inverted(float, float) ; normal(float, float).
%------------------------------------------------------------------------------%

:- func x_sensitivity(mouse_settings) = float.
:- func y_sensitivity(mouse_settings) = float.
:- func sensitivity(mouse_settings) = {float, float}.

:- type update ---> update(mouse_x_change::float, mouse_y_change::float).

% Moves a camera in XYZ space based on whether the direction inputs match the
% DoMove argument. This is useful for things like a free-floating camera.
% Control(DoMove, Forward, Backward, Left, Right, Rise, Fall, Speed, !Camera)
:- pred cardinal_control(T::in, T::in, T::in, T::in, T::in, T::in, T::in,
    float::in, camera::in, camera::out) is det.
:- func cardinal_control(T, T, T, T, T, T, T, float, camera) = camera.

:- pred update(mouse_settings::in, update::in, camera::in, camera::out) is det.
:- func update(mouse_settings, update, camera) = camera.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module float.

x_sensitivity(inverted(X, _)) = -X.
x_sensitivity(normal(X, _)) = X.
y_sensitivity(inverted(_ , Y)) = -Y.
y_sensitivity(normal(_, Y)) = Y.

sensitivity(Settings) = {x_sensitivity(Settings), y_sensitivity(Settings)}.

cardinal_control(Do, U, D, L, R, Z, F, Speed, Cam,
    cardinal_control(Do, U, D, L, R, Z, F, Speed, Cam)).

cardinal_control(Do, Forward, Backward, Left, Right, Up, Down, Speed, Cam) =
    camera(CamX, CamY, CamZ, Cam ^ pitch, Cam ^ yaw) :-
    ( not Forward = Backward ->
        ( Forward = Do ->
            CamZ = Cam ^ z + Speed
        ; Backward = Do ->
            CamZ = Cam ^ z - Speed
        ;
            CamZ = Cam ^ z
        )
    ;
        CamZ = Cam ^ z
    ),
    ( not Left = Right ->
        ( Left = Do ->
            CamX = Cam ^ x - Speed
        ; Right = Do ->
            CamX = Cam ^ x + Speed
        ;
            CamX = Cam ^ x
        )
    ;
        CamX = Cam ^ x
    ),
    ( not Up = Down ->
        ( Up = Do ->
            CamY = Cam ^ y - Speed
        ; Down = Do ->
            CamY = Cam ^ y + Speed
        ;
            CamY = Cam ^ y
        )
    ;
        CamY = Cam ^ y
    ).

update(Settings, Update, Camera, update(Settings, Update, Camera)).
update(Settings, update(DX, DY), camera(X, Y, Z, Pitch, Yaw)) =
    camera(X, Y, Z, 
        Pitch + (Pitch * x_sensitivity(Settings) * DX),
        Yaw + (Yaw * y_sensitivity(Settings) * DY)).
