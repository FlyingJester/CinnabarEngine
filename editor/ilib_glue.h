#pragma once

#define CHOICE_TO_ENUM(CHOICE, DEST, ENUM)\
do{\
    const int n = CHOICE->value();\
    if(n < static_cast<int>(NUM_ ## ENUM ## Type)) {\
        DEST = static_cast<EnumBottle ## ENUM ## Type>(n);\
    }\
    else{\
        DEST = static_cast<EnumBottle ## ENUM ## Type>(0);\
        fprintf(stderr, "Invalid " #ENUM " type %i\n", n);\
    }\
}while(0)

#define COPY_OUT_BOTTLE_STRING(ALLOCATOR, STR, FUNC)\
do{ \
    const unsigned L_ = STR.len;\
    char *const N_ = (char*)ALLOCATOR(L_ + 1);\
    memcpy(N_, STR.str, L_);\
    N_[L_] = 0;\
    FUNC(N_);\
}while(0)

#define COPY_IN_BOTTLE_STRING(STR, FROM)\
do{\
    const char *const S_ = FROM;\
    const unsigned L_ = strlen(S_);\
    if(L_ > STR.len)\
        STR.str = (char*)realloc(STR.str, L_);\
    STR.len = L_;\
    memcpy(STR.str, S_, L_);\
}while(0)
