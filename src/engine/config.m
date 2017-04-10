:- module config.
%==============================================================================%
% Loads the config file.
:- interface.
%==============================================================================%

:- use_module io.
:- use_module window.

%------------------------------------------------------------------------------%

:- type backend ---> fltk ; glow.
:- type config ---> config(gl_version::window.gl_version,
    back::backend,
    w::int,
    h::int).

%------------------------------------------------------------------------------%

:- pred home_directory(string::uo, io.io::di, io.io::uo) is det.

:- pred load(config::uo, io.io::di, io.io::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module list.
:- import_module int.
:- use_module maybe.
:- use_module string.

:- pragma foreign_decl("C", "
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN 1
#define NOGDI 1
#define NOCRYPT 1
#include <Windows.h>
#include <stdlib.h>
#else
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#endif
").

:- pragma foreign_proc("C", home_directory(Home::uo, IO0::di, IO1::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "
    IO1 = IO0;
#ifdef _WIN32
    #define BUFFER_SIZE 0x400
    TCHAR buffer[BUFFER_SIZE];
    GetModuleFileName(NULL, buffer, BUFFER_SIZE);
    {
        short last_slash = -1;
        const TCHAR slash = (TEXT(""/""))[0];
        unsigned short i;
        for(i = 0; i < BUFFER_SIZE && buffer[i] != 0; i++){
            if(buffer[i] == slash)
                last_slash = i;
        }
        if(last_slash != -1)
            buffer[last_slash+1] = 0;
        else{
            buffer[i++] = slash;
            buffer[i] = 0;
        }
#if (defined UNICODE) || (defined _UNICODE) || (defined UNICODE_)
        {
            const unsigned len = i<<1;
            Home = MR_GC_malloc_atomic(len + 1);
            size_t rval;
            wcstombs_s(&rval, Home, len, buffer, len + 1);
        }
#else
        Home = MR_GC_malloc_atomic(i);
        memcpy(Home, buffer, i);
        Home[i] = 0;
#endif
    }
    #undef BUFFER_SIZE
#else
    const char *home_dir = getenv(""HOME"");
    if(home_dir == NULL){
        const struct passwd *const pw = getpwuid(getuid());
        home_dir = pw->pw_dir;
    }
    const unsigned len = strlen(home_dir);
    Home = MR_GC_malloc_atomic(len + 1);
    memcpy(Home, home_dir, len+1);
    if(Home[len-1] != '/'){
        Home[len] = '/';
        Home[len+1] = 0;
    }
#endif
    ").

:- pred config_fold(string::in, config::di, config::uo) is det.
config_fold(Line, !Config) :-
    string.split_at_char(('='), Line) = Strings,
    (
        Strings = []
    ;
        Strings = [_|[]]
    ;
        Strings = [Key|Values], Values = [_|_],
        string.join_list(("="), Values) = Value,
        ( Key = "window" ->
            ( Value = "fltk" -> 
                !Config ^ back := fltk
            ;
                !Config ^ back := glow
            )
        ; Key = "opengl" ->
            ( ( Value = "gl4" ; Value = "4") ->
                !Config ^ gl_version := window.gl_version(4, 0)
            ;
                !Config ^ gl_version := window.gl_version(2, 0)
            )
        ; Key = "windowed" ->
            ( ( Value = "true" ; Value = "True" ; Value = "1" ) ->
                true % TODO!
            ;
                true
            )
        ; (Key = "width"; Key = "w"), string.to_int(Value, W) ->
            !Config ^ w := W+0
        ; (Key = "height" ; Key = "h"), string.to_int(Value, H) ->
            !Config ^ h := H+0
        ;
            true % Write an error?
        )
    ).

:- pred read_file_as_lines(io.text_input_stream::in,
    list(string)::in, list(string)::out,
    io.io::di, io.io::uo) is det.

read_file_as_lines(Stream, LinesIn, LinesOut, !IO) :-
    io.read_line_as_string(Stream, LineResult, !IO),
    ( LineResult = io.ok(Line) ->
        read_file_as_lines(Stream, [Line|LinesIn], LinesOut, !IO)
    ;
        LinesOut = LinesIn
    ).


:- func copy_config(config::in, int::in, int::in) = (config::uo) is det.
copy_config(Config, W+0, H+0) = config(window.gl_version(Maj, Min), Back, W, H) :-
    Config ^ gl_version = window.gl_version(Maj+0, Min+0),
    (
        Config ^ back = fltk, Back = fltk
    ;
        Config ^ back = glow, Back = glow
    ).

load(Config, !IO) :-
    home_directory(Home, !IO),
    string.append(Home, ".cinnabar/cinnabar.ini", IniPath),
    io.open_input(IniPath, StreamResult, !IO),
    DefaultConfig = config(window.gl_version(2, 0), glow, -1, -1),
    (
        StreamResult = io.ok(Stream),
        read_file_as_lines(Stream, [], Lines, !IO),
        io.close_input(Stream, !IO),
        foldl(config_fold, Lines, DefaultConfig, FoldedConfig),
        ( FoldedConfig ^ w = -1 ->
            ( FoldedConfig ^ h = -1 ->
                Config = copy_config(FoldedConfig, 640, 480)
            ;
                H = FoldedConfig ^ h,
                Config = copy_config(FoldedConfig,
                    unchecked_quotient(unchecked_left_shift(H, 2), 3), H)
            )
        ; FoldedConfig ^ h = -1 ->
            W = FoldedConfig ^ w,
            Config = copy_config(FoldedConfig,
                W, unchecked_right_shift(W * 3, 2))
        ;
            FoldedConfig = Config
        )
    ;
        StreamResult = io.error(Error),
        io.write_string("Could not open config file: ", !IO),
        io.write_string(io.error_message(Error), !IO), io.nl(!IO),
        Config = config(window.gl_version(2, 0), glow, 640, 480)
    ).

%------------------------------------------------------------------------------%
