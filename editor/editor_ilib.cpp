#include "editor_ilib.hpp"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

namespace CinEdit {

struct loader_raii{
    FILE *m_file;
    ilib *m_ilib;

    loader_raii(FILE *file, ilib *i = NULL)
      : m_file(file), m_ilib(i){
#ifndef NDEBUG
        m_err = NULL;
#endif
    }

    ~loader_raii(){
        if(m_file) fclose(m_file);
        if(m_ilib) m_ilib->clear();
        printErr();
    }

#ifndef NDEBUG
    bool ok(){ m_ilib = NULL; m_err = NULL; return true; }
    const char *m_err;
    void setErr(const char *e){ m_err = e; }
    void printErr(){
        if(m_err){
            fputs("Error ", stderr);
            fputs(m_err, stderr);
            fputc('\n', stderr);
        }
    }
#else
    bool ok(){ m_ilib = NULL; return true; }
    static void setErr(const char *){}
    static void printErr(){}
#endif

};

ilib::~ilib(){
    clear();
}

bool ilib::load(const std::string &path){
    clear();
    setPath(path);
    FILE *const input = fopen(path.c_str(), "rb");

    struct loader_raii lraii(input, this);
    lraii.setErr("opening file");
    if(!input)
        return false;

    lraii.setErr("reading signature");
    char sig[4];
    if(fread(sig, 1, 4, input) != 4)
        return false;
    
    lraii.setErr("verifying signature");
    if(memcmp(sig, "ilib", 4) != 0)
        return false;
    
    lraii.setErr("reading version");
    const unsigned version = (unsigned)fgetc(input);
    if(version != 1)
        return false;

    // reserved
    fgetc(input);
        
    const unsigned nitems =
        (((unsigned)fgetc(input) & 0xFF) << 8) |
        ((unsigned)fgetc(input) & 0xFF);
    
    {
        char buffer[24];
        lraii.setErr("seeking through reserved block");
        if(fread(buffer, 1, 24, input) != 24)
            return false;
    }
    
    // Make sure that freeing all the items will NOT chase uninitialized pointers.
    m_items.resize(nitems);
    for(unsigned i = 0; i < nitems; i++){
        m_items[i].name.str = NULL;
        m_items[i].name.len = 0;
        m_items[i].ItemTypeData.junk.JunkTypeData.book.text.str = NULL;
        m_items[i].ItemTypeData.junk.JunkTypeData.book.text.len = 0;
        m_items[i].model.str = NULL;
        m_items[i].model.len = 0;
        m_items[i].icon.str = NULL;
        m_items[i].icon.len = 0;
    }
    
    for(unsigned i = 0; i < nitems; i++){
        lraii.setErr("eof in item list");
        if(feof(input))
            return false;
        lraii.setErr("loading item");
        if(Bottle_LoadItemFile(&m_items[i], input) != BOTTLE_OK){
            // Resizing here avoids needing to do extra work in the raii finalizer.
            m_items.resize(i);
            return false;
        }
    }
    
    return lraii.ok();
}

bool ilib::save() const {
    FILE *const output = fopen(m_path.c_str(), "wb");
    
    struct loader_raii lraii(output, NULL);
    lraii.setErr("opening file");
    if(!output)
        return false;
    
    {
        const unsigned n = m_items.size();
        const char header[8] = {
            'i', 'l', 'i', 'b',
            (char)1, // Version
            (char)0xFF, // Reserved
            (char)((n >> 8) & 0xFF), // Size hi-word
            (char)((n >> 0) & 0xFF)  // Size lo-word
        };
        
        lraii.setErr("writing header");
        if(fwrite(header, 1, sizeof(header), output) != sizeof(header))
            return false;
    }

    {
        const unsigned reserved[24] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        lraii.setErr("writing reserved");
        if(fwrite(reserved, 1, 24, output) != 24)
            return false;
    }

    lraii.setErr("writing item");
    for(std::vector<BottleItem>::const_iterator i = m_items.begin();
        i != m_items.end(); i++){
        const BottleItem &item = *i;
        Bottle_WriteItemFile(&item, output);
        if(ferror(output) != 0)
            return false;
    }

    return lraii.ok();
}

/*
    BottleItem *getItems();
    const BottleItem *getItems() const;
    unsigned getNumItems() const;
    void erase(unsigned i);
    
    BottleItem *append();
private:
    std::vector<BottleItem> m_items;
    std::string m_path;
*/


BottleItem *ilib::getItems() {
    return &m_items.front();
}

const BottleItem *ilib::getItems() const {
    return &m_items.front();
}

unsigned ilib::getNumItems() const {
    return m_items.size();
}

void ilib::clear(){
    for(unsigned i = 0; i < m_items.size(); i++){
        free(m_items[i].name.str);
        if(m_items[i].ItemType == eJunk &&
            m_items[i].ItemTypeData.junk.JunkType == eBook)
            free(m_items[i].ItemTypeData.junk.JunkTypeData.book.text.str);
    }
    m_items.clear();
}

BottleItem &ilib::append(){
    m_items.resize(m_items.size() + 1);
    BottleItem &item = m_items.back();
    memset(&item, 0, sizeof(BottleItem));
    return item;
}

} // namespace CinEdit
