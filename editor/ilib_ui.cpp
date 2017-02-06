#include "ilib_ui.h"

#include "cinedit.ilib.mh"

#include "editor_ui.hpp"

#include "aimage/image.h"

#include <FL/Fl_Image.H>

#include <cassert>
#include <string>
#include <stack>
#include <vector>

static char interned_empty_string[1] = {'\0'};

static MR_String create_mr_string(const char *string){
    if(string == NULL || *string == '\0')
        return interned_empty_string;
    const unsigned len = strlen(string);
    char *const string_copy = (char*)MR_GC_malloc_atomic(len + 1);
    memcpy(string_copy, string, len + 1);
    return string_copy;
}

// A container for MR_Words that uses the GC allocation functions to be sure
// the GC can find them. This ensures that we won't have a word freed while
// we still have a reference to it, since all GC-able words must be referenced
// in GC-allocated memory.
class WordHolder{
    MR_Word *m_data;
    unsigned m_size, m_capacity;
public:
    typedef MR_Word value_type;
    typedef MR_Word &reference;
    typedef const MR_Word &const_reference;
    typedef unsigned size_type;
    
    WordHolder()
      : m_data(NULL)
      , m_size(0)
      , m_capacity(0){
        
    }
    
    MR_Word &back(){
        assert(m_size > 0);
        return m_data[m_size - 1];
    }
    
    MR_Word back() const {
        assert(m_size > 0);
        return m_data[m_size - 1];
    }
    
    bool empty() const { return m_size == 0; }
    
    void push_back(MR_Word word) {
        assert(m_size <= m_capacity);
        if(m_size == m_capacity){
            if(m_capacity == 0){
                m_capacity = 16;
                m_data = (MR_Word*)MR_GC_malloc(16*sizeof(MR_Word));
            }
            else{
                if(m_capacity <= 4096 / sizeof(MR_Word))
                    m_capacity <<= 1;
                else
                    m_capacity += 4096 / sizeof(MR_Word);
                m_data = (MR_Word*)MR_GC_realloc(m_data, m_capacity * sizeof(MR_Word));
            }
        }
        m_data[m_size++] = word;
    }

    void emplace_back(MR_Word w){
        push_back(w);
    }
    
    void pop_back(){
        assert(m_size > 0);
        m_data[m_size--] = 0;
    }
};

static inline void set_undo_redo_menu_items(){
    if(CinEdit_IlibCanUndo())
        undo_menu_item->activate();
    else
        undo_menu_item->deactivate();
    if(CinEdit_IlibCanRedo())
        redo_menu_item->activate();
    else
        redo_menu_item->deactivate();
}

static bool s_item_browser_dirty = false;
static bool s_item_info_frame_dirty = false;
static std::string s_last_preview_image = "";
static Fl_RGB_Image *s_fl_image = NULL;
static struct AImg_Image s_preview_image = {NULL, 0, 0};

static unsigned load_preview_image(const char *image){
    if(s_last_preview_image == image)
        return 1;
    printf("Loading %s...\n", image);
    AImg_DestroyImage(&s_preview_image);
    s_preview_image.w = s_preview_image.h = 0;
    s_last_preview_image = image;
    if(!s_last_preview_image.empty()){
        if(AImg_LoadAuto(&s_preview_image, image) == AIMG_LOADPNG_SUCCESS){
            // Don't bother with deallocation, just do destructor + constructor.
            if(s_fl_image == NULL){
                s_fl_image = new Fl_RGB_Image((const uchar*)s_preview_image.pixels, s_preview_image.w, s_preview_image.h, 4, 0);
            }
            else{
                s_fl_image->~Fl_RGB_Image();
                new (s_fl_image) Fl_RGB_Image((const uchar*)s_preview_image.pixels, s_preview_image.w, s_preview_image.h, 4, 0);
            }
            item_icon_image_box->image(s_fl_image);
            return 1;
        }
        else
            return 0;
    }
    return 1;
}

static void do_dirty_all(){
    CinEdit_RebuildViews();
    // Dirty all.
    s_item_browser_dirty = true;
    s_item_info_frame_dirty = true;
}

static bool s_has_focus = true;
void CinEdit_IlibFocus(){
    s_has_focus = true;
    set_undo_redo_menu_items();
}

void CinEdit_IlibUnfocus(){
    s_has_focus = false;
}

#define DIRTY_CHECK(WHAT)\
do{\
    if(s_ ## WHAT ## _dirty) {\
        WHAT->redraw();\
        s_ ## WHAT ## _dirty = false;\
    }\
} while(false)

static MR_Word s_ilib = 0xDEADCAFE;
void CinEdit_SetIlib(MR_Word ilib){
    if(s_has_focus)
        set_undo_redo_menu_items();
    s_ilib = ilib;
}

