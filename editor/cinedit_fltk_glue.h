#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Returns an Fl_Window. */
void *CinEdit_CreateEditorWindow();

void CinEdit_DestroyEditorWindow(void *);

unsigned CinEdit_FlWait();

#ifdef __cplusplus
}
#endif
