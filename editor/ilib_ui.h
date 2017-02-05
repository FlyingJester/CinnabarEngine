#pragma once

// UI Interface for Item Library (ilib) operations
#include "ilib.mh"

#ifdef __cplusplus
extern "C" {
#endif

struct ItemAdapter {
    void *item;
};

/*
 * Most operations on the model-facing or view-facing adapters have an
 * equivalent on the other adapter. In general, the responsibility to call
 * the next operation is:
 *
 *   FLTK-based Views OR
 *     UI Callbacks
 *          ||
 *         call
 *          ||
 *          \/
 *    View-Facing Adpt. =======\
 *          ||                 \|
 *         calls               ||
 *          ||                calls
 *          \/                 ||
 *  Mercury-based Model <======+|
 *          ||                 ||
 *         calls               ||
 *          ||                 ||
 *          \/                 /|
 *   Model-Facing Adpt. <======/
 *          ||
 *         calls
 *          ||
 *          \/
 * FLTK-based View functions
 *
 * For example, when adding an item via a button, the button's callback will
 * call the view-facing adapter function, which will call the Mercury-based
 * model code, which will call a model-facing adapter function, which will
 * call a C++ function defined in the .fl file.
 * In some cases, where a larger Mercury API is supplied, the view-facing
 * adapter will call a model facing adapter directly. Examples of this include
 * cases where an allocator is exposed by Mercury for some manipulatable data,
 * and a menu entry should be added for the new data.
 * The view callback should NOT also try to update any view itself. Any case
 * where the view does not update properly is likely a bug in the adapter
 * code.
 */

/* Called during before the call to Fl::wait. All inner wrappers will
 * update this, and then before the return from the Mercury wrapper to
 * Fl::wait, we will reload using CinEdit_GetIlib. */
void CinEdit_SetIlib(MR_Word);
MR_Word CinEdit_GetIlib();

/* Called by the UI to remember what the loaded path is. */
void CinEdit_SetItemLibraryPath(const char *);
const char *CinEdit_GetItemLibraryPath();

/* Undo/Redo ops. Push will automatically be called for any wrappers, so it
 * should not need to be called externally. */
void CinEdit_IlibUndo();
void CinEdit_IlibRedo();
void CinEdit_IlibPushUndo();
unsigned CinEdit_IlibCanUndo();
unsigned CinEdit_IlibCanRedo();

/* View-facing adapter.  */
void CinEdit_IlibFocus();
/* Unfocus may be called more than once between each call to Focus. */
void CinEdit_IlibUnfocus();

unsigned CinEdit_GetNumItems();
enum EnumItemTypeType CinEdit_GetItemType(unsigned i);

void CinEdit_SetItemType(unsigned i, enum EnumItemTypeType type);
void CinEdit_SetItemName(unsigned i, const char *name);
unsigned CinEdit_SetItemModel(unsigned i, const char *model);
unsigned CinEdit_SetItemIcon(unsigned i, const char *icon);
void CinEdit_SetItemValue(unsigned i, unsigned v);
void CinEdit_SetItemDurability(unsigned i, unsigned d);
void CinEdit_SetItemWeight(unsigned i, unsigned w);
void CinEdit_SetItemArmorType(unsigned i, enum EnumArmorTypeType type);
void CinEdit_SetItemArmorDefense(unsigned i, unsigned defense);

/* Adds a new item to the lib model. */
void CinEdit_AddNewItemModel(const char *);
void CinEdit_RemoveItemModel(unsigned i);

/* Replaces the existing item lib model */
void CinEdit_NewItemLibModel();

/* Saves the current lib to the specified path. Returns NULL on success, or
 * an error message describing the issue. */
const char *CinEdit_SaveItemLib(const char *);
/* Loads the current lib from the specified path. Returns NULL on success, or
 * an error message describing the issue. */
const char *CinEdit_LoadItemLib(const char *);

/* Model-facing adapter (implemented in C++) */

void CinEdit_AppendItemView(const char *name, MR_Word data);
void CinEdit_ClearItemView();
void CinEdit_RemoveItemView(unsigned i);

void CinEdit_RebuildViews();
void CinEdit_RebuildItemInfoFrame(MR_Word item);
void CinEdit_RebuildItemInfoFrame2();

#ifdef __cplusplus
}
#endif
