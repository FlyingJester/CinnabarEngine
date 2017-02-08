:- module perlintest.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.

:- pred main(io.io::di, io.io::uo) is det.

% cmain(Seed, ImageW, ImageH, PW, PH, IsIsland, Path, !IO)
:- pred cmain(int, int, int, int, int, int, string, io.io, io.io).
:- mode cmain(in, in, in, in, in, in, in, di, uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module list.
:- use_module string.
:- use_module random.
:- use_module perlin.

:- pragma foreign_decl("C", "#include ""aimage/image.h"" ").
:- pragma foreign_decl("C", "#include ""perlin.mh"" ").
:- pragma foreign_decl("C", "#include ""xorshift.mh"" ").

:- type args ---> args(
    seed::int,
    image_w::int,
    image_h::int,
    perlin_w::int,
    perlin_h::int,
    output::string).

:- pred parse_args(string::in, args::in, args::out) is det.

:- pred arg(string::in, string::in, string::in, int::out) is semidet.
:- pred arg(string::in, string::in, string::in, string::in, int::out) is semidet.

arg(Arg, Short, Long, Other, Output) :-
    ( string.remove_prefix(Arg, string.append("--", Other), X) ->
        string.to_int(X, Output)
    ;
        arg(Arg, Short, Long, Output)
    ).

arg(Arg, Short, Long, Output) :-
    ( string.remove_prefix(Arg, string.append("-", Short), X) ->
        string.to_int(X, Output)
    ; string.remove_prefix(Arg, string.append("--", Long), X) ->
        string.to_int(X, Output)
    ;
        false
    ).

parse_args(Arg, !Args) :-
    ( string.remove_prefix(Arg, "-o", Output) -> 
        !Args ^ output := Output
    ; string.remove_prefix(Arg, "--output=", Output) ->
        !Args ^ output := Output
    ; arg(Arg, "w", "width", W) ->
        !Args ^ image_w := W
    ; arg(Arg, "h", "height", H) ->
        !Args ^ image_h := H
    ; arg(Arg, "u", "perlinw", "pwidth", PW) ->
        !Args ^ perlin_w := PW
    ; arg(Arg, "v", "perlinh", "pheight", PH) ->
        !Args ^ perlin_h := PH
    ; arg(Arg, "s", "seed", S) ->
        !Args ^ seed := S
    ;
        true
    ).

main(!IO) :-
    io.command_line_arguments(Args, !IO),
    ArgsIn = args(9999101, 120, 120, 39, 39, "perlin.png"),
    list.foldl(parse_args, Args, ArgsIn, ArgsOut),
    ArgsOut = args(Seed, ImageW, ImageH, PW, PH, Path),
    cmain(Seed, ImageW, ImageH, PW, PH, 1, Path, !IO).

:- pragma foreign_proc("C",
    cmain(Seed::in, ImageW::in, ImageH::in, PW::in, PH::in, Island::in, Path::in, IO0::di, IO1::uo),
    [promise_pure, thread_safe, will_not_throw_exception, may_call_mercury],
    "
    struct AImg_Image image;
    
    float *const buffer = (float*)malloc(sizeof(float) * ImageW * ImageH);   
    float val_min = 0.0, val_max = 0.0;
    
    const unsigned passes = 6;
    unsigned pass = 0;
    
    image.w = ImageW;
    image.h = ImageH;

    IO1 = IO0;
    while(pass++ != passes){
        printf(""Beginning pass %i/%i...\\n"", pass, passes);
        const unsigned SeedZ = ((Seed << pass) ^ (Seed >> (pass + 1))) ^ Seed;
        unsigned x, y;
        const unsigned div = (pass == passes) ? pass + 1 : pass;
        for(y = 0; y < image.h; y++){
            const float ty = ((float)y / (float)image.h) * ((float)PH / div);
            for(x = 0; x < image.w; x++){
                const float tx = ((float)x / (float)image.w) * ((float)PW / div);
                const float value = Cinnabar_Perlin(SeedZ, tx, ty, PW / div, PH / div);
                const float a = ((value + 0.8f) / 1.6f);
                if(pass == 1){
                    buffer[x + (y * image.w)] = a;
                }
                else if(pass == passes){
                    buffer[x + (y * image.w)] *= a;
                }
                else{
                    buffer[x + (y * image.w)] += a;
                    buffer[x + (y * image.w)] /= 2.0f;
                }
                if(a > val_max)
                    val_max = value;
                else if(a < val_min)
                    val_min = value;
            }
            if(y % (image.h / 8) == 0)
                puts(""."");
        }
    }

    printf(""Values from %f to %f\\n"", val_min, val_max);
    puts(""Beginning rasterization..."");
        
    /* Very evil, we can reuse the buffer. */
    image.pixels = (void*)buffer;

    {
        unsigned x, y;
        float max_distance = 0.0;
        const unsigned range = ((image.w > image.h) ? image.w : image.h) >> 1;
        printf(""Max range is %u\\n"", range);
        int dy = -(image.h >> 1);
        for(y = 0; y < image.h; y++){
            int dx = -(image.w >> 1);
            dy++;
            for(x = 0; x < image.w; x++){
                dx++;
                float a = buffer[x + (y * image.w)];
                if(Island){
                    const float distance = sqrt((dx * dx) + (dy * dy));
                    if(distance > max_distance)
                        max_distance = distance;
                    a *= (distance > range) ? 0.0 : 1.0 - (distance / (float)range);
                }
                a *= 255.0f;
                const uint32_t color = AImg_RGBAToRaw(a, a, a, 255);
                AImg_SetPixel(&image, x, y, color);
            }
        }
        printf(""Max distance: %f\\n"", max_distance);
    }

    AImg_SaveAuto(&image, Path);
    free(image.pixels);
    
    puts(""Success!"");
    ").
