#include "ilib.h"

#include <stdlib.h>
#include <string.h>

static unsigned bottle_read_string_file(FILE *from, struct BottleString *to){
    const unsigned len = fgetc(from);
    to->len = len;
    to->str = (char*)malloc(len);
    {
        const unsigned nread = fread(to->str, 1, len, from);
        if(nread == len)
            return BOTTLE_OK;
        else
            return BOTTLE_FAIL;
    }
}

static unsigned bottle_read_string_mem(const void *from_v, unsigned from_len,
    const unsigned at, unsigned *const len_to, struct BottleString *to){
    
    unsigned i = at;
    const unsigned char *const from = from_v;
    
    if(from_len <= i + 1)
        return BOTTLE_FAIL;
    else{
        const unsigned len = from[i++];
        if(from_len <= i + len)
            return BOTTLE_FAIL;
        to->len = len;
        to->str = (char*)malloc(len);
        memcpy(to->str, from + i, len);
        len_to[0] = len;
    }
    
    return BOTTLE_OK;
}

static void bottle_write_string_file(FILE *to, const struct BottleString *from){
    fputc(from->len, to);
    fwrite(from->str, 1, from->len, to);
}

static void bottle_write_string_mem(void *to_v, unsigned *at,
    const struct BottleString *from){

    unsigned char *const to = to_v;
    to[*at] = from->len;
    memcpy(to + 1, from->str, from->len);
    at[0] += from->len+1;
}

void *Bottle_WriteItemMem(const struct BottleItem* from, unsigned *size_out){
}
void Bottle_WriteItemFile(const struct BottleItem* from, FILE *to){
    fwrite(&(from->weight), 1, 4, to);
    bottle_write_string_file(to, &(from->name));
    fwrite(&(from->value), 1, 4, to);
    fwrite(&(from->durability), 1, 4, to);
    {
        fputc(from->ItemType, to); 
        switch(from->ItemType){
            case eArmor:
                fwrite(&(from->ItemTypeData.armor.defense), 1, 4, to);
                { const unsigned i = from->ItemTypeData.armor.atype; fwrite(&i, 1, 4, to); };
            break;
            case eWeapon:
                { const unsigned i = from->ItemTypeData.weapon.wtype; fwrite(&i, 1, 4, to); };
                fwrite(&(from->ItemTypeData.weapon.speed), 1, 4, to);
                fwrite(&(from->ItemTypeData.weapon.attack), 1, 4, to);
            break;
            case eJunk:
                {
                    fputc(from->ItemTypeData.junk.JunkType, to); 
                    switch(from->ItemTypeData.junk.JunkType){
                        case eBook:
                            bottle_write_string_file(to, &(from->ItemTypeData.junk.JunkTypeData.book.text));
                        break;
                        case eGem:
                        break;
                    }
                }
            break;
            case eConsumable:
            break;
        }
    }
}
unsigned Bottle_LoadItemMem(struct BottleItem *out, const void *mem, unsigned len){
}
unsigned Bottle_LoadItemFile(struct BottleItem *out, FILE *from){
    if(feof(from) != 0) return BOTTLE_FAIL;
    fread(&(out->weight), 1, 4, from);
    if(feof(from) != 0) return BOTTLE_FAIL;
    bottle_read_string_file(from, &(out->name));
    if(feof(from) != 0) return BOTTLE_FAIL;
    fread(&(out->value), 1, 4, from);
    if(feof(from) != 0) return BOTTLE_FAIL;
    fread(&(out->durability), 1, 4, from);
    {
        out->ItemType = fgetc(from); 
        switch(out->ItemType){
        if(feof(from) != 0) return BOTTLE_FAIL;
            case eArmor:
                if(feof(from) != 0) return BOTTLE_FAIL;
                fread(&(out->ItemTypeData.armor.defense), 1, 4, from);
                if(feof(from) != 0) return BOTTLE_FAIL;
                { unsigned i; fread(&i, 1, 4, from);
                    out->ItemTypeData.armor.atype = i; }
            break;
        if(feof(from) != 0) return BOTTLE_FAIL;
            case eWeapon:
                if(feof(from) != 0) return BOTTLE_FAIL;
                { unsigned i; fread(&i, 1, 4, from);
                    out->ItemTypeData.weapon.wtype = i; }
                if(feof(from) != 0) return BOTTLE_FAIL;
                fread(&(out->ItemTypeData.weapon.speed), 1, 4, from);
                if(feof(from) != 0) return BOTTLE_FAIL;
                fread(&(out->ItemTypeData.weapon.attack), 1, 4, from);
            break;
        if(feof(from) != 0) return BOTTLE_FAIL;
            case eJunk:
                {
                    out->ItemTypeData.junk.JunkType = fgetc(from); 
                    switch(out->ItemTypeData.junk.JunkType){
                    if(feof(from) != 0) return BOTTLE_FAIL;
                        case eBook:
                            if(feof(from) != 0) return BOTTLE_FAIL;
                            bottle_read_string_file(from, &(out->ItemTypeData.junk.JunkTypeData.book.text));
                        break;
                    if(feof(from) != 0) return BOTTLE_FAIL;
                        case eGem:
                        break;
                    }
                }
            break;
        if(feof(from) != 0) return BOTTLE_FAIL;
            case eConsumable:
            break;
        }
    }
}
