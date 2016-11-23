#if (!defined(__APPLE__)) || ((defined(__FreeBSD__)) && (__FreeBSD__ < 9))

static void memset_pattern4(void *to, const void *pattern, unsigned long len){
    while(len--)
        ((unsigned char *)to)[len] = ((unsigned char *)pattern)[len % 4];
}

#else

#include <string.h>

#endif
