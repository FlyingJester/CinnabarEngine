#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#ifdef MR_HIGHLEVEL_CODE
#include "mercury.h"
#else
  #ifndef MERCURY_HDR_EXCLUDE_IMP_H
  #include "mercury_imp.h"
  #endif
#endif
#ifdef MR_DEEP_PROFILING
#include "mercury_deep_profiling.h"
#endif

#ifdef __cplusplus
}
#endif
