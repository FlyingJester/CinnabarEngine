/*
 *    Copyright (c) 2015-2016
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

#include "image.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <string.h>

#define AIMG_MIN(A, B) (((A)>(B))?(B):(A))

void AImg_CloneImage(struct AImg_Image *to, const struct AImg_Image *from){
    const unsigned pix_size = from->w * from->h << 2;
    to->w = from->w;
    to->h = from->h;   
    
    to->pixels = malloc(pix_size);
    memcpy(to->pixels, from->pixels, pix_size);
}

void AImg_DestroyImage(struct AImg_Image *that){
    free(that->pixels);
    that->pixels = NULL;
    that->w = that->h = 0;
}

void AImg_CreateImage(struct AImg_Image *that, unsigned w, unsigned h){
    that->w = w;
    that->h = h;

    that->pixels = calloc(w<<1, h<<1);
}

static unsigned AImg_LowerBlitWidth(const struct AImg_Image *src, const struct AImg_Image *dst, unsigned x){
    const unsigned clip = dst->w - x;
    if(src->w<clip)
        return src->w;
    else
        return clip;
}

#ifndef ATHENA_DISABLE_OPT_BLEND

static unsigned aimg_find_solid_block(const struct AImg_Image *src, unsigned x, unsigned y){
/* the > 0xFA is a Slightly greedy fudge to improve performance. */
    if(x < src->w && AImg_RawToA( *AImg_PixelConst(src, x, y) ) > 0xFC)
        return aimg_find_solid_block(src, x+1, y);

    return x;
}

static unsigned aimg_find_empty_block(const struct AImg_Image *src, unsigned x, unsigned y){
/* the < 0x08 is a Slightly greedy fudge to improve performance. */
    if(x < src->w && AImg_RawToA( *AImg_PixelConst(src, x, y) ) < 0x04)
        return aimg_find_empty_block(src, x+1, y);

    return x;
}

#endif

static int aimg_blit_scanline_blended_iter(const struct AImg_Image *src, struct AImg_Image *dst,
    int x, int y, unsigned w, unsigned h, unsigned laser_x, unsigned laser_y){

    if(laser_y >= h)
        return 0;
    else if(laser_x >= w)
        return aimg_blit_scanline_blended_iter(src, dst, x, y, w, h, 0, laser_y + 1);
    else{

        uint32_t *pixel_to = AImg_Pixel(dst, x + laser_x, y + laser_y);
        const uint32_t *pixel_from = AImg_PixelConst(src, laser_x, laser_y);
#ifndef ATHENA_DISABLE_OPT_BLEND
        const unsigned empty_x = aimg_find_empty_block(src, laser_x, laser_y),
            solid_x = aimg_find_solid_block(src, laser_x, laser_y);
        if(solid_x > laser_x){
            const unsigned len = AIMG_MIN(solid_x - laser_x, w - laser_x);
            memcpy(pixel_to, pixel_from, len << 2);
            return aimg_blit_scanline_blended_iter(src, dst, x, y, w, h, laser_x + len, laser_y);
        }
        else if(empty_x > laser_x){
            /* Just skip the zero alpha area */
            return aimg_blit_scanline_blended_iter(src, dst, x, y, w, h, empty_x, laser_y);
        }
        else
#endif
        {
            pixel_to[0] = AImg_RGBARawBlend(*pixel_from, *pixel_to);
            return aimg_blit_scanline_blended_iter(src, dst, x, y, w, h, laser_x + 1, laser_y);
        }
    }
}


void AImg_Blit(const struct AImg_Image *src, struct AImg_Image *dst, int x, int y){
    assert(src);
    assert(dst);
    if(x < (long)dst->w && y < (long)dst->h && x + (long)src->w > 0 && y + (long)src->h > 0){
        const unsigned len = AImg_LowerBlitWidth(src, dst, x);

        aimg_blit_scanline_blended_iter(src, dst, x, y, len, AIMG_MIN(src->h, dst->h - y), 0, 0);
    }
}

void AImg_SetPixel(struct AImg_Image *to, int x, int y, uint32_t color){
    if(x < 0 || y < 0 || x >= (long)to->w || y >= (long)to->h)
        return;
    AImg_Pixel(to, x, y)[0] = color;
}

uint32_t AImg_GetPixel(struct AImg_Image *to, int x, int y){
    if(x < 0 || y < 0 || x >= (long)to->w || y >= (long)to->h)
        return 0;
    return *AImg_Pixel(to, x, y);
}


uint32_t *AImg_Pixel(struct AImg_Image *to, int x, int y){
    return (uint32_t *)AImg_PixelConst(to, x, y);
}

const uint32_t *AImg_PixelConst(const struct AImg_Image *to, int x, int y){
    return to->pixels + x + (y * to->w);
}

/* 0xFF00FFFF is yellow. That is all. */

