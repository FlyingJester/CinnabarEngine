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

update(Settings, Update, Camera, update(Settings, Update, Camera)).
update(Settings, update(DX, DY), camera(X, Y, Z, Pitch, Yaw)) =
    camera(X, Y, Z, 
        Pitch + (Pitch * x_sensitivity(Settings) * DX),
        Yaw + (Yaw * y_sensitivity(Settings) * DY)).
