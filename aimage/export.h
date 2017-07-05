/*
 *    Copyright (c) 2015-2016
 *        Martin McDonough (FlyingJester)
 *    All rights reserved.
 *
 *    This software is provided 'as-is', without any express or implied
 *    warranty. In no event will the authors be held liable for any damages
 *    arising from the use of this software.
 *
 *    Permission is granted to anyone to use this software for any purpose,
 *    including commercial applications, and to alter it and redistribute it
 *    freely, subject to the following restrictions:
 *
 *    1. Redistributions of source code must retain the above copyright
 *         notice, this list of conditions and the following disclaimer.
 *    2. Redistributions in binary form must reproduce the above copyright
 *         notice, this list of conditions and the following disclaimer in the
 *         documentation and/or other materials provided with the distribution.
 *    3. Neither the name of the Lightning Game Engine Group, the TurboSphere
 *         Organization, or AthenaTBS, nor the names of any contributors may be
 *         used to endorse or promote products derived from this software 
 *         without specific prior written permission.
 */

#ifndef AIMG_PLATFORM_API
#define AIMG_PLATFORM_API

#if ( defined _MSC_VER ) || ( defined __WATCOMC__ )
#ifdef _WIN64
#define AIMG_FASTCALL
#else
#define AIMG_FASTCALL __fastcall
#endif
#ifdef AIMG_EXPORTS
#define AIMG_API(X) __declspec(dllexport) X AIMG_FASTCALL
#else
#define AIMG_API(X) __declspec(dllimport) X AIMG_FASTCALL
#endif
#else
#ifdef __GNUC__
#define AIMG_FASTCALL __fastcall
#else
#define AIMG_FASTCALL
#endif
#define AIMG_API(X) X FASTCALL
#endif

#endif
