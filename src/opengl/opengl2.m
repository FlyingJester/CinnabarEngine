:- module opengl2.
:- interface.

:- use_module opengl.

:- type matrix_mode --->
	modelview ; 
	projection.

:- type material --->
	ambient ; 
	diffuse ; 
	specular ; 
	emission.

:- type face --->
	front ; 
	back ; 
	front_and_back.

:- pred vertex(float::in, float::in, Window::di, Window::uo) is det.
:- pred pop_matrix(Window::di, Window::uo) is det.
:- pred tex_coord(float::in, float::in, Window::di, Window::uo) is det.
:- pred disable_texture(Window::di, Window::uo) is det.
:- pred draw_pixels(int::in, int::in, c_pointer::in, Window::di, Window::uo) is det.
:- pred begin(opengl.shape_type::in, Window::di, Window::uo) is det.
:- pred color(float::in, float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred enable_texture(Window::di, Window::uo) is det.
:- pred scale(float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred raster_pos(float::in, float::in, Window::di, Window::uo) is det.
:- pred rotate(float::in, float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred normal(float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred translate(float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred color(float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred vertex(float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred load_identity(Window::di, Window::uo) is det.
:- pred frustum(float::in, float::in, float::in, float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred push_matrix(Window::di, Window::uo) is det.
:- pred matrix_mode(matrix_mode::in, Window::di, Window::uo) is det.
:- pred end(Window::di, Window::uo) is det.
:- pred ortho(float::in, float::in, float::in, float::in, float::in, float::in, Window::di, Window::uo) is det.
:- pred material(face::in, material::in, float::in, float::in, float::in, float::in, Window::di, Window::uo) is det.

:- implementation.

:- pragma foreign_decl("C", "
#ifdef WIN32_
#include <Windows.h>
#include <GL/gl.h>
#endif").

:- pragma foreign_decl("C", "
#ifdef __APPLE__
#include <OpenGL/gl.h>
#endif").

:- pragma foreign_decl("C", "
#if (!(defined(__APPLE__))) && (!(defined(_WIN32)))
#include <GL/gl.h>
#endif").

:- pragma foreign_enum("C", matrix_mode/0, [
	modelview - "GL_MODELVIEW",
	projection - "GL_PROJECTION"]).

:- pragma foreign_enum("C", material/0, [
	ambient - "GL_AMBIENT",
	diffuse - "GL_DIFFUSE",
	specular - "GL_SPECULAR",
	emission - "GL_EMISSION"]).

:- pragma foreign_enum("C", face/0, [
	front - "GL_FRONT",
	back - "GL_BACK",
	front_and_back - "GL_FRONT_AND_BACK"]).


:- pragma foreign_proc("C", vertex(FLOAT0::in, FLOAT1::in, WINDOW2::di, WINDOW3::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW3=WINDOW2;
	glVertex2f(FLOAT0, FLOAT1);
	").

:- pragma foreign_proc("C", pop_matrix(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glPopMatrix();
	").

:- pragma foreign_proc("C", tex_coord(FLOAT0::in, FLOAT1::in, WINDOW2::di, WINDOW3::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW3=WINDOW2;
	glTexCoord2f(FLOAT0, FLOAT1);
	").

:- pragma foreign_proc("C", disable_texture(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glDisable(GL_TEXTURE_2D);
	").

:- pragma foreign_proc("C", draw_pixels(INT0::in, INT1::in, C_POINTER2::in, WINDOW3::di, WINDOW4::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW4=WINDOW3;
	glDrawPixels(INT0, INT1, GL_RGBA, GL_UNSIGNED_BYTE, (const void*)C_POINTER2);
	").

:- pragma foreign_proc("C", begin(SHAPE_TYPE0::in, WINDOW1::di, WINDOW2::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW2=WINDOW1;
	glBegin(SHAPE_TYPE0);
	").

:- pragma foreign_proc("C", color(FLOAT0::in, FLOAT1::in, FLOAT2::in, FLOAT3::in, WINDOW4::di, WINDOW5::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW5=WINDOW4;
	glColor4f(FLOAT0, FLOAT1, FLOAT2, FLOAT3);
	").

:- pragma foreign_proc("C", enable_texture(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glEnable(GL_TEXTURE_2D);
	").

:- pragma foreign_proc("C", scale(FLOAT0::in, FLOAT1::in, FLOAT2::in, WINDOW3::di, WINDOW4::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW4=WINDOW3;
	glScalef(FLOAT0, FLOAT1, FLOAT2);
	").

:- pragma foreign_proc("C", raster_pos(FLOAT0::in, FLOAT1::in, WINDOW2::di, WINDOW3::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW3=WINDOW2;
	glRasterPos2f(FLOAT0, FLOAT1);
	").

:- pragma foreign_proc("C", rotate(FLOAT0::in, FLOAT1::in, FLOAT2::in, FLOAT3::in, WINDOW4::di, WINDOW5::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW5=WINDOW4;
	glRotatef(FLOAT0, FLOAT1, FLOAT2, FLOAT3);
	").

:- pragma foreign_proc("C", normal(FLOAT0::in, FLOAT1::in, FLOAT2::in, WINDOW3::di, WINDOW4::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW4=WINDOW3;
	glNormal3f(FLOAT0, FLOAT1, FLOAT2);
	").

:- pragma foreign_proc("C", translate(FLOAT0::in, FLOAT1::in, FLOAT2::in, WINDOW3::di, WINDOW4::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW4=WINDOW3;
	glTranslatef(FLOAT0, FLOAT1, FLOAT2);
	").

:- pragma foreign_proc("C", color(FLOAT0::in, FLOAT1::in, FLOAT2::in, WINDOW3::di, WINDOW4::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW4=WINDOW3;
	glColor3f(FLOAT0, FLOAT1, FLOAT2);
	").

:- pragma foreign_proc("C", vertex(FLOAT0::in, FLOAT1::in, FLOAT2::in, WINDOW3::di, WINDOW4::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW4=WINDOW3;
	glVertex3f(FLOAT0, FLOAT1, FLOAT2);
	").

:- pragma foreign_proc("C", load_identity(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glLoadIdentity();
	").

:- pragma foreign_proc("C", frustum(FLOAT0::in, FLOAT1::in, FLOAT2::in, FLOAT3::in, FLOAT4::in, FLOAT5::in, WINDOW6::di, WINDOW7::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW7=WINDOW6;
	glFrustum(FLOAT0, FLOAT1, FLOAT2, FLOAT3, FLOAT4, FLOAT5);
	").

:- pragma foreign_proc("C", push_matrix(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glPushMatrix();
	").

:- pragma foreign_proc("C", matrix_mode(MATRIX_MODE0::in, WINDOW1::di, WINDOW2::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW2=WINDOW1;
	glMatrixMode(MATRIX_MODE0);
	").

:- pragma foreign_proc("C", end(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glEnd();
	").

:- pragma foreign_proc("C", ortho(FLOAT0::in, FLOAT1::in, FLOAT2::in, FLOAT3::in, FLOAT4::in, FLOAT5::in, WINDOW6::di, WINDOW7::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW7=WINDOW6;
	glOrtho(FLOAT0, FLOAT1, FLOAT2, FLOAT3, FLOAT4, FLOAT5);
	").

:- pragma foreign_proc("C", material(FACE0::in, MATERIAL1::in, FLOAT2::in, FLOAT3::in, FLOAT4::in, FLOAT5::in, WINDOW6::di, WINDOW7::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	float Array2[4];
	Array2[0] = FLOAT2;
	Array2[1] = FLOAT3;
	Array2[2] = FLOAT4;
	Array2[3] = FLOAT5;

	WINDOW7=WINDOW6;
	glMaterialfv(FACE0, MATERIAL1, Array2);
	").

