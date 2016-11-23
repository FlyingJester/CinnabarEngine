#pragma once

/*    Bufferfile is a part of AthenaTBS.
*
*    Copyright (c) 2015-2016
*        Martin McDonough (FlyingJester)
*
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice, this
*   list of conditions and the following disclaimer.
*
* - Redistributions in binary form must reproduce the above copyright notice,
*   this list of conditions and the following disclaimer in the documentation
*   and/or other materials provided with the distribution.
*
* - Neither the name Athena or AthenaTBS, nor the names of its
*   contributors may be used to endorse or promote products derived from
*   this software without specific prior written permission.
*
* - The origin of this software must not be misrepresented; you must not
*   claim that you wrote the original software. If you use this software
*   in a product, an acknowledgment in the product documentation would be
*   appreciated but is not required.
*
* - Altered source versions must be plainly marked as such, and must not be
*   misrepresented as being the original software.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
* CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "bufferfile.h"

#include <Windows.h>

void *BufferFile(const char *path, int *size) {
	HANDLE file = CreateFile(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	const int l_size = size[0] = GetFileSize(file, NULL);

	HANDLE mmiofile = CreateFileMapping(file, NULL, PAGE_READONLY, 0, 0, NULL);
	void *const output = MapViewOfFile(mmiofile, FILE_MAP_READ, 0, 0, l_size);

	CloseHandle(file);
	CloseHandle(mmiofile);

	return output;
}

void FreeBufferFile(void *in, int size) {
	if (size) {}
	UnmapViewOfFile(in);
}
