#include "glow.h"

#include <Windows.h>
#include <gl/gl.h>

#include <assert.h>
#include <stdio.h>

#include <stdlib.h>

#undef WinMain

struct Glow_Window{
	HDC dc;
	HWND win;
	HGLRC ctx;
	unsigned gl_mag, gl_min;
};

#ifdef __GNUC__
HINSTANCE __mingw_winmain_hInstance;
LPWSTR __mingw_winmain_lpCmdLine;
DWORD __mingw_winmain_nShowCmd;
extern char **__argv;
extern int __argc;

#ifdef WinMain
#undef WinMain
#endif

#endif

#define GLOW_CLASS_NAME "GlowWindow"
static HINSTANCE glow_app = NULL;
static const PIXELFORMATDESCRIPTOR glow_pixel_format = {
	sizeof(PIXELFORMATDESCRIPTOR),
	1, /* Version, always 1 */
	PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
	PFD_TYPE_RGBA,
	32, /* Color Depth */
	0, 0, 0, 0, 0, 0, /* Individual color depths and shifts */
	0,
	0,
	0,
	0, 0, 0, 0,
	16, /* Depth buffer size */
	8, /* Stencil buffer size */
	0,
	PFD_MAIN_PLANE,
	0,
	0, 0, 0
};

static LRESULT WINAPI glow_window_proc(HWND wnd, UINT msg, WPARAM parm, LPARAM lparam){
	if(msg == WM_CREATE){
/*		typedef BOOL (*wglow_choose_pixel_format)(HDC, const int*, const FLOAT*, UINT, int*, UINT*); */
		struct Glow_Window *const window = (struct Glow_Window *)(((CREATESTRUCT*)lparam)->lpCreateParams);
		const int let = ChoosePixelFormat((window->dc = GetDC(wnd)), &glow_pixel_format);
		SetPixelFormat(window->dc, let, &glow_pixel_format);
		window->ctx = wglCreateContext(window->dc);
		wglMakeCurrent(window->dc, window->ctx);
		glClearColor(0.75, 0.333, 0.0, 1.0);
		return 0;
	}
	else if(msg == WM_SHOWWINDOW){
        if(parm == FALSE)
            PostQuitMessage(EXIT_SUCCESS);
        else
            ShowWindow(wnd, SW_SHOWNORMAL);
		return 0;
	}
	else if(msg == WM_CLOSE || msg == WM_DESTROY){
		PostQuitMessage(EXIT_SUCCESS);
        return 0;
	}
	else{
		return DefWindowProc(wnd, msg, parm, lparam);
	}
}

int WINAPI WinMain(HINSTANCE app, HINSTANCE prev, LPSTR cmdline, int showcmd){

	WNDCLASS wc = {
		CS_OWNDC,
		glow_window_proc,
		0,
		0,
		0,
		NULL,
		NULL,
		(HBRUSH)(COLOR_BACKGROUND),
		NULL,
		GLOW_CLASS_NAME
	};
	wc.hInstance = glow_app = app;
	
	RegisterClass(&wc);
	
	if(prev || cmdline || showcmd){}
	
#ifdef __GNUC__
	__mingw_winmain_nShowCmd = showcmd;
#endif

	return glow_main(__argc, __argv);
}

struct Glow_Window *Glow_CreateWindow(unsigned w, unsigned h, const char *title, unsigned gl_maj, unsigned gl_min){
	struct Glow_Window *const window = malloc(sizeof(struct Glow_Window));
	
	window->gl_mag = gl_maj;
	window->gl_min = gl_min;
	
	if(glow_app == NULL){
		WNDCLASS wc = {
			CS_OWNDC,
			glow_window_proc,
			0,
			0,
			0,
			NULL,
			NULL,
			(HBRUSH)(COLOR_BACKGROUND),
			NULL,
			GLOW_CLASS_NAME
		};
		wc.hInstance = glow_app = GetModuleHandle(NULL);
		
		RegisterClass(&wc);
	}

    {
        const DWORD style = WS_OVERLAPPED | WS_CAPTION | WS_BORDER | WS_MINIMIZEBOX | WS_SYSMENU; 
        window->win = CreateWindow(GLOW_CLASS_NAME, title, style, 64, 64, w, h, NULL, NULL, glow_app, window);
	}
    
	return window;
}

void Glow_DestroyWindow(struct Glow_Window *w){
	wglDeleteContext(w->ctx);
	DestroyWindow(w->win);
}

void Glow_ShowWindow(struct Glow_Window *w){
	ShowWindow(w->win, SW_SHOWNORMAL);
}

void Glow_HideWindow(struct Glow_Window *w){
	ShowWindowAsync(w->win, SW_HIDE);
}

void Glow_MakeCurrent(struct Glow_Window *w){
	wglMakeCurrent(w->dc, w->ctx);
}

void Glow_FlipScreen(struct Glow_Window *w){
	wglMakeCurrent(w->dc, w->ctx);
	glFinish();
	wglSwapLayerBuffers(w->dc, WGL_SWAP_MAIN_PLANE);
	glClear(GL_COLOR_BUFFER_BIT);
}

