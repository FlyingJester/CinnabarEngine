:- module matrix.
%==============================================================================%
:- interface.
%==============================================================================%

:- use_module vector.

%------------------------------------------------------------------------------%
:- type matrix ---> matrix(
    a::float, b::float, c::float, d::float,
    e::float, f::float, g::float, h::float,
    i::float, j::float, k::float, l::float,
    m::float, n::float, o::float, p::float).

:- func identity = (matrix).
:- func translation(vector.vector3) = (matrix).
:- func scaling(vector.vector3) = (matrix).
:- func rotate_x(float) = (matrix).
:- func rotate_y(float) = (matrix).
:- func rotate_z(float) = (matrix).

:- type row ---> r0 ; r1 ; r2 ; r3.
:- type col ---> c0 ; c1 ; c2 ; c3.

:- func element(matrix, col, row) = float.

:- func multiply(matrix, matrix) = (matrix).
:- func explicit_matrix(
    float, float, float, float,
    float, float, float, float,
    float, float, float, float,
    float, float, float, float) = matrix.

% frustum(NearZ, FarZ, Left, Right, Top, Bottom)
:- func frustum(float, float, float, float, float, float) = matrix.

:- func epsilon = (float).

%==============================================================================%
:- implementation.
%==============================================================================%

:- import_module float.
:- use_module math.

% C stuff

:- pragma foreign_enum("C", row/0,
    [
        r0 - "0",
        r1 - "1",
        r2 - "2",
        r3 - "3"
    ]).

:- pragma foreign_enum("C", col/0,
    [
        c0 - "0",
        c1 - "1",
        c2 - "2",
        c3 - "3"
    ]).

:- type float_ptr.
:- pragma foreign_type("C", float_ptr, "float*").

:- func load_matrix(matrix, float_ptr) = float_ptr.
:- func store_matrix(float_ptr) = matrix.

:- pragma foreign_export("C", element(in, in, in) = (out), "GetMatrixElement").
:- pragma foreign_export("C", load_matrix(in, in) = (out), "LoadMatrix").
:- pragma foreign_export("C", store_matrix(in) = (out), "StoreMatrix").
:- pragma foreign_export("C", identity = (out), "IdentityMatrix").
:- pragma foreign_export("C", explicit_matrix(
    in, in, in, in,
    in, in, in, in, 
    in, in, in, in, 
    in, in, in, in) = (out), "ExplicitMatrix").

explicit_matrix(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P) = 
    matrix(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P).

