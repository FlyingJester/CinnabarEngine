:- module aimg.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
%------------------------------------------------------------------------------%

:- type texture.
:- func width(texture) = int.
:- func height(texture) = int.

:- type pixels.

:- func pixels(texture) = pixels.
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

:- pragma foreign_type("C", pixels, "unsigned char*").
:- pragma foreign_type("Java", pixels, "int[]").

:- pragma foreign_export("C",    create_nofile = (out), "Aimg_Mercury_CreateNoFile").
:- pragma foreign_export("Java", create_nofile = (out), "CreateAImgNoFile").
:- pragma foreign_export("C",    create_badfile = (out), "Aimg_Mercury_CreateBadFile").
:- pragma foreign_export("Java", create_badfile = (out), "CreateAimgBadFile").
:- pragma foreign_export("C",    create_ok(in) = (out), "Aimg_Mercury_CreateOK").
:- pragma foreign_export("Java", create_ok(in) = (out), "CreateAImgOK").

:- pragma foreign_decl("C", "#include ""aimage/image.h"" ").
:- pragma foreign_decl("C", "void AImg_Finalizer(void *image, void *unused);").
:- pragma foreign_type("C", texture, "struct AImg_Image*").
:- pragma foreign_code("C", "
void AImg_Finalizer(void *image, void *unused){
    AImg_DestroyImage(image);
    (void)image;
}
").

:- pragma foreign_decl("Java", "import java.awt.image.BufferedImage;").
:- pragma foreign_decl("Java", "import java.io.*;").
:- pragma foreign_decl("Java", "import javax.imageio.ImageIO;").
:- pragma foreign_type("Java", texture, "BufferedImage").

:- pragma foreign_proc("C", pixels(Image::in) = (Pix::out), 
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " Pix = (MR_Word)Image->pixels; ").

:- pragma foreign_proc("C", width(Image::in) = (W::out), 
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " W = Image->w; ").

:- pragma foreign_proc("C", height(Image::in) = (H::out), 
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
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
            MR_GC_register_finalizer(image, AImg_Finalizer, NULL);
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

:- pragma foreign_proc("Java", pixels(Image::in) = (Pix::out), 
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    "
        const int w = Image.getWidth();
        const int h = Image.getHeight();
        Pix = Image.getRGB(0, 0, w, h, null, 0, w);
    ").

:- pragma foreign_proc("Java", width(Image::in) = (W::out), 
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " W = Image.getWidth(); ").

:- pragma foreign_proc("Java", height(Image::in) = (H::out), 
    [will_not_call_mercury, will_not_throw_exception,
     thread_safe, promise_pure, does_not_affect_liveness],
    " H = Image.getHeight(); ").

:- pragma foreign_proc("Java", load(IO0::di, IO1::uo, Path::in, Result::out), 
    [promise_pure, thread_safe, will_not_throw_exception],
    "
        IO1 = IO0;
        File file = new File(Path);
        if(file.exists() && file.canRead()){
            try{
                
                BufferedImage image = ImageIO.read(file);
                Result = CreateAImgOK(image);
            }
            catch(IOException err){
                Result = CreateAImgBadFile();
            }
        } // file.exists and file.canRead
        else{
            Result = CreateAImgNoFile();
        }
    ").