MR_Word CinEdit_GetIlib(){
    if(s_has_focus)
        set_undo_redo_menu_items();
    
    DIRTY_CHECK(item_browser);
    DIRTY_CHECK(item_info_frame);
    return s_ilib;
}

#undef DIRTY_CHECK

static std::string s_path;
void CinEdit_SetItemLibraryPath(const char *path){
    assert(path != NULL);
    s_path = path;
}

const char *CinEdit_GetItemLibraryPath(){
    return s_path.c_str();
}

static std::stack<MR_Word, WordHolder> s_ilib_undo_stack,
    s_ilib_redo_stack;

void CinEdit_IlibPushUndo(){
    assert(s_ilib != 0xDEADCAFE);
    s_ilib_undo_stack.push(s_ilib);
    while(!s_ilib_redo_stack.empty())
        s_ilib_redo_stack.pop();
}

void CinEdit_IlibUndo(){
    if(s_ilib_undo_stack.empty())
        return;
    const bool do_activate = s_ilib_redo_stack.empty();
    s_ilib_redo_stack.push(s_ilib);
    s_ilib = s_ilib_undo_stack.top();
    s_ilib_undo_stack.pop();
    if(s_has_focus){
        if(do_activate)
            redo_menu_item->activate();
        if(s_ilib_undo_stack.empty())
            undo_menu_item->deactivate();
    }
    do_dirty_all();
}

void CinEdit_IlibRedo(){
    if(s_ilib_redo_stack.empty())
        return;
    const bool do_activate = s_ilib_undo_stack.empty();
    s_ilib_undo_stack.push(s_ilib);
    s_ilib = s_ilib_redo_stack.top();
    s_ilib_redo_stack.pop();
    if(s_has_focus){
        if(do_activate)
            undo_menu_item->activate();
        if(s_ilib_redo_stack.empty())
            redo_menu_item->deactivate();
    }
    do_dirty_all();
}

unsigned CinEdit_IlibCanUndo(){
    return !s_ilib_undo_stack.empty();
}

unsigned CinEdit_IlibCanRedo(){
    return !s_ilib_redo_stack.empty();
}

static void try_replace_push(unsigned i, MR_Word item){
    MR_Word new_ilib;
    
    item_browser->data(i+1, (void*)item);
    if(CinEdit_M_ReplaceItem(i, s_ilib, item, &new_ilib) == MR_YES){
        CinEdit_IlibPushUndo();
        s_ilib = new_ilib;
    }
    else
        assert(false);
}

unsigned CinEdit_GetNumItems(){
    unsigned i = 0;
    MR_Word list = s_ilib;
    while(!MR_list_is_empty(list)){
        i++;
        list = MR_list_tail(list);
    }
    return i;
}

EnumItemTypeType CinEdit_GetItemType(unsigned len){
    MR_Word item;
    if(CinEdit_M_GetItem(len, s_ilib, &item) != MR_YES){
        assert(false);
        return eArmor;
    }
    return (EnumItemTypeType)Ilib_GetItemType(item);
}

void CinEdit_SetItemType(const unsigned i, enum EnumItemTypeType type){
    MR_Word item;
    if(CinEdit_M_GetItem(i, s_ilib, &item) != MR_YES){
        assert(false);
        return;
    }
    MR_String name = NULL, model, icon;
    MR_Integer weight, durability, value; 
    MR_Word child;
    Ilib_GetItem(&child, &durability, &icon, &model, &name, &value, &weight, item);
    fputs("New Type ", stdout); puts(name);
    printf("Number %i\n", i);
    switch(type){
        case eArmor:
            CinEdit_SetItemTypeArmor();
            Ilib_CreateArmor(10, (MR_Word)eHelmet, &child);
            weapon_type_choice->value((int)eHelmet);
            armor_defense_input->value(10);
            Ilib_CreateItemArmor(&child, child);
            break;
        case eWeapon:
            CinEdit_SetItemTypeWeapon();
            Ilib_CreateWeapon((MR_Word)eSword, 500, 10, &child);
            weapon_type_choice->value((int)eSword);
            weapon_attack_power_input->value(10);
            weapon_attack_speed_input->value(500);
            Ilib_CreateItemWeapon(&child, child);
            break;
        case eConsumable:
            CinEdit_SetItemTypeConsumable();
            Ilib_CreateItemConsumable(&child);
            break;
        case eJunk:
            CinEdit_SetItemTypeJunk();
            Ilib_CreateBook(create_mr_string(""), &child);
            Ilib_CreateJunk(child, &child);
            Ilib_CreateItemJunk(&child, child);
            break;
    }

    item = 0;
    Ilib_CreateItem(child, durability, icon, model, name, value, weight, &item);
    try_replace_push(i, item);
}

