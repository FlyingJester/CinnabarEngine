#include "cinedit_fltk_glue.h"
#include "editor_ui.hpp"

void *CinEdit_CreateEditorWindow(){
    Fl_Window *const window = make_editor_window();
    Fl::scheme("GTK+");
    window->show();
    return window;
}

void CinEdit_DestroyEditorWindow(void *that){
    delete static_cast<Fl_Double_Window *>(that);
}

extern "C"
unsigned CinEdit_FlWait(){
    return Fl::wait();
}