:- pragma foreign_proc("C", load_matrix(M::in, Ptr::in) = (Out::out),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        {
            unsigned i = 0, r, c;
            for(c = 0; c < 4; c++)
                for(r = 0; r < 4; r++)
                    ((float*)Ptr)[i++] = GetMatrixElement(M, c, r);
            Out = Ptr;
        }
    ").

:- pragma foreign_proc("C", store_matrix(Ptr::in) = (M::out),
    [will_not_throw_exception, promise_pure, thread_safe],
    "
        {
            const float *const ptr = (float*)Ptr;
            M = ExplicitMatrix(ptr[0], ptr[1], ptr[2], ptr[3],
                ptr[4], ptr[5], ptr[6], ptr[7],
                ptr[8], ptr[9], ptr[10], ptr[11],
                ptr[12], ptr[13], ptr[14], ptr[15]);
        }
    ").

% Mercury stuff

element(M, c0, r0) = M ^ a.
element(M, c1, r0) = M ^ b.
element(M, c2, r0) = M ^ c.
element(M, c3, r0) = M ^ d.

element(M, c0, r1) = M ^ e.
element(M, c1, r1) = M ^ f.
element(M, c2, r1) = M ^ g.
element(M, c3, r1) = M ^ h.

element(M, c0, r2) = M ^ i.
element(M, c1, r2) = M ^ j.
element(M, c2, r2) = M ^ k.
element(M, c3, r2) = M ^ l.

element(M, c0, r3) = M ^ m.
element(M, c1, r3) = M ^ n.
element(M, c2, r3) = M ^ o.
element(M, c3, r3) = M ^ p.

epsilon = 0.00001.

identity = matrix(
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0).

translation(vector.vector(X, Y, Z)) = matrix(
    1.0, 0.0, 0.0, X,
    0.0, 1.0, 0.0, Y,
    0.0, 0.0, 1.0, Z,
    0.0, 0.0, 0.0, 1.0).

scaling(vector.vector(X, Y, Z)) = matrix(
    X,   0.0, 0.0, 0.0,
    0.0, Y,   0.0, 0.0,
    0.0, 0.0, Z,   0.0,
    0.0, 0.0, 0.0, 1.0).

rotate_x(X) = matrix(
    1.0, 0.0, 0.0, 0.0,
    0.0, Cos,-Sin, 0.0,
    0.0, Sin, Cos, 0.0,
    0.0, 0.0, 0.0, 1.0) :-
    Sin = math.sin(X),
    Cos = math.cos(X).

rotate_y(Y) = matrix(
    Cos, 0.0, Sin, 0.0,
    0.0, 1.0, 0.0, 0.0,
   -Sin, 0.0, Cos, 0.0,
    0.0, 0.0, 0.0, 1.0) :-
    Sin = math.sin(Y),
    Cos = math.cos(Y).

rotate_z(Z) = matrix(
    Cos,-Sin, 0.0, 0.0,
    Sin, Cos, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0) :-
    Sin = math.sin(Z),
    Cos = math.cos(Z).

multiply(M0, M1) = matrix(
    (M0^a*M1^a)+(M0^b*M1^e)+(M0^c*M1^i)+(M0^d*M1^m), (M0^a*M1^b)+(M0^b*M1^f)+(M0^c*M1^j)+(M0^d*M1^n), (M0^a*M1^c)+(M0^b*M1^g)+(M0^c*M1^k)+(M0^d*M1^o), (M0^a*M1^d)+(M0^b*M1^h)+(M0^c*M1^l)+(M0^d*M1^p), 
    (M0^e*M1^a)+(M0^f*M1^e)+(M0^g*M1^i)+(M0^h*M1^m), (M0^e*M1^b)+(M0^f*M1^f)+(M0^g*M1^j)+(M0^h*M1^n), (M0^e*M1^c)+(M0^f*M1^g)+(M0^g*M1^k)+(M0^h*M1^o), (M0^e*M1^d)+(M0^f*M1^h)+(M0^g*M1^l)+(M0^h*M1^p), 
    (M0^i*M1^a)+(M0^j*M1^e)+(M0^k*M1^i)+(M0^l*M1^m), (M0^i*M1^b)+(M0^j*M1^f)+(M0^k*M1^j)+(M0^l*M1^n), (M0^i*M1^c)+(M0^j*M1^g)+(M0^k*M1^k)+(M0^l*M1^o), (M0^i*M1^d)+(M0^j*M1^h)+(M0^k*M1^l)+(M0^l*M1^p), 
    (M0^m*M1^a)+(M0^n*M1^e)+(M0^o*M1^i)+(M0^p*M1^m), (M0^m*M1^b)+(M0^n*M1^f)+(M0^o*M1^j)+(M0^p*M1^n), (M0^m*M1^c)+(M0^n*M1^g)+(M0^o*M1^k)+(M0^p*M1^o), (M0^m*M1^d)+(M0^n*M1^h)+(M0^o*M1^l)+(M0^p*M1^p)).

:- func ab_conj(float, float) = float.
ab_conj(A, B) = (A+B) / (A-B).

frustum(NearZ, FarZ, Left, Right, Top, Bottom) = matrix(
    N2/(Right-Left), 0.0, A, 0.0,
    0.0, N2/(Top-Bottom), B, 0.0,
    0.0, 0.0, C, D,
    0.0, 0.0, -1.0, 0.0) :-
    
    N2 = 2.0 * NearZ,
    A = ab_conj(Right, Left),
    B = ab_conj(Top, Bottom),
    C = ab_conj(NearZ, FarZ),
    D = -(N2 * FarZ) / (FarZ - NearZ).
