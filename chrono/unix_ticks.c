#include "chrono.h"
#include <sys/time.h>
#include <stdlib.h>

unsigned Lightning_GetMicrosecondsTime(){
    struct timeval t;
    gettimeofday(&t, NULL);
    {
        const unsigned long time_ms = t.tv_sec * 1000000;
        return time_ms + t.tv_usec;
    }
}

unsigned Lightning_GetMillisecondsTime(){
    struct timeval t;
    gettimeofday(&t, NULL);
    {
        unsigned long time_ms = t.tv_sec * 1000;
        time_ms += t.tv_usec / 1000;
        return time_ms;
    }
}
