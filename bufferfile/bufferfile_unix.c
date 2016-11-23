#include "bufferfile.h"
#include <stdlib.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>

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
        char *buffer = NULL;

        if(fd<=0){
            write(STDERR_FILENO, cannot_write_string, cannot_write_string_len);
            write(STDERR_FILENO, file, b_strlen(file));
            write(STDERR_FILENO, "\n", 1);
            return NULL;
        }

        fstat(fd, &lstat);

        size[0] = lstat.st_size;

        buffer = malloc(lstat.st_size);
        read(fd, buffer, lstat.st_size);
        
        return buffer;
    }
}

void FreeBufferFile(void *in, int X){
    if(!X) return;
    free(in);
}
