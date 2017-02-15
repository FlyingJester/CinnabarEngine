:- module opengl.
:- interface.

:- include_module opengl.texture.

:- type shape_type --->
	points ; 
	line_strip ; 
	line_loop ; 
	lines ; 
	triangle_strip ; 
	triangle_fan ; 
	triangles.

:- type filter_set --->
	texture_min_filter ; 
	texture_mag_filter.

:- type filter_type --->
	linear ; 
	nearest.

:- pred enable_depth_test(Window::di, Window::uo) is det.
:- pred disable_depth_test(Window::di, Window::uo) is det.
:- pred tex_parameter(filter_set::in, filter_type::in, Window::di, Window::uo) is det.
:- pred viewport(int::in, int::in, int::in, int::in, Window::di, Window::uo) is det.
:- pred clear_depth_buffer_bit(Window::di, Window::uo) is det.
:- pred point_size(float::in, Window::di, Window::uo) is det.
:- pred line_width(float::in, Window::di, Window::uo) is det.
:- pred draw_arrays(shape_type::in, int::in, int::in, Window::di, Window::uo) is det.
:- pred clear_color(int::in, int::in, int::in, int::in, Window::di, Window::uo) is det.

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

:- pragma foreign_enum("C", shape_type/0, [
	points - "GL_POINTS",
	line_strip - "GL_LINE_STRIP",
	line_loop - "GL_LINE_LOOP",
	lines - "GL_LINES",
	triangle_strip - "GL_TRIANGLE_STRIP",
	triangle_fan - "GL_TRIANGLE_FAN",
	triangles - "GL_TRIANGLES"]).

:- pragma foreign_enum("C", filter_set/0, [
	texture_min_filter - "GL_TEXTURE_MIN_FILTER",
	texture_mag_filter - "GL_TEXTURE_MAG_FILTER"]).

:- pragma foreign_enum("C", filter_type/0, [
	linear - "GL_LINEAR",
	nearest - "GL_NEAREST"]).


:- pragma foreign_proc("C", enable_depth_test(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glEnable(GL_DEPTH_TEST);
	").

:- pragma foreign_proc("C", disable_depth_test(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glDisable(GL_DEPTH_TEST);
	").

:- pragma foreign_proc("C", tex_parameter(FILTER_SET0::in, FILTER_TYPE1::in, WINDOW2::di, WINDOW3::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW3=WINDOW2;
	glTexParameterf(GL_TEXTURE_2D, FILTER_SET0, FILTER_TYPE1);
	").

:- pragma foreign_proc("C", viewport(INT0::in, INT1::in, INT2::in, INT3::in, WINDOW4::di, WINDOW5::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW5=WINDOW4;
	glViewport(INT0, INT1, INT2, INT3);
	").

:- pragma foreign_proc("C", clear_depth_buffer_bit(WINDOW0::di, WINDOW1::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW1=WINDOW0;
	glClear(GL_DEPTH_BUFFER_BIT);
	").

:- pragma foreign_proc("C", point_size(FLOAT0::in, WINDOW1::di, WINDOW2::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW2=WINDOW1;
	glPointSize(FLOAT0);
	").

:- pragma foreign_proc("C", line_width(FLOAT0::in, WINDOW1::di, WINDOW2::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW2=WINDOW1;
	glLineWidth(FLOAT0);
	").

:- pragma foreign_proc("C", draw_arrays(SHAPE_TYPE0::in, INT1::in, INT2::in, WINDOW3::di, WINDOW4::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW4=WINDOW3;
	glDrawArrays(SHAPE_TYPE0, INT1, INT2);
	").

:- pragma foreign_proc("C", clear_color(INT0::in, INT1::in, INT2::in, INT3::in, WINDOW4::di, WINDOW5::uo),
	[will_not_call_mercury, will_not_throw_exception,
	thread_safe, promise_pure, does_not_affect_liveness],
	"
	WINDOW5=WINDOW4;
	glClearColor(INT0, INT1, INT2, INT3);
	").