static void CinEdit_SetItemString(unsigned i,
    const char **in_name,
    const char **in_model,
    const char **in_icon){
    MR_Word item;
    if(CinEdit_M_GetItem(i, s_ilib, &item) != MR_YES){
        assert(false);
        return;
    }
    MR_Word child;
    MR_String name, model, icon;
    MR_Integer weight, durability, value;
    Ilib_GetItem(&child, &durability, &icon, &model, &name, &value, &weight, item);
    if(in_name)
        name = create_mr_string(*in_name);
    if(in_model)
        model = create_mr_string(*in_model);
    if(in_icon)
        icon = create_mr_string(*in_icon);
    Ilib_CreateItem(child, durability, icon, model, name, value, weight, &item);
    try_replace_push(i, item);
}

void CinEdit_SetItemName(unsigned i, const char *name){
    CinEdit_SetItemString(i, &name, NULL, NULL);
    item_browser->text(i+1, name);
}

unsigned CinEdit_SetItemModel(unsigned i, const char *model){
    CinEdit_SetItemString(i, NULL, &model, NULL);
    return 1;
}

unsigned CinEdit_SetItemIcon(unsigned i, const char *icon){
    CinEdit_SetItemString(i, NULL, NULL, &icon);
    if(static_cast<int>(i + 1) == item_browser->value()){
        return load_preview_image(icon);
    }
    return 1;
}

static void CinEdit_SetItemData(unsigned i,
    unsigned *in_value,
    unsigned *in_durability,
    unsigned *in_weight){
    MR_Word item;
    if(CinEdit_M_GetItem(i, s_ilib, &item) != MR_YES){
        assert(false);
        return;
    }
    MR_Word child;
    MR_String name, model, icon;
    MR_Integer weight, durability, value;
    Ilib_GetItem(&child, &durability, &icon, &model, &name, &value, &weight, item);
    if(in_weight)
        weight = *in_weight;
    if(in_value)
        value = *in_value;
    if(in_durability)
        durability = *in_durability;
    Ilib_CreateItem(child, durability, icon, model, name, value, weight, &item);
    try_replace_push(i, item);
}

void CinEdit_SetItemValue(unsigned i, unsigned v){
    CinEdit_SetItemData(i, &v, NULL, NULL);
}

void CinEdit_SetItemDurability(unsigned i, unsigned d){
    CinEdit_SetItemData(i, NULL, &d, NULL);
}

void CinEdit_SetItemWeight(unsigned i, unsigned w){
    CinEdit_SetItemData(i, NULL, NULL, &w);
}

static void CinEdit_SetItemArmorData(unsigned i,
    unsigned *in_defense,
    enum EnumArmorTypeType *in_type){
    MR_Word item;
    if(CinEdit_M_GetItem(i, s_ilib, &item) != MR_YES){
        assert(false);
        return;
    }
    MR_Word child;
    MR_String name, model, icon;
    MR_Integer weight, durability, value;
    Ilib_GetItem(&child, &durability, &icon, &model, &name, &value, &weight, item);
    
    if(Ilib_GetItemArmor(child, &child) == MR_YES){
        MR_Integer defense;
        MR_Word type;
        Ilib_GetArmor(&type, &defense, child);
        if(in_type)
            type = *in_type;
        if(in_defense)
            defense = *in_defense;
        Ilib_CreateArmor(defense, (MR_Word)type, &child);
    }
    else{
        assert(false);
        return;
    }
    
    Ilib_CreateItem(child, durability, icon, model, name, value, weight, &item);
    try_replace_push(i, item);
}

void CinEdit_SetItemArmorType(unsigned i, enum EnumArmorTypeType type){
    CinEdit_SetItemArmorData(i, NULL, &type);
}

void CinEdit_SetItemArmorDefense(unsigned i, unsigned defense){
    CinEdit_SetItemArmorData(i, &defense, NULL);
}

void CinEdit_AddNewItemModel(const char *name){
    MR_String mr_name = create_mr_string(name);
    
    const MR_Word item = CinEdit_M_CreateItem(mr_name);
    
    CinEdit_IlibPushUndo();
    
    CinEdit_M_AddItem(item, s_ilib, &s_ilib);
    CinEdit_AppendItemView(name, item);
}

void CinEdit_RemoveItemModel(unsigned i){
    MR_Word new_ilib;
    if(CinEdit_M_RemoveItem(i, s_ilib, &new_ilib) == MR_YES){
        CinEdit_IlibPushUndo();
        s_ilib = new_ilib;
        CinEdit_RemoveItemView(i);
    }
    else
        assert(false);
}

