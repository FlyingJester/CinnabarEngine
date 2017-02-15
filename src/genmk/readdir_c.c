
static const char *lantern_file_finder_path_inner(const struct Lantern_FileFinder *finder);

#if (defined _WIN32) || (defined WIN32) || (defined __WIN32)

#include <Windows.h>

struct Lantern_FileFinder{
	WIN32_FIND_DATA data;
	HANDLE find;
    char *filename;
};

unsigned lantern_file_attrs_are_ok(unsigned long attrs){
    return (attrs == FILE_ATTRIBUTE_NORMAL ||
        (attrs & (FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_TEMPORARY | FILE_ATTRIBUTE_ARCHIVE)) == attrs);
}

unsigned Lantern_InitFileFinder(struct Lantern_FileFinder *finder, const char *path){
	
	char lpath[0x103];
	unsigned i = 0;
	
	finder->filename = NULL;
	
	if(path == NULL || path[0] == '\\0'){
		lpath[0] = '*';
		lpath[1] = '\\0';
	}
	else{
	
		while(path[i] != '\\0' && i + 2 < sizeof(lpath)){
			lpath[i] = path[i];
			i++;
		}
		
		if(path[i-1] != '/')
			lpath[i] = '/';
		else
			i--;
		lpath[i+1] = '*';
		lpath[i+2] = '\\0';
	}
	
	if ((finder->find = FindFirstFileA(lpath, &finder->data)) == INVALID_HANDLE_VALUE)
        return 0;
    while((!lantern_file_attrs_are_ok(finder->data.dwFileAttributes)) || finder->data.cFileName[0] == '.'){
		if(FindNextFile(finder->find, &finder->data) == 0)
			return 0;
    }
    return 1;
}

void Lantern_DestroyFileFinder(void *f, void *_){
    (void)_;
	FindClose(((struct Lantern_FileFinder*)f)->find);
}

unsigned long Lantern_FileFinderFileSize(const struct Lantern_FileFinder *finder){
	return finder->data.nFileSizeLow;
}

unsigned Lantern_FileFinderNext(struct Lantern_FileFinder *finder){
	do{
		if(FindNextFile(finder->find, &finder->data) == 0)
			return 0;
	}while((!lantern_file_attrs_are_ok(finder->data.dwFileAttributes)) || finder->data.cFileName[0] == '.');
	finder->filename = NULL;
	return 1;
}

static const char *lantern_file_finder_path_inner(const struct Lantern_FileFinder *finder){
	return finder->data.cFileName;
}

#else

#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>

struct Lantern_FileFinder{
    struct dirent *dirt;
    DIR *dir;
    char *filename;
};

unsigned Lantern_InitFileFinder(struct Lantern_FileFinder *finder, const char *path){
    if(finder)
        finder->filename = NULL;
    return finder && path && (finder->dir = opendir(path)) != NULL;
}

void Lantern_DestroyFileFinder(void *f, void *_){
    (void)_;
	closedir(((struct Lantern_FileFinder*)f)->dir);
}

unsigned long Lantern_FileFinderFileSize(const struct Lantern_FileFinder *finder){
    struct stat st;
    
    if(!finder->dirt)
        return 0;
    
    stat(finder->dirt->d_name, &st);
    return st.st_size;
}

unsigned Lantern_FileFinderNext(struct Lantern_FileFinder *finder){
    finder->filename = NULL;
    return (finder->dirt = readdir(finder->dir)) != NULL;
}

static const char *lantern_file_finder_path_inner(const struct Lantern_FileFinder *finder){
    return finder->dirt ? finder->dirt->d_name : """";
}

#endif

char *Lantern_FileFinderPath(struct Lantern_FileFinder *finder){
    if(finder->filename == NULL){
        const char *const str = lantern_file_finder_path_inner(finder);
        const unsigned len = strlen(str);
        finder->filename = (char*)MR_GC_malloc_atomic(len+1);
        memcpy(finder->filename, str, len+1);
    }
    return finder->filename;
}

unsigned Lantern_FileFinderSize(){
    return sizeof(struct Lantern_FileFinder);
}
