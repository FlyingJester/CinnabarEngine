:- module bufferfile.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module io.
:- use_module buffer.

:- type file.

:- pred bufferfile(string::in, io.res(buffer.buffer)::out, io.io::di, io.io::uo) is det.

:- pred open(string::in, io.res(file)::uo, io.io::di, io.io::uo) is det.
:- func size(file) = int.
:- pred map(file::in, int::in, buffer.buffer::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- func create_ok_file(file) = io.res(file).
:- mode create_ok_file(di) = (uo) is det.
:- mode create_ok_file(in) = (out) is det.
create_ok_file(File) = io.ok(File).
:- pragma foreign_export("C", create_ok_file(di) = uo, "MerBufferFile_OKFile").

:- func create_error_file(string) = io.res(file).
create_error_file(Str) = io.error(io.make_io_error(Str)).
:- pragma foreign_export("C", create_error_file(in) = out, "MerBufferFile_ErrorFile").

:- pragma foreign_decl("C",
    "
#include ""buffer.mh""

#ifdef _WIN32

#include <Windows.h>
typedef HANDLE MerBufferFile_FileDeref;
#define BUFFERFILE_FILE_OK(F) (F)

#else

#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <assert.h>
typedef int MerBufferFile_FileDeref;
#define BUFFERFILE_FILE_OK(F) (F>=0)

#endif

typedef MerBufferFile_FileDeref *MerBufferFile_File;
void MerBufferFile_BufferFinalizer(void *buf, void *unused);
void MerBufferFile_FileFinalizer(void *data, void *unused);
").

:- pragma foreign_code("C","
#ifdef _WIN32

void MerBufferFile_BufferFinalizer(void *buf, void *unused){
    (void)unused;
    UnmapViewOfFile(((struct M_Buffer*)buf)->data);
}

void MerBufferFile_FileFinalizer(void *data, void *unused){
    CloseHandle(*(MerBufferFile_File)data);
}

#else

void MerBufferFile_BufferFinalizer(void *data, void *unused){
    (void)unused;
    const struct M_Buffer *const buffer = (struct M_Buffer *)data;
    munmap(buffer->data, buffer->size);
}

void MerBufferFile_FileFinalizer(void *data, void *unused){
    close(*(MerBufferFile_File)data);
}
#endif
    ").

:- pragma foreign_type("C", file, "MerBufferFile_File").

:- pragma foreign_proc("C", open(Path::in, MaybeFile::uo, IO0::di, IO1::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness, tabled_for_io],
    "
    const MerBufferFile_FileDeref file =
#ifdef _WIN32
        CreateFile(Path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL, NULL);
#else
        open(Path, O_RDONLY);
#endif

    if(BUFFERFILE_FILE_OK(file)){
        MerBufferFile_File out =
            MR_GC_malloc_atomic(sizeof(MerBufferFile_File));
        out[0] = file;
        MR_GC_register_finalizer(out, MerBufferFile_FileFinalizer, NULL);
        MaybeFile = MerBufferFile_OKFile(out);
    }
    else{
        const char err[] = ""Could not open file"";
        char *output_err = MR_GC_malloc_atomic(sizeof(err));
        memcpy(output_err, err, sizeof(err));
        MaybeFile = MerBufferFile_ErrorFile(output_err);
    }
    IO1 = IO0;
    ").

:- pragma foreign_proc("C", size(File::in) = (Size::out),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness],
    "
#ifdef _WIN32
        Size = GetFileSize(*File, NULL);
#else
    {
        struct stat lstat;
        fstat(*File, &lstat);
        Size = lstat.st_size;
    }
#endif
    ").

:- pragma foreign_proc("C", map(File::in, Len::in, Buffer::uo),
    [will_not_call_mercury, promise_pure, will_not_throw_exception,
     thread_safe, does_not_affect_liveness, tabled_for_io],
    "
        struct M_Buffer* const buffer = MR_GC_malloc_atomic(sizeof(struct M_Buffer));
        buffer->size = Len;
#ifdef _WIN32
        {
            HANDLE mmiofile = CreateFileMapping(*File, NULL, PAGE_READONLY, 0, 0, NULL);
            buffer->data = MapViewOfFile(mmiofile, FILE_MAP_READ, 0, 0, Len);
            CloseHandle(mmiofile);
        }
#else
        buffer->data = mmap(NULL, Len, PROT_READ, MAP_SHARED, *File, 0);
#endif
        MR_GC_register_finalizer(buffer, MerBufferFile_BufferFinalizer, File);
        Buffer = buffer;
    ").

bufferfile(Name, MaybeOutput, !IO) :-
    open(Name, MaybeFile, !IO),
    (
        MaybeFile = io.ok(File),
        MaybeOutput = io.ok(Buffer),
        map(File, size(File), Buffer)
    ;
        MaybeFile = io.error(Err),
        MaybeOutput = io.error(Err)
    ).