uint32_t AImg_RGBAToRaw(uint8_t r, uint8_t g, uint8_t b, uint8_t a){
    return (a << 24) | (b << 16) | (g << 8) | (r);
}

void AImg_RawToRGBA(uint32_t rgba, uint8_t *r, uint8_t *g, uint8_t *b, uint8_t *a){
    r[0] = rgba & 0xFF;
    rgba >>= 8;
    g[0] = rgba & 0xFF;
    rgba >>= 8;
    b[0] = rgba & 0xFF;
    rgba >>= 8;
    a[0] = rgba & 0xFF;
}

uint8_t AImg_RawToR(uint32_t rgba){
    return rgba & 0xFF;
}

uint8_t AImg_RawToG(uint32_t rgba){
    return (rgba >> 8) & 0xFF;
}

uint8_t AImg_RawToB(uint32_t rgba){
    return (rgba >> 16) & 0xFF;
}

uint8_t AImg_RawToA(uint32_t rgba){
    return (rgba >> 24) & 0xFF;
}

static void aimg_flip_image_vertically_iter(const struct AImg_Image *from, struct AImg_Image *to, uint32_t *buffer, unsigned line){
    if(line > from->h >> 1){
        return;
    }

    memcpy(buffer, AImg_PixelConst(from, 0, line), from->w << 2);
    memcpy(AImg_Pixel(to, 0, line), AImg_PixelConst(from, 0, from->h - line - 1), from->w << 2);
    memcpy(AImg_Pixel(to, 0, from->h - line - 1), buffer, from->w << 2);
    aimg_flip_image_vertically_iter(from, to, buffer, line + 1);
}

void AImg_FlipImageVertically(const struct AImg_Image *from, struct AImg_Image *to){
    if(from->w > to->w || from->h > to->h)
        return;
    else{
        uint32_t * const row_buffer = calloc(4, from->w);
        aimg_flip_image_vertically_iter(from, to, row_buffer, 0);
        free(row_buffer);
    }
}

uint32_t AImg_RGBABlend(uint8_t src_r, uint8_t src_g, uint8_t src_b, uint8_t src_a, uint8_t dst_r, uint8_t dst_g, uint8_t dst_b, uint8_t dst_a){

    float accum_r = ((float)dst_r)/255.0f, accum_g = ((float)dst_g)/255.0f, accum_b = ((float)dst_b)/255.0f;
    
    const float src_factor = ((float)src_a)/255.0f, dst_factor = 1.0f - src_factor;
    
    accum_r = (accum_r * dst_factor) + ((((float)src_r)/255.0f) * src_factor);
    accum_g = (accum_g * dst_factor) + ((((float)src_g)/255.0f) * src_factor);
    accum_b = (accum_b * dst_factor) + ((((float)src_b)/255.0f) * src_factor);

    if(dst_a){} /* Unused param */

    return AImg_RGBAToRaw(accum_r * 255.0f, accum_g * 255.0f, accum_b * 255.0f, 0xFF);
}

#define AIMG_DECONSTRUCT_BLENDER(NAME)\
uint32_t AImg_RGBARaw ## NAME(uint32_t src, uint32_t dst){\
    uint8_t src_r, src_g, src_b, src_a, dst_r, dst_g, dst_b, dst_a;\
    AImg_RawToRGBA(src, &src_r, &src_g, &src_b, &src_a);\
    AImg_RawToRGBA(dst, &dst_r, &dst_g, &dst_b, &dst_a);\
    return AImg_RGBA ## NAME(src_r, src_g, src_b, src_a, dst_r, dst_g, dst_b, dst_a);\
}

AIMG_DECONSTRUCT_BLENDER(Blend)

#undef AIMG_DECONSTRUCT_BLENDER

unsigned AImg_LoadAuto(struct AImg_Image *to, const char *path){
    const char * const end = path + strlen(path), *str = end;
    while(str[0] != '.'){
        if(str==path)
            return AIMG_LOADPNG_NFORMAT;
        str--;
    }
    
    if(end - str == 4){
        if(memcmp(str, ".png", 4)==0)
            return AImg_LoadPNG(to, path);
        else if(memcmp(str, ".tga", 4)==0)
            return AImg_LoadTGA(to, path);
    }
    return AIMG_LOADPNG_NFORMAT;
}

unsigned AImg_SaveAuto(const struct AImg_Image *from, const char *path){
    const char * const end = path + strlen(path), *str = end;
    while(str[0] != '.'){
        if(str==path)
            return AIMG_LOADPNG_NFORMAT;
        str--;
    }
    
    if(end - str == 4){
        if(memcmp(str, ".png", 4)==0)
            return AImg_SavePNG(from, path);
        else if(memcmp(str, ".tga", 4)==0)
            return AImg_SaveTGA(from, path);
    }
    return AIMG_LOADPNG_NFORMAT;
}
