:- module buffer.
%==============================================================================%
:- interface.
%==============================================================================%

:- import_module list.
:- use_module io.

:- type buffer.
:- func init(int) = (buffer).
:- func length(buffer) = (int).

% Just used for clarity.
:- type index == int.
:- type byte_index == int.

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

% Used to implement all other getters. These should be the only native getters.
% These do NOT do any bounds checking, the callers MUST bounds check. Otherwise you
% WILL CRASH. I guarantee it.
:- pred get_native_8(buffer::in, byte_index::in, int::uo) is det.
:- pred get_native_16(buffer::in, byte_index::in, int::uo) is det.
:- pred get_native_32(buffer::in, byte_index::in, int::uo) is det.
:- pred get_native_float(buffer::in, byte_index::in, float::uo) is det.
:- pred get_native_double(buffer::in, byte_index::in, float::uo) is det.

:- pred read(io.binary_input_stream, int, io.maybe_partial_res(buffer), io.io, io.io).
:- mode read(in, in, out, di, uo) is det.

:- pred append(buffer::in, buffer::in, buffer::uo) is det.
:- func append(buffer, buffer) = (buffer).

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module int.

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

:- pragma foreign_type("C", buffer, "const struct M_Buffer*").

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

:- pragma foreign_proc("C", length(Buffer::in) = (Size::out),
    [will_not_call_mercury, will_not_throw_exception, promise_pure, thread_safe,
    does_not_affect_liveness],
    "
        Size = Buffer->size;
    ").

to_list_8(In) = Out  :- to_list_8(In, Out).
to_list_16(In) = Out :- to_list_16(In, Out).
to_list_32(In) = Out :- to_list_16(In, Out).
to_list_float(In) = Out  :- to_list_float(In, Out).
to_list_double(In) = Out :- to_list_double(In, Out).

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
            List = MR_list_cons(((unsigned char*)Buf->data)[i], List);
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
            List = MR_list_cons(array[i], List);
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
            List = MR_list_cons(array[i], List);
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
            List = MR_list_cons(MR_float_to_word(array[i]), List);
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

:- pred read(io.binary_input_stream,
    int, list.list(int), io.maybe_partial_res(buffer), io.io, io.io).
:- mode read(in,
    in, in, out, di, uo) is det.

% Passes the list through reversed. Slightly faster.
read(In, Len, Out, !IO) :- read(In, Len, [], Out, !IO).
read(In, Len, InList, Result, !IO) :-
    from_list_8(list.reverse(InList), Buffer),
    ( Len =< 0 ->
        Result = io.ok(Buffer)
    ;
        io.read_byte(In, ByteResult, !IO),
        (
            ByteResult = io.eof,
            Result = io.error(Buffer, io.make_io_error("EOF"))
        ;
            ByteResult = io.error(Err),
            Result = io.error(Buffer, Err)
        ;
            ByteResult = io.ok(Byte),
            read(In, Len-1, [Byte|InList], Result, !IO)
        )
    ).

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
