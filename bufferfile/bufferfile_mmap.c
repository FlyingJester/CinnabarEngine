#include "bufferfile.h"
#include <stdlib.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <assert.h>

#if (defined __GNUC__) && __GNUC__ > 3
#pragma GCC diagnostic ignored "-Wunused-result"
#endif

static const char cannot_write_string[] = "[BufferFile] Could not open file ";
static const unsigned cannot_write_string_len = (sizeof cannot_write_string) - 1;

static unsigned b_strlen(const char *x){
    unsigned i = 0;
    while(x[i]) i++;
    return i;
}

void *BufferFile(const char *file, int *size){
    if(!file || !size){
        return NULL;
    }
    else{
        const int fd = open(file, O_RDONLY);
        struct stat lstat;

        if(fd<=0){
            write(STDERR_FILENO, cannot_write_string, cannot_write_string_len);
            write(STDERR_FILENO, file, b_strlen(file));
            write(STDERR_FILENO, "\n", 1);
            
            return NULL;
        }

        fstat(fd, &lstat);
        size[0] = lstat.st_size;
        {
            void *data = mmap(NULL, lstat.st_size, PROT_READ, MAP_SHARED, fd, 0);
            if(data!=MAP_FAILED)
                return data;
            else
                return NULL;
        }
    }
}

void FreeBufferFile(void *in, int size){
    munmap(in, size);
}
