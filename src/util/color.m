:- module color.
%==============================================================================%
:- interface.
%==============================================================================%

:- type color ---> color(r::float, g::float, b::float, a::float).

:- func white = color.
:- func black = color.
:- func red = color.
:- func green = color.
:- func blue = color.
:- func yellow = color.
:- func cyan = color.
:- func purple = color.
:- func orange = color.
:- func lime = color.
:- func sky = color.
:- func gray = color.

:- func rgb(float, float, float) = color.
:- func rgba(float, float, float, float) = color.

:- pred rgb(float, float, float, color).
:- mode rgb(in, in, in, out) is det.
:- mode rgb(di, di, di, uo) is det.

:- pred rgba(float, float, float, float, color).
:- mode rgba(in, in, in, in, out) is det.
:- mode rgba(out, out, out, out, in) is det.
:- mode rgba(uo, uo, uo, uo, di) is det.
:- mode rgba(in, in, in, in, in) is semidet.
:- mode rgba(di, di, di, di, uo) is det.

:- func red(color) = float.
:- func green(color) = float.
:- func blue(color) = float.
:- func alpha(color) = float.

%==============================================================================%
:- implementation.
%==============================================================================%

white = rgb(1.0, 1.0, 1.0).
black = rgb(0.0, 0.0, 0.0).
red   = rgb(1.0, 0.0, 0.0).
green = rgb(0.0, 1.0, 0.0).
blue  = rgb(0.0, 0.0, 1.0).
yellow= rgb(1.0, 1.0, 0.0).
cyan  = rgb(0.0, 1.0, 1.0).
purple= rgb(1.0, 0.0, 1.0).
orange= rgb(1.0, 0.5, 0.0).
lime  = rgb(0.5, 0.1, 0.0).
sky   = rgb(0.5, 0.5, 1.0).
gray  = rgb(0.5, 0.5, 0.5).

rgb(R, G, B) = color(R, G, B, 1.0).
rgba(R, G, B, A) = color(R, G, B, A).
rgb(R, G, B, color(R, G, B, 1.0)).
rgba(R, G, B, A, color(R, G, B, A)).

red(C) = C ^ r.
green(C) = C ^ g.
blue(C) = C ^ b.
alpha(C) = C ^ a.

:- pragma foreign_export("C", rgb(in, in, in) = (out),
    "Cinnabar_CreateRGB").
:- pragma foreign_export("C", rgba(in, in, in, in) = (out),
    "Cinnabar_CreateRGBA").
:- pragma foreign_export("C", rgba(out, out, out, out, in),
    "Cinnabar_GetRGB").
:- pragma foreign_export("C", red(in) = (out),
    "Cinnabar_Red").
:- pragma foreign_export("C", green(in) = (out),
    "Cinnabar_Green").
:- pragma foreign_export("C", blue(in) = (out),
    "Cinnabar_Blue").
:- pragma foreign_export("C", alpha(in) = (out),
    "Cinnabar_Alpha").
