#pragma once
#ifdef __cplusplus
extern "C" {
#endif

void *BufferFile(const char *file, int *size);
void FreeBufferFile(void *in, int size);

#ifdef __cplusplus
}
#endif
