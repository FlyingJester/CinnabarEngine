#pragma once

struct Lantern_FileFinder;
unsigned Lantern_FileFinderSize();
unsigned Lantern_InitFileFinder(struct Lantern_FileFinder *finder, const char *path);
void Lantern_DestroyFileFinder(void *finder, void *unused);
char *Lantern_FileFinderPath(struct Lantern_FileFinder *finder);
unsigned long Lantern_FileFinderFileSize(const struct Lantern_FileFinder *finder);
unsigned Lantern_FileFinderNext(struct Lantern_FileFinder *finder);

#if (defined _WIN32) || (defined WIN32) || (defined __WIN32)
unsigned lantern_file_attrs_are_ok(unsigned long attrs);
#endif
