#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void Lightning_MicrosecondsSleep(unsigned);
unsigned Lightning_GetMicrosecondsTime(void);
unsigned Lightning_GetMillisecondsTime(void);

#ifdef __cplusplus
}
#endif
