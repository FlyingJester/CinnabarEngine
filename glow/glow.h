#pragma once

#ifndef GLOW_LIBRARY_HEADER_
#define GLOW_LIBRARY_HEADER_

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __GNUC__
#define GLOW_CONST __attribute__((const))
#define GLOW_PURE __attribute__((pure))
#define GLOW_RETURNS_NOT_NULL __attribute__((returns_nonnull))
#else
#define GLOW_CONST
#define GLOW_PURE
#define GLOW_RETURNS_NOT_NULL
#endif

#define GLOW_RESIZABLE   (1<<0)
#define GLOW_UNDECORATED (1<<1)

enum Glow_EventType {
	eGlowKeyboardPressed,
	eGlowKeyboardReleased,
	eGlowMousePressed,
	eGlowMouseReleased,
	eGlowResized,
	eGlowQuit = 0xFF
};

enum Glow_MouseButton{
	eGlowLeft,
	eGlowRight,
	eGlowMiddle
};

#define GLOW_COORD_X 0
#define GLOW_COORD_Y 1

#define GLOW_GET_X(THAT) (THAT[0])
#define GLOW_GET_Y(THAT) (THAT[1])

typedef unsigned short glow_pixel_coords_t[2];

#define GLOW_MAX_KEY_NAME_SIZE 16
struct Glow_Event{
	enum Glow_EventType type;
	union {
                /* String representing a key. Always null-terminated */
		char key[GLOW_MAX_KEY_NAME_SIZE];
                struct {
			glow_pixel_coords_t xy;
			enum Glow_MouseButton button;
		} mouse;
		glow_pixel_coords_t resize;
	} value;
};

/******************************************************************************/
/**
 * @brief A Window, wrapping an X11/Win32/Haiku/etc window.
 *
 * A Window or an Offscreen is required to make a GL context.
 */
struct Glow_Window;

/**
 * @brief Gets the size of the Window struct.
 *
 * You must allocate the memory for windows on the application side. This will
 * return the size needed.
 */
GLOW_CONST unsigned Glow_WindowStructSize();

/**
 * @brief Creates a Window
 *
 * The window is hidden by default.
 * 
 * @sa Glow_ShowWindow
 */
void Glow_CreateWindow(struct Glow_Window *out,
    unsigned w, unsigned h, const char *title, int flags);

/**
 * @brief Destroys a Window
 *
 * This will also destroy the Context (if it exists) for the Window.
 *
 * It is safe to free the memory for the window and the associated context
 * (if one exists) after calling this.
 */
void Glow_DestroyWindow(struct Glow_Window *window);

/**
 * @brief Sets the title of the Window
 */
void Glow_SetTitle(struct Glow_Window *window, const char *title);

/**
 * @brief Shows the Window
 *
 * The Window starts hidden, so this must be called before anything is visible.
 */
void Glow_ShowWindow(struct Glow_Window *window);

/**
 * @brief Hides the Window
 */
void Glow_HideWindow(struct Glow_Window *window);

/**
 * @brief Gets the dimensions of the Window.
 */
void Glow_GetWindowSize(const struct Glow_Window *window,
    unsigned *out_w, unsigned *out_h);

void Glow_FlipScreen(struct Glow_Window *window);

unsigned Glow_GetEvent(struct Glow_Window *window,
    struct Glow_Event *out_event);
void Glow_WaitEvent(struct Glow_Window *window, struct Glow_Event *out_event);

/**
 * @brief OpenGL Context
 *
 * Every context must be bound to a Window. A Window can only have a single
 * context. A single context may be made current on each thread as well, but a
 * context cannot be current on more than one thread.
 */
struct Glow_Context;

/**
 * @brief Gets the size of the Context struct.
 *
 * You must allocate the memory for contexts on the application side. This will
 * return the size needed.
 */
GLOW_CONST unsigned Glow_ContextStructSize();

/**
 * @brief Creates a context for the specified window
 *
 * The function will fail if the window already has a context, or if the OpenGL
 * version is not available.
 *
 * If you do not need context sharing or a 3+ version of OpenGL, you can use
 * Glow_CreateLegacyContext which is simpler for that case.
 *
 * The Context will be destroyed with the attached Window is destroyed.
 *
 * @param window Window to create a context for. Must not have a context yet
 * @param opt_share An optional context to share objects with
 * @param major Major OpenGL version to request
 * @param minor Minor OpenGL version to request
 * @param out Destination for context
 * @returns 0 on success, -1 on failure.
 *
 * @sa Glow_GetContext
 * @sa Glow_CreateLegacyContext
 */
int Glow_CreateContext(struct Glow_Window *window,
    struct Glow_Context *opt_share,
    unsigned major, unsigned minor,
    struct Glow_Context *out);

/**
 * @brief Creates a context for a Window
 *
 * The context will not share with any other context, and will be version
 * 2.1 or lower. This is useful just for bringing up a window and a context
 * quickly without worrying about more advanced or unneeded features.
 *
 * The Context will be destroyed with the attached Window is destroyed.
 *
 * @sa Glow_CreateContext
 */
void Glow_CreateLegacyContext(struct Glow_Window *window,
    struct Glow_Context *out);

/**
 * @brief Returns the Context for a Window
 *
 * May return NULL if no context exists for the Window yet.
 */
GLOW_PURE struct Glow_Context *Glow_GetContext(struct Glow_Window *window);

/**
 * @brief Makes the context current for this thread
 */
void Glow_MakeCurrent(struct Glow_Context *ctx);

/**
 * @brief Creates a Window and an associated legacy GL Context for it.
 *
 * @warning Unlike all the other calls for Glow, this one uses malloc to
 * allocate memory. You must call Glow_DestroyWindow and then free on the
 * returned Window to properly free the memory.
 * 
 * @sa Glow_CreateLegacyContext
 * @sa Glow_CreateWindow
 */
GLOW_RETURNS_NOT_NULL struct Glow_Window *Glow_CreateLegacyWindow(
    unsigned w, unsigned h, const char *title);

#ifdef __cplusplus
}
#endif

#endif /* GLOW_LIBRARY_HEADER_ */
