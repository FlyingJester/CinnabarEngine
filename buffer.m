:- module buffer.
%==============================================================================%
:- interface.
%==============================================================================%

:- import_module list.
:- use_module io.

%------------------------------------------------------------------------------%

:- type buffer.
:- func init(int) = (buffer).
:- func length(buffer) = (int).

% Just used for clarity.
:- type index == int.
:- type byte_index == int.

%------------------------------------------------------------------------------%

% Reads using from the indexed element based on element size, not byte number.
:- pred get_8(buffer::in, index::in, int::uo) is semidet.
:- pred get_16(buffer::in, index::in, int::uo) is semidet.
:- pred get_32(buffer::in, index::in, int::uo) is semidet.
:- pred get_float(buffer::in, index::in, float::uo) is semidet.
:- pred get_double(buffer::in, index::in, float::uo) is semidet.

% Same as the other getters, but uses a byte index to start with.
:- pred get_byte_8(buffer::in, byte_index::in, int::uo) is semidet.
:- pred get_byte_16(buffer::in, byte_index::in, int::uo) is semidet.
:- pred get_byte_32(buffer::in, byte_index::in, int::uo) is semidet.
:- pred get_byte_float(buffer::in, byte_index::in, float::uo) is semidet.
:- pred get_byte_double(buffer::in, byte_index::in, float::uo) is semidet.

%------------------------------------------------------------------------------%

:- func to_list_8(buffer) = list.list(int).
:- func to_list_16(buffer) = list.list(int).
:- func to_list_32(buffer) = list.list(int).
:- func to_list_float(buffer) = list.list(float).
:- func to_list_double(buffer) = list.list(float).

:- pred to_list_8(buffer::in, list.list(int)::uo) is det.
:- pred to_list_16(buffer::in, list.list(int)::uo) is det.
:- pred to_list_32(buffer::in, list.list(int)::uo) is det.
:- pred to_list_float(buffer::in, list.list(float)::uo) is det.
:- pred to_list_double(buffer::in, list.list(float)::uo) is det.

:- func to_list_8_reverse(buffer) = list.list(int).
:- func to_list_16_reverse(buffer) = list.list(int).
:- func to_list_32_reverse(buffer) = list.list(int).
:- func to_list_float_reverse(buffer) = list.list(float).
:- func to_list_double_reverse(buffer) = list.list(float).

:- pred to_list_8_reverse(buffer::in, list.list(int)::uo) is det.
:- pred to_list_16_reverse(buffer::in, list.list(int)::uo) is det.
:- pred to_list_32_reverse(buffer::in, list.list(int)::uo) is det.
:- pred to_list_float_reverse(buffer::in, list.list(float)::uo) is det.
:- pred to_list_double_reverse(buffer::in, list.list(float)::uo) is det.

%------------------------------------------------------------------------------%

:- func from_list_8(list.list(int)) = buffer.
:- func from_list_16(list.list(int)) = buffer.
:- func from_list_32(list.list(int)) = buffer.
:- func from_list_float(list.list(float)) = buffer.
:- func from_list_double(list.list(float)) = buffer.

:- pred from_list_8(list.list(int)::in, buffer::uo) is det.
:- pred from_list_16(list.list(int)::in, buffer::uo) is det.
:- pred from_list_32(list.list(int)::in, buffer::uo) is det.
:- pred from_list_float(list.list(float)::in, buffer::uo) is det.
:- pred from_list_double(list.list(float)::in, buffer::uo) is det.

%------------------------------------------------------------------------------%

% Succeeds if the buffer is as long or longer than the string, and matches for
% the length of the string matches bytewise.
% Fails if buffer is shorter than string.
:- pred matches(buffer::in, string::in) is semidet.

% Creates a string from Length bytes of Buffer. Fails if Length is greater
% than the length of Buffer, or if any invalid codepoints are encountered.
% get_string(Buffer, Length, String)
% :- pred get_string(buffer::in, int::in, string::uo) is semidet.

% Same as get_string, but only accepts ascii characters. Slightly faster.
:- pred get_ascii_string(buffer::in, int::in, string::uo) is semidet.

%------------------------------------------------------------------------------%

:- pred read(io.binary_input_stream, int, io.maybe_partial_res(buffer), io.io, io.io).
:- mode read(in, in, out, di, uo) is det.

% Reads from the current binary input stream.
:- pred read(int, buffer, io.io, io.io).
:- mode read(in, uo, di, uo) is det.

