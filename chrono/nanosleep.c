#include "chrono.h"
#include <time.h>
#include <unistd.h>
#include <sys/time.h>
#include <unistd.h>

void Lightning_MicrosecondsSleep(unsigned microseconds){
    struct timespec t;
    unsigned long ns = microseconds * 1000;
    t.tv_sec = microseconds / 1000000;
    ns -= (t.tv_sec * 1000000000);
    t.tv_nsec = ns;

    nanosleep(&t, NULL);
}
