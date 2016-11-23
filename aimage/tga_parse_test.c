#include "image.h"
#include <stdio.h>

int main(int argc, char *argv[]){
    if(argc<3){
        puts("Usage: tga_parse_test <infile> <outfile>");
        return 0;
    }
    else{
        struct AImg_Image img;
        if(AImg_LoadTGA(&img, argv[1])!=AIMG_LOADPNG_SUCCESS){
            fputs("Cannot load file: ", stdout);
            puts(argv[1]);
        }
        else if(AImg_SaveTGA(&img, argv[2])!=AIMG_LOADPNG_SUCCESS){
            fputs("Cannot save file: ", stdout);
            puts(argv[2]);
        }
        return 0;
    }
}