%------------------------------------------------------------------------------%

:- pred append(buffer::in, buffer::in, buffer::uo) is det.
:- func append(buffer, buffer) = (buffer).

:- pred concatenate(list(buffer)::in, buffer::out) is det.
:- func concatenate(list(buffer)) = buffer.

%------------------------------------------------------------------------------%

% Used to implement all other getters. These should be the only native getters.
% These do NOT do any bounds checking, the callers MUST bounds check. Otherwise you
% WILL CRASH. I guarantee it.
:- pred get_native_8(buffer::in, byte_index::in, int::uo) is det.
:- pred get_native_16(buffer::in, byte_index::in, int::uo) is det.
:- pred get_native_32(buffer::in, byte_index::in, int::uo) is det.
:- pred get_native_float(buffer::in, byte_index::in, float::uo) is det.
:- pred get_native_double(buffer::in, byte_index::in, float::uo) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module int.

%------------------------------------------------------------------------------%

:- pragma foreign_import_module("C", io).

%------------------------------------------------------------------------------%
% Houskeeping for C to help working with the GC

:- pragma foreign_decl("C", "struct M_Buffer { unsigned long size; void *data; };").
:- pragma foreign_decl("C", "struct M_Buffer *M_Buffer_Allocate(unsigned long len);").
:- pragma foreign_code("C",
    "
        struct M_Buffer *M_Buffer_Allocate(unsigned long len){
            struct M_Buffer *const buf = MR_GC_NEW(struct M_Buffer);
            buf->data = MR_GC_malloc_atomic((buf->size = len));
            return buf;
        }
    ").

%------------------------------------------------------------------------------%

:- pragma foreign_type("C", buffer, "const struct M_Buffer*").
:- pragma foreign_type("Java", buffer, "byte[]").

:- pragma foreign_export("C", get_native_8(in, in, uo), "M_Buffer_GetNative8").
:- pragma foreign_export("C", get_native_16(in, in, uo), "M_Buffer_GetNative16").
:- pragma foreign_export("C", get_native_32(in, in, uo), "M_Buffer_GetNative32").
:- pragma foreign_export("C",
    get_native_float(in, in, uo), "M_Buffer_GetNativeFloat").
:- pragma foreign_export("C",
    get_native_double(in, in, uo), "M_Buffer_GetNativeDouble").

:- pragma foreign_export("C", to_list_8(in) = (out), "M_Buffer_ToList8").
:- pragma foreign_export("C", to_list_16(in) = (out), "M_Buffer_ToList16").
:- pragma foreign_export("C", to_list_32(in) = (out), "M_Buffer_ToList32").
:- pragma foreign_export("C", to_list_float(in) = (out), "M_Buffer_ToListFloat").
:- pragma foreign_export("C", to_list_double(in) = (out), "M_Buffer_ToListDouble").

:- pragma foreign_export("C", from_list_8(in) = (out), "M_Buffer_FromList8").
:- pragma foreign_export("C", from_list_16(in) = (out), "M_Buffer_FromList16").
:- pragma foreign_export("C", from_list_32(in) = (out), "M_Buffer_FromList32").
:- pragma foreign_export("C",
    from_list_float(in) = (out), "M_Buffer_FromListFloat").
:- pragma foreign_export("C",
    from_list_double(in) = (out), "M_Buffer_FromListDouble").

:- pragma foreign_proc("C", init(Size::in) = (Buffer::out),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        struct M_Buffer *const buf = MR_GC_NEW(struct M_Buffer);
        buf->size = Size;
        buf->data = MR_GC_malloc_atomic(Size);
        Buffer = buf;
    ").

:- pragma foreign_proc("Java", init(Size::in) = (Buffer::out),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        Buffer = new byte[Size];
    ").

:- pragma foreign_proc("C", length(Buffer::in) = (Size::out),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
    does_not_affect_liveness], " Size = Buffer->size; ").

to_list_8(In) = Out  :- to_list_8(In, Out).
to_list_16(In) = Out :- to_list_16(In, Out).
to_list_32(In) = Out :- to_list_16(In, Out).
to_list_float(In) = Out  :- to_list_float(In, Out).
to_list_double(In) = Out :- to_list_double(In, Out).

to_list_8_reverse(In) = Out  :- to_list_8_reverse(In, Out).
to_list_16_reverse(In) = Out :- to_list_16_reverse(In, Out).
to_list_32_reverse(In) = Out :- to_list_16_reverse(In, Out).
to_list_float_reverse(In) = Out  :- to_list_float_reverse(In, Out).
to_list_double_reverse(In) = Out :- to_list_double_reverse(In, Out).

from_list_8(In) = Out  :- from_list_8(In, Out).
from_list_16(In) = Out :- from_list_16(In, Out).
from_list_32(In) = Out :- from_list_32(In, Out).
from_list_float(In) = Out  :- from_list_float(In, Out).
from_list_double(In) = Out :- from_list_double(In, Out).

:- func size8 = int.
size8 = 1.

:- func size16 = int.
size16 = 2.

:- func size32 = int.
size32 = 4.

:- func sizefloat = int.
sizefloat = 4.

:- func sizedouble = int.
sizedouble = 8.

:- func append_float_to_list(float, list.list(float)) = list.list(float).
append_float_to_list(F, L) = list.append(L, [F|[]]).
:- pragma foreign_export("C", append_float_to_list(in, in) = (out),
    "M_Buffer_AppendFloatToList").

:- func append_int_to_list(int, list.list(int)) = list.list(int).
append_int_to_list(F, L) = list.append(L, [F|[]]).
:- pragma foreign_export("C", append_int_to_list(in, in) = (out),
    "M_Buffer_AppendIntToList").

get_8(B, I, O)      :- get_byte_8(B, I, O).
get_16(B, I, O)     :- get_byte_16(B, I*size16, O).
get_32(B, I, O)     :- get_byte_32(B, I*size32, O).
get_float(B, I, O)  :- get_byte_float(B, I*sizefloat, O).
get_double(B, I, O) :- get_byte_double(B, I*sizedouble, O).

get_byte_8(Buf, I, O) :- I + size8 =< length(Buf), get_native_8(Buf, I, O).

get_byte_16(Buf, I, O) :- I + size16 =< length(Buf), get_native_16(Buf, I, O).

get_byte_32(Buf, I, O) :- I + size32 =< length(Buf), get_native_32(Buf, I, O).

get_byte_float(Buf, I, O) :-
    I + sizefloat =< length(Buf), get_native_float(Buf, I, O).

get_byte_double(Buf, I, O) :-
    I + sizedouble =< length(Buf), get_native_double(Buf, I, O).

:- pragma foreign_proc("C", matches(Buf::in, Str::in),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
     does_not_affect_liveness],
    "
        const unsigned len = strnlen(Str, Buf->size + 1);
        SUCCESS_INDICATOR = (len <= Buf->size && memcmp(Buf->data, Str, len) == 0);
    ").

:- pragma foreign_proc("C", get_ascii_string(Buf::in, Len::in, Out::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        if((SUCCESS_INDICATOR = Buf->size >= Len)){
            unsigned i;
            for(i = 0; i < Len; i++){
                const char c = ((char*)Buf->data)[i];
                if(!((c >= ' ' || c == '\\n' || c == '\\r' ||
                    c == '\\t') && !(c & 0x80))){
                    SUCCESS_INDICATOR = 0;
                    goto m_buffer_failure_not_ascii;
                }
            }
            Out = MR_GC_malloc_atomic(Len+1);
            memcpy(Out, Buf->data, Len);
            Out[Len] = '\\0';
        }
        m_buffer_failure_not_ascii: 
    ").

:- pragma foreign_proc("C", get_native_8(Buf::in, I::in, O::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
     does_not_affect_liveness],
    " O = ((unsigned char*)Buf->data)[I]; ").

:- pragma foreign_proc("C", get_native_16(Buf::in, I::in, O::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
     does_not_affect_liveness],
    " O = *((unsigned short*)(((char*)Buf->data) + I)); ").

:- pragma foreign_proc("C", get_native_32(Buf::in, I::in, O::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
     does_not_affect_liveness],
    " O = *((unsigned int*)(((char*)Buf->data) + I)); ").

:- pragma foreign_proc("C", get_native_float(Buf::in, I::in, O::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
     does_not_affect_liveness],
    " O = MR_float_to_word(*((float*)(((char*)Buf->data) + I))); ").

:- pragma foreign_proc("C", get_native_double(Buf::in, I::in, O::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
     does_not_affect_liveness],
    " O = MR_float_to_word(*((double*)(((char*)Buf->data) + I))); ").

:- pragma foreign_proc("C",
    to_list_8(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        for(i = 0; i < Buf->size; i++){
            const unsigned char b = ((unsigned char*)Buf->data)[i];
            List = M_Buffer_AppendIntToList(b, List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_16(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        const unsigned short *const array = (unsigned short*)((char*)Buf->data);
        for(i = 0; i < Buf->size >> 1; i++){
            List = M_Buffer_AppendIntToList(array[i], List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_32(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        const unsigned int *const array = (unsigned int*)((char*)Buf->data);
        for(i = 0; i < Buf->size >> 2; i++){
            List = M_Buffer_AppendIntToList(array[i], List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_float(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        const float *const array = (float*)((char*)Buf->data);
        for(i = 0; i < Buf->size >> 2; i++){
            List = M_Buffer_AppendFloatToList(array[i], List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_double(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        const double *const array = (double*)((char*)Buf->data);
        for(i = 0; i < Buf->size >> 3; i++){
            List = M_Buffer_AppendFloatToList(array[i], List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_8_reverse(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        for(i = 0; i < Buf->size; i++){
            const unsigned char b = ((unsigned char*)Buf->data)[i];
            List = MR_list_cons(b, List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_16_reverse(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        const unsigned short *const array = (unsigned short*)((char*)Buf->data);
        for(i = 0; i < Buf->size >> 1; i++){
            List = MR_list_cons(array[i], List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_32_reverse(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        const unsigned int *const array = (unsigned int*)((char*)Buf->data);
        for(i = 0; i < Buf->size >> 2; i++){
            List = MR_list_cons(array[i], List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_float_reverse(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        const float *const array = (float*)((char*)Buf->data);
        for(i = 0; i < Buf->size >> 2; i++){
            List = MR_list_cons(MR_float_to_word(array[i]), List);
        }
    ").

:- pragma foreign_proc("C",
    to_list_double_reverse(Buf::in, List::uo),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        unsigned i;
        List = MR_list_empty();
        const double *const array = (double*)((char*)Buf->data);
        for(i = 0; i < Buf->size >> 3; i++){
            List = MR_list_cons(MR_float_to_word(array[i]), List);
        }
    ").

:- pragma foreign_proc("C", from_list_8(List::in, Buffer::uo),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        MR_Word list = List;
        unsigned len = 0;
        while(!MR_list_is_empty(list)){
            len++;
            list = MR_list_tail(list);
        }
        struct M_Buffer *const buf = MR_GC_NEW(struct M_Buffer);
        buf->data = MR_GC_malloc_atomic(len);
        buf->size = len;
        list = List; len = 0;
        while(!MR_list_is_empty(list)){
            ((unsigned char*)buf->data)[len++] = MR_list_head(list);
            list = MR_list_tail(list);
        }
        Buffer = buf;
    ").

:- pragma foreign_proc("C", from_list_16(List::in, Buffer::uo),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        MR_Word list = List;
        unsigned len = 0;
        while(!MR_list_is_empty(list)){
            len++;
            list = MR_list_tail(list);
        }
        struct M_Buffer *const buf = MR_GC_NEW(struct M_Buffer);
        buf->data = MR_GC_malloc_atomic(len << 1);
        buf->size = len << 1;
        list = List; len = 0;
        while(!MR_list_is_empty(list)){
            ((unsigned short*)buf->data)[len++] = MR_list_head(list);
            list = MR_list_tail(list);
        }
        Buffer = buf;
    ").

:- pragma foreign_proc("C", from_list_32(List::in, Buffer::uo),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        MR_Word list = List;
        unsigned len = 0;
        while(!MR_list_is_empty(list)){
            len++;
            list = MR_list_tail(list);
        }
        struct M_Buffer *const buf = MR_GC_NEW(struct M_Buffer);
        buf->data = MR_GC_malloc_atomic(len << 2);
        buf->size = len << 2;
        list = List; len = 0;
        while(!MR_list_is_empty(list)){
            ((unsigned int*)buf->data)[len++] = MR_list_head(list);
            list = MR_list_tail(list);
        }
        Buffer = buf;
    ").

:- pragma foreign_proc("C", from_list_float(List::in, Buffer::uo),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        MR_Word list = List;
        unsigned len = 0;
        while(!MR_list_is_empty(list)){
            len++;
            list = MR_list_tail(list);
        }
        struct M_Buffer *const buf = MR_GC_NEW(struct M_Buffer);
        buf->data = MR_GC_malloc_atomic(len << 2);
        buf->size = len << 2;
        list = List; len = 0;
        while(!MR_list_is_empty(list)){
            ((float*)buf->data)[len++] = MR_word_to_float(MR_list_head(list));
            list = MR_list_tail(list);
        }
        Buffer = buf;
    ").

:- pragma foreign_proc("C", from_list_double(List::in, Buffer::uo),
    [will_not_throw_exception, promise_pure, thread_safe, tabled_for_io],
    "
        MR_Word list = List;
        unsigned len = 0;
        while(!MR_list_is_empty(list)){
            len++;
            list = MR_list_tail(list);
        }
        struct M_Buffer *const buf = MR_GC_NEW(struct M_Buffer);
        buf->data = MR_GC_malloc_atomic(len << 3);
        buf->size = len << 3;
        list = List; len = 0;
        while(!MR_list_is_empty(list)){
            ((double*)buf->data)[len++] = MR_word_to_float(MR_list_head(list));
            list = MR_list_tail(list);
        }
        Buffer = buf;
    ").

read(In, Len, io.ok(Out), !IO) :-
    io.set_binary_input_stream(In, OldStream, !IO),
    buffer.read(Len, Out, !IO),
    io.set_binary_input_stream(OldStream, _, !IO).

:- pragma foreign_proc("C", read(Len::in, Buffer::uo, IO0::di, IO1::uo),
    [promise_pure, thread_safe, tabled_for_io],
    "
        MercuryFile *const stream = mercury_current_binary_input();

        if(stream != NULL){
            struct M_Buffer *const buffer = M_Buffer_Allocate(Len);
            buffer->size = MR_READ(*stream, buffer->data, Len);
            Buffer = buffer;
        }
        else{
            struct M_Buffer *const buffer = MR_GC_malloc_atomic(sizeof(struct M_Buffer));
            buffer->size = 0;
            fputs(""[Buffer] Invalid binary input stream.\\n"", stderr);
            Buffer = buffer;
        }
        IO1 = IO0;
    ").

:- pragma foreign_proc("C", append(A::in, B::in, Out::uo),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
    tabled_for_io],
    "
        struct M_Buffer *const buffer = M_Buffer_Allocate(A->size + B->size);
        memcpy(buffer->data, A->data, A->size);
        memcpy(((char*)buffer->data) + A->size, B->data, B->size);
        Out = buffer;
    ").

% We can be a little more sneaky about not doing extra allocations here, since we
% never promised the output was unique.
append(A, B) = Out :-
    ( length(A) = 0 ->
        Out = B
    ; length(B) = 0 ->
        Out = A
    ;
        append(A, B, Out)
    ).

concatenate(List) = Out :-
    concatenate(List, Out).

:- pragma foreign_proc("C", concatenate(In::in, Out::out),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        /* There are optimizations for lists of sizes 0 or 1, and lists with
         * only one buffer of a size other than zero. */
        
        MR_Word list = In;
        unsigned n = 0, size = 0;
        /* -2 is unset, -1 is multiple found. Used to determine if there is
         * only one non-empty buffer */
        int only_found = -2;
        const struct M_Buffer *found = NULL;
        
        while(!MR_list_is_empty(list)){
            const struct M_Buffer *const buf =
                (struct M_Buffer*)MR_list_head(list);
            assert(buf != NULL);
            list = MR_list_tail(list);
            if(size == 0 && buf->size > 0 && only_found == -2){
                only_found = n;
                found = buf;
            }
            else if(size != 0 && buf->size > 0){
                found = NULL;
                only_found = -1;
            }
            n++;
            size+=buf->size;
        }
        
        if(only_found >= 0){
            assert(found != NULL);
            Out = found;
        }
        if(size == 0 || n == 0){
            struct M_Buffer *const buffer =
                MR_GC_malloc_atomic(sizeof(struct M_Buffer));
            buffer->size = 0;
            Out = buffer;
        }
        else if(n == 1){
            Out = (struct M_Buffer*)MR_list_head(list);
        }
        else{
            unsigned at = 0;
            struct M_Buffer *const output = M_Buffer_Allocate(size);
            list = In;
            do{
                const struct M_Buffer *const buf = (void*)MR_list_head(list);
                list = MR_list_tail(list);
                if(buf->size == 0)
                    continue;
                memcpy(((char*)output->data) + at, buf->data, buf->size);
                at += buf->size;
            }while(!MR_list_is_empty(list));
            Out = output;
        }
    ").