/*
enum Glow_EventType {
	eGlowUnknown,
	eGlowKeyboard,
	eGlowMouseClick,
	eGlowQuit
};

enum Glow_MouseButton{
	eGlowLeft,
	eGlowRight,
	eGlowMiddle
};

struct Glow_Event{
	enum Glow_EventType type;
	union {
		char key[16];
		struct {
			unsigned x, y;
			enum Glow_MouseButton button;
		} mouse;
	} value;
};
*/

static void glow_translate_local_mouse_pos(POINT *pnt,
	struct Glow_Window *w, glow_pixel_coords_t out_pos){
	RECT rect;
	GetWindowRect(w->win, &rect);

	out_pos[0] = pnt->x - rect.left;
	out_pos[1] = pnt->y - rect.top;
	
	if(!PtInRect(&rect, *pnt)){
		if(pnt->x < rect.left)
			out_pos[0] = 0;
		else if(pnt->x > rect.right)
			out_pos[0] = rect.right - rect.left;
		
		if(pnt->y < rect.top)
			out_pos[1] = 0;
		else if(pnt->y > rect.bottom)
			out_pos[1] = rect.bottom - rect.top;
	}
}

static char glow_get_key_char(unsigned in){
	if(in <= 0x5A && in >= 0x41){
		return (in - 0x41) + 'a';
	}
	if(in <= 0x39 && in >= 0x30){
		return (in - 0x30) + '0';
	}
	if(in == VK_SPACE)
		return ' ';
	
	return '\0';
}

static const char *glow_get_key_string(unsigned in, unsigned *len){
#define GLOW_IN_VK(N, VAL) case N: len[0] = sizeof(VAL) - 1; assert(sizeof(VAL) < 16); return VAL
	switch(in){
		GLOW_IN_VK(VK_ESCAPE, GLOW_ESCAPE);
		case VK_LSHIFT: case VK_RSHIFT:
		GLOW_IN_VK(VK_SHIFT, GLOW_SHIFT);
		case VK_LCONTROL: case VK_RCONTROL:
		GLOW_IN_VK(VK_CONTROL, GLOW_CONTROL);
		GLOW_IN_VK(VK_BACK, GLOW_BACKSPACE);
		GLOW_IN_VK(VK_RETURN, GLOW_ENTER);
		GLOW_IN_VK(VK_TAB, GLOW_TAB);
		GLOW_IN_VK(VK_CLEAR, "clear");
		GLOW_IN_VK(VK_LEFT, GLOW_LEFT_ARROW);
		GLOW_IN_VK(VK_DELETE, GLOW_DELETE);
		GLOW_IN_VK(VK_UP, GLOW_UP_ARROW);
		GLOW_IN_VK(VK_DOWN, GLOW_DOWN_ARROW);
		GLOW_IN_VK(VK_RIGHT, GLOW_RIGHT_ARROW);
		case VK_OEM_2: case VK_OEM_3: case VK_OEM_4: case VK_OEM_5:
		case VK_OEM_6: case VK_OEM_7: case VK_OEM_8: case VK_OEM_102: case VK_NONAME:
		GLOW_IN_VK(VK_OEM_1, "216");
#undef GLOW_IN_VK
		default: return NULL;
	}
}

/* Returns 1 if there is an even, 0 otherwise */
unsigned Glow_GetEvent(struct Glow_Window *w, struct Glow_Event *out_event){
	MSG message;
get_msg:
	if(PeekMessage(&message, w->win, 0, 0, PM_REMOVE)){
		
		assert(message.hwnd == NULL || message.hwnd == w->win);
		/* Check for the messages we handle... */
		
		out_event->value.mouse.button = 0xFF;
		switch(message.message){
			case WM_KEYDOWN:
				{
					const char c = glow_get_key_char(message.wParam),
						*c_str;
					unsigned len;
					if(c){
						out_event->value.key[0] = c;
						out_event->value.key[1] = '\0';
						return 1;
					}
					else if ((c_str = glow_get_key_string(message.wParam, &len))){
						assert(len + 1< 16);
						memcpy(out_event->value.key, c_str, len);
						out_event->value.key[len] = '\0';
						return 1;
					}
					else /* Drop input */
						goto get_msg;
				}
			case WM_LBUTTONDOWN:
				if(out_event->value.mouse.button == 0xFF)
					out_event->value.mouse.button = eGlowLeft;
					/* FALLTHROUGH */
			case WM_RBUTTONDOWN:
				if(out_event->value.mouse.button == 0xFF)
					out_event->value.mouse.button = eGlowRight;
				
				glow_translate_local_mouse_pos(&message.pt, w, out_event->value.mouse.xy);
				out_event->type = eGlowMouseClick;
				return 1;
			case WM_DESTROY:
			case WM_CLOSE:
			case WM_QUIT:/*
				DestroyWindow(w->win);*/
				out_event->type = eGlowQuit;
				out_event->value.quit = message.wParam;
				return 1;
			default:
				DispatchMessage(&message);
				goto get_msg;
		}
		
		return 1;
	}
	else
		return 0;
}

unsigned Glow_GetKeyPressed(struct Glow_Window *w, char out_key[16]){
	if(w || out_key){}
	return 0;
}

void Glow_GetMousePosition(struct Glow_Window *w, glow_pixel_coords_t out_pos){
	POINT pnt;
	GetCursorPos(&pnt);
	glow_translate_local_mouse_pos(&pnt, w, out_pos);
}