const char *CinEdit_SaveItemLib(const char *path){
    if(path == NULL)
        path = s_path.c_str();

    MR_Word err;
    char *mutable_path = create_mr_string(path);
    CinEdit_M_SaveIlib(mutable_path, s_ilib, &err);
    
    MR_String error_string;
    if(CinEdit_M_GetSaveError(err, &error_string) == MR_NO)
        return NULL;
    assert(error_string != NULL);
    fprintf(stderr, "%p\n", (void*)error_string);
    fprintf(stderr, "%s\n", error_string);
    return error_string;
}

const char *CinEdit_LoadItemLib(const char *path){
    char *mutable_path = create_mr_string(path);
    MR_Word result, lib;
    CinEdit_M_LoadIlib(mutable_path, &result);
    mutable_path = NULL;
    
    if(CinEdit_M_GetLoadedIlib(result, &lib) == MR_NO){
        MR_String str;
        CinEdit_M_GetLoadError(result, &str);
        return str;
    }
    
    s_ilib = lib;
    
    while(!s_ilib_redo_stack.empty())
        s_ilib_redo_stack.pop();

    while(!s_ilib_undo_stack.empty())
        s_ilib_undo_stack.pop();
    
    do_dirty_all();
    
    s_path = path;
    return NULL;
}

void CinEdit_AppendItemView(const char *name, MR_Word data){
    assert(sizeof(MR_Word) == sizeof(void*));
    item_browser->add(name, (void*)data);
    
    s_item_browser_dirty = true;
    s_item_info_frame_dirty = true;

}

void CinEdit_ClearItemView(){
    item_browser->clear();
    
    s_item_browser_dirty = true;
    s_item_info_frame_dirty = true;
    
    CinEdit_SetItemsDoNotExistUI();
}

void CinEdit_RemoveItemView(unsigned i){
    const int n = i + 1;
    if(item_browser->value() == n)
        item_browser->value(i);
    item_browser->remove(n);
    item_browser->do_callback();
    s_item_browser_dirty = true;
    if(item_browser->size() == 0)
        CinEdit_SetItemsDoNotExistUI();
}

void CinEdit_RebuildViews(){
    int selected_item = item_browser->value();
    CinEdit_ClearItemView();
    MR_Word list = s_ilib;
    while(!MR_list_is_empty(list)){
        MR_Word item = MR_list_head(list);
        list = MR_list_tail(list);
        CinEdit_AppendItemView(CinEdit_M_ItemName(item), item);
    }

    if(selected_item > item_browser->size())
        selected_item = item_browser->size();
    
    item_browser->value(selected_item);

    if(selected_item > 0){
        MR_Word item;
        if(CinEdit_M_GetItem(selected_item - 1, s_ilib, &item) == MR_NO){
            assert(false && "Somehow we miscounted the number of items");
            CinEdit_SetItemsDoNotExistUI();
            return;
        }
        CinEdit_RebuildItemInfoFrame(item);
    }
    if(s_has_focus){
        if(item_browser->size() || !s_path.empty()){
            CinEdit_SetSaveActiveUI();
        }
        else{
            CinEdit_SetSaveInactiveUI();
        }
    }
}

void CinEdit_RebuildItemInfoFrame(MR_Word item){
    MR_Word child;
    
    {
        MR_String name, model, icon;
        MR_Integer weight, durability, value;
        Ilib_GetItem(&child, &durability, &icon, &model, &name, &value, &weight, item);
        CinEdit_SetItemAttributes(value, durability, weight, icon, model);
        item_name_input->value(name);
        item_name_input->redraw();
        load_preview_image(icon);
    }

    MR_Word unwrapped_child;
    if(Ilib_GetItemArmor(child, &unwrapped_child) == MR_YES){
        CinEdit_SetItemTypeArmor();
        puts("Armor");
    }
    else if(Ilib_GetItemWeapon(child, &unwrapped_child) == MR_YES){
        CinEdit_SetItemTypeWeapon();
        puts("Weapon");
        
    }
    else if(Ilib_GetItemConsumable(child/*, &unwrapped_child*/) == MR_YES){
        CinEdit_SetItemTypeConsumable();
        puts("Consumable");
        
    }
    else if(Ilib_GetItemJunk(child, &unwrapped_child) == MR_YES){
        CinEdit_SetItemTypeJunk();
        puts("Junk");
        
    }
    else{
        assert(false && "Invalid or unsupported item type");
    }
    s_item_info_frame_dirty = true;

    if(s_has_focus){
        if(item_browser->size() || !s_path.empty()){
            CinEdit_SetSaveActiveUI();
        }
        else{
            CinEdit_SetSaveInactiveUI();
        }
    }
}

void CinEdit_RebuildItemInfoFrame2(){
    const int i = item_browser->value();
    if(i <= 0){
        CinEdit_SetItemsDoNotExistUI();
    }
    else{
        CinEdit_SetItemsExistUI();
        printf("Redraw %i\n", i - 1);
        CinEdit_RebuildItemInfoFrame((MR_Word)item_browser->data(i));
    }
}
