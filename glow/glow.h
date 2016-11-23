#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Windowing interface */
struct Glow_Window;
struct Glow_Window *Glow_CreateWindow(unsigned w, unsigned h, const char *title, unsigned gl_maj, unsigned gl_min);

void Glow_DestroyWindow(struct Glow_Window *w);

void Glow_ShowWindow(struct Glow_Window *);
void Glow_HideWindow(struct Glow_Window *);

void Glow_MakeCurrent(struct Glow_Window *);

void Glow_FlipScreen(struct Glow_Window *);

/* Input interface */
enum Glow_EventType {
	eGlowUnknown,
	eGlowKeyboardPressed,
	eGlowKeyboardReleased,
	eGlowMouseClick,
	eGlowResized,
	eGlowQuit = 0xFF
};

enum Glow_MouseButton{
	eGlowLeft,
	eGlowRight,
	eGlowMiddle
};

typedef unsigned short glow_pixel_coords_t[2];

struct Glow_Event{
	enum Glow_EventType type;
	union {
		char key[16]; /* Always null-terminated */
		struct {
			glow_pixel_coords_t xy;
			enum Glow_MouseButton button;
		} mouse;
		unsigned quit;
		glow_pixel_coords_t resize;
	} value;
};

/* Key constants */
#define GLOW_ESCAPE      "escape"
#define GLOW_SHIFT       "shift"
#define GLOW_CONTROL     "control"
#define GLOW_BACKSPACE   "backspace"
#define GLOW_DELETE   "backspace"
#define GLOW_UP_ARROW    "up"
#define GLOW_DOWN_ARROW  "down"
#define GLOW_LEFT_ARROW  "left"
#define GLOW_RIGHT_ARROW "right"
#define GLOW_ENTER "enter"
#define GLOW_RETURN GLOW_ENTER
#define GLOW_TAB "tab"

/* Returns 1 if there is an even, 0 otherwise */
unsigned Glow_GetEvent(struct Glow_Window *w, struct Glow_Event *out_event);

unsigned Glow_GetKeyPressed(struct Glow_Window *w, char out_key[16]);
void Glow_GetMousePosition(struct Glow_Window *w, glow_pixel_coords_t out_pos);

/* Define your main as this. */
int glow_main(int argc, char *argv[]);

#ifdef __cplusplus
}
#endif
