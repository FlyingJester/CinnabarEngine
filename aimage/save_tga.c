/*
 *    Copyright (c) 20152016
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
#include <stdio.h>

/* There's really no reason to not do RLE, if we do it properly.
 * This breaks Corona loading images saved by AImg. But that's Corona's
 * problem, not ours.
 * Unlike TurboSphere/Sapphire, we actually support homogenous AND
 * heterogenous blocks in AImg. This is why it's almost always better to
 * save with RLE.
 */

static const uint8_t aimg_max_block_size = 0x7F;

/* Targa dimensions are 16-bit, and blocks do not cross scanlines. Thus x and y are 16-bit. */
static uint8_t aimg_determine_block_size(const struct AImg_Image *from, 
    uint8_t i, uint16_t x, uint16_t y, unsigned(*cmp)(uint32_t, uint32_t)){
    if(i==0)
        return aimg_determine_block_size(from, 1, x, y, cmp);
    else if((unsigned)(x+i)>=from->w)
        return i;
    else if(i+1 >= aimg_max_block_size)
        return aimg_max_block_size;
    else{
        if(cmp(*AImg_PixelConst(from, x+i-1, y), *AImg_PixelConst(from, x+i, y)))
            return aimg_determine_block_size(from, i+1, x, y, cmp);
        else
            return i;
    }
}

static unsigned aimg_pix_same(uint32_t a, uint32_t b){
    return a==b;
}

static unsigned aimg_pix_diff(uint32_t a, uint32_t b){
    return a!=b;
}

static const char aimg_tga_id[] = "aimg";

static const char aimg_tga_header[] = {
    sizeof(aimg_tga_id), /* id length */
    0,  /* color map type */
    10, /* data type (always RLE RGBA) */
    0, 0, 0, 0, 0, /* color map data */
    0, 0, 0, 0 /* x, y origin (shorts) */
    /* Then write width, height as shorts, then bitsperpixel and "descriptor" as bytes. */
};

static void aimg_lo_hi_short(uint16_t in_, uint8_t out[2]){
    uint8_t *in = (void *)(&in_);
    out[0] = in[0];
    out[1] = in[1];
}

#define TGA_WRITE_RGBA(RGBA_UINT_, FILE_)\
    do{\
        const uint32_t PIXEL_ = RGBA_UINT_;\
        putc(AImg_RawToB(PIXEL_), FILE_);\
        putc(AImg_RawToG(PIXEL_), FILE_);\
        putc(AImg_RawToR(PIXEL_), FILE_);\
        putc(AImg_RawToA(PIXEL_), FILE_);\
    }while(0)

static void aimg_write_tga_pixels(const uint32_t *pixels, uint8_t remaining, FILE *file){
    if(remaining){
        TGA_WRITE_RGBA(*pixels, file);
        aimg_write_tga_pixels(pixels+1, remaining-1, file);
    }
}

unsigned AIMG_FASTCALL AImg_SaveTGA(const struct AImg_Image *from, const char *path){
    FILE *file;
    if(from->w > 0xFFFF || from->h > 0xFFFF){
        puts("AIMG_LOADPNG_NFORMAT");
        return AIMG_LOADPNG_NFORMAT;
    }
    if(!(file = fopen(path, "wb"))){
        puts("AIMG_LOADPNG_NO_FILE");
        return AIMG_LOADPNG_NO_FILE;
    }
    
    /* Write the header. */
    fwrite(aimg_tga_header, sizeof(aimg_tga_header), 1, file);
    {
        uint8_t dimensions[4];
        aimg_lo_hi_short(from->w, dimensions);
        aimg_lo_hi_short(from->h, dimensions + 2);
        fwrite(dimensions, 1, 4, file);
    }
    
    putc(32, file);
    putc(0x20 | 0x09, file);
    fwrite(aimg_tga_id, sizeof(aimg_tga_id), 1, file);
    {
        uint16_t x = 0, y = 0, run;
start_image:
        if((run = aimg_determine_block_size(from, 0, x, y, aimg_pix_same))==1){
            run = aimg_determine_block_size(from, 0, x, y, aimg_pix_diff);
            putc(run-1, file);
            aimg_write_tga_pixels(AImg_PixelConst(from, x, y), run, file);
        }
        else{
            putc(0x80 | (run-1), file);
            TGA_WRITE_RGBA(*AImg_PixelConst(from, x, y), file);
        }        

        x+=run;

        if(x>=from->w){
            x = 0;
            y++;
        }
        if(y<=from->h)
            goto start_image;
    }
    
    fflush(file);
    fclose(file);
    return AIMG_LOADPNG_SUCCESS;
}
