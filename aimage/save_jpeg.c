/*
 *    Copyright (c) 2017
 *        Martin McDonough (FlyingJester)
 *    All rights reserved.
 *
 *    This software is provided 'as-is', without any express or implied
 *    warranty. In no event will the authors be held liable for any damages
 *    arising from the use of this software.
 *
 *    Permission is granted to anyone to use this software for any purpose,
 *    including commercial applications, and to alter it and redistribute it
 *    freely, subject to the following restrictions:
 *
 *    1. Redistributions of source code must retain the above copyright
 *         notice, this list of conditions and the following disclaimer.
 *    2. Redistributions in binary form must reproduce the above copyright
 *         notice, this list of conditions and the following disclaimer in the
 *         documentation and/or other materials provided with the distribution.
 *    3. Neither the name of the Lightning Game Engine Group, the TurboSphere
 *         Organization, or AthenaTBS, nor the names of any contributors may be
 *         used to endorse or promote products derived from this software 
 *         without specific prior written permission.
 */

#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif

#include "image.h"
#include <setjmp.h>
#include <stdio.h>
#include <jpeglib.h>

static void aimg_jpeg_error(j_common_ptr ptr){
    jmp_buf *const jmpbuf = ptr->client_data;
    longjmp(*jmpbuf, 0xFF);
}

unsigned AIMG_FASTCALL AImg_SaveJPG(const struct AImg_Image *from, const char *path){
    jmp_buf jmpbuf;
    struct jpeg_compress_struct compress;
    struct jpeg_error_mgr error;
    FILE *const file = fopen(path, "wb");
    unsigned i;

    if(!file)
        return AIMG_LOADPNG_NO_FILE;

    if(setjmp(jmpbuf)){
        fclose(file);
#ifdef NDEBUG
        remove(path);
#endif
        return AIMG_LOADPNG_PNG_ERR;
    }

    jpeg_stdio_dest(&compress, file);
    
    jpeg_std_error(&error);
    error.error_exit = aimg_jpeg_error;

    compress.client_data = &jmpbuf;
    compress.err = &error;

    compress.image_width = from->w;
    compress.image_height = from->h;
    compress.input_components = 4;
    compress.in_color_space = JCS_EXT_RGBA;

    jpeg_set_defaults(&compress);
    jpeg_start_compress(&compress, 1);

    for(i = 0; i < from->h; i++){
        JSAMPLE *row = (JSAMPLE*)(from->pixels + (from->h * from->w));
        jpeg_write_scanlines(&compress, &row, 1);
    }

    jpeg_finish_compress(&compress);

    fflush(file);
    fclose(file);

    return AIMG_LOADPNG_SUCCESS;
}
