#pragma once

namespace CinEdit {

class ilib;

enum EnumSystem { eCellSystem, eItemSystem, eNUM_SYSTEMS };
void SetUnsavedChanges(bool, EnumSystem);
bool GetUnsavedChanges(EnumSystem);
bool GetUnsavedChanges(void);

enum EnumCellType { eInterior, eExterior };
void SetCellType(EnumCellType);
EnumCellType GetCellType(void);

ilib &GetIlib();

} // namespace CinEdit
