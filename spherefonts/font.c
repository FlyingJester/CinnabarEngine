#include "font.h"
#include "cynical.inc"
#include <stdlib.h>
#include <string.h>
#include <assert.h>

bool Sphere_LoadFontMem(struct Sphere_Font *to, const uint32_t *mem, const uint64_t size){
	assert(to);
	
	if(size < 64)
		return false;
	
	to->master.w = to->master.h = 0;
	
#ifdef __EMSCRIPTEN__
    mem = (uint32_t *)(((uint8_t*)(mem))-1);
#endif

#ifdef __EMSCRIPTEN__
	if(mem[0]!=0x66722e82) return false;
#else
	if(mem[0]!=0x6e66722e) return false;
#endif
	
    if(((const uint16_t *)(&mem[1]))[0] != 2)
		return false;
	
	{
		unsigned i, offset = 64, width;
		const unsigned num_chars = ((const uint16_t *)(&mem[1]))[1];
		/* Real data starts at 64. */
		
		/* Determine width and height. */
		for(i = 0; i < 0xFF && i < num_chars; i++){
			const unsigned w = ((const uint16_t *)(mem + offset))[0],
				h = ((const uint16_t *)(mem + offset))[1];
			
			to->master.w += w;
			if(h > to->master.h)
				to->master.h = h;
			
			offset+=8;
			offset += w * h;
		}
		
		/* Create glyphs and copy chars */
		to->master.data = malloc(to->master.w * to->master.h << 2);
		
		offset = 64;
		for(width = i = 0; i < 0xFF && i < num_chars; i++){
			const unsigned w = ((const uint16_t *)(mem + offset))[0],
				h = ((const uint16_t *)(mem + offset))[1];
			unsigned y;
			
			assert(width < to->master.w);
			assert(h <= to->master.h);
			
			offset += 8;
			
			to->glyphs[i].x = width;
			to->glyphs[i].w = w;
			to->glyphs[i].h = h;
			
			/* Copy the scanlines */
			for(y = 0; y < h; y++){
				
				#ifndef NDEBUG
				if(i >= 'A' && i <= 'Z'){
					unsigned z;
					for(z = 0; z < w; z++){
						
					}
				}
				#endif
				memcpy(to->master.data + width + (to->master.w * y), mem + offset + (y * w), w << 2);
			}
			
			width += w;
			offset += w * h;
		}
		
		assert(width == to->master.w);
		
		for(; i < 0xFF; i++)
			to->glyphs[i].x = to->glyphs[i].w = to->glyphs[i].h = 0;
		
	}
	
	return true;
}

uint64_t Sphere_StringWidth(const struct Sphere_Font *font, const char *str, uint16_t n){
	unsigned i = 0, width = 0;
	assert(font);
	while(i < n){
		const struct Sphere_Glyph *const glyph = Sphere_GetBoundedGlyph(font, str[i]);
		width += glyph->w;
		i++;
	}
    
	return width;
}

const struct Sphere_Glyph *Sphere_GetBoundedGlyph(const struct Sphere_Font *font, unsigned i){
	assert(font);
	if(i > 0xFF || i < 0x0F)
		return font->glyphs + (int)' ';
	else
		return font->glyphs + i;
}

static struct Sphere_Font system_font_z, *system_font = NULL;
const struct Sphere_Font *Sphere_GetSystemFont(){
	if(!system_font){
		system_font = &system_font_z;
		Sphere_LoadFontMem(system_font, (uint32_t *)res_fonts_cynical_rfn, res_fonts_cynical_rfn_len);
	}
	
	return system_font;
}
