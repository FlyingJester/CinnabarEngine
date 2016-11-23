:- module aimg.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
%------------------------------------------------------------------------------%

:- type texture.
:- func width(texture) = int.
:- func height(texture) = int.

:- type result ---> ok(texture) ; nofile ; badfile.

:- pred load(io.io::di, io.io::uo, string::in, result::out) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- func create_nofile = result.
:- func create_badfile = result.
:- func create_ok(texture) = result.

create_nofile = nofile.
create_badfile = badfile.
create_ok(I) = ok(I).

:- pragma foreign_export("C", create_nofile = (out), "Aimg_Mercury_CreateNoFile").
:- pragma foreign_export("C", create_badfile = (out), "Aimg_Mercury_CreateBadFile").
:- pragma foreign_export("C", create_ok(in) = (out), "Aimg_Mercury_CreateOK").

:- pragma foreign_decl("C", "#include ""aimage/image.h"" ").
:- pragma foreign_type("C", texture, "struct AImg_Image*").

:- pragma foreign_proc("C", width(Image::in) = (W::out), 
    [promise_pure, thread_safe, will_not_call_mercury, will_not_throw_exception],
    " W = Image->w; ").

:- pragma foreign_proc("C", height(Image::in) = (H::out), 
    [promise_pure, thread_safe, will_not_call_mercury, will_not_throw_exception],
    " H = Image->h; ").

:- pragma foreign_proc("C", load(IO0::di, IO1::uo, Path::in, Result::out), 
    [promise_pure, thread_safe, will_not_throw_exception],
    "
    IO1 = IO0;
    {
        struct AImg_Image im;
        const unsigned err = AImg_LoadAuto(&im, Path);
        if(err == AIMG_LOADPNG_SUCCESS){
            struct AImg_Image *const image = MR_GC_malloc_atomic(sizeof(struct AImg_Image));
            image->pixels = im.pixels;
            image->w = im.w;
            image->h = im.h;
            Result = Aimg_Mercury_CreateOK(image);
        }
        else if(err == AIMG_LOADPNG_NO_FILE)
            Result = Aimg_Mercury_CreateNoFile();
        else
            Result = Aimg_Mercury_CreateBadFile();
    }
    ").


