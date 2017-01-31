#include "editor.hpp"
#include "editor_ui.hpp"
#include "editor_ilib.hpp"
#include "editor_cell.hpp"

#include <cassert>

//----------------------------------------------------------------------------//

namespace CinEdit {

//----------------------------------------------------------------------------//
// Unsaved Changes Variable

static bool unsaved_changes[eNUM_SYSTEMS];
void SetUnsavedChanges(bool ch, EnumSystem sys){
    assert(sys < eNUM_SYSTEMS);
    if(sys < eNUM_SYSTEMS)
        unsaved_changes[sys] = ch;
}

bool GetUnsavedChanges(){
    for(unsigned i = 0; i < (unsigned)eNUM_SYSTEMS; i++){
        if(unsaved_changes[i])
            return true;
    }

    return false;
}

bool GetUnsavedChanges(EnumSystem sys){
    assert(sys < eNUM_SYSTEMS);
    if(sys < eNUM_SYSTEMS)
        return unsaved_changes[sys];
    else
        return false;
}

//----------------------------------------------------------------------------//
// Cell Type Variable

static EnumCellType cell_type = eExterior;
void SetCellType(EnumCellType ct){
    cell_type = ct;
    SetCellTypeUI(ct == eExterior);
}

EnumCellType GetCellType(){
    return cell_type;
}

//----------------------------------------------------------------------------//
// ilib

static ilib edit_ilib;
ilib &GetIlib(){
    return edit_ilib;
}

} // namespace CinEdit

//----------------------------------------------------------------------------//

int main(int argc, char **argv){
    for(unsigned i = 0; i < (unsigned)CinEdit::eNUM_SYSTEMS; i++){
        CinEdit::unsaved_changes[i] = false;
    }
    
//----------------------------------------------------------------------------//
// Create an editor Window, then Create a glow window and initialize a Cinnabar
// scene for the glow window.
    
    
    Fl_Double_Window *const editor_window = make_editor_window();
    
    editor_window->show();
    
    return Fl::run();
}
