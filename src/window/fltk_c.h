#pragma once
/* FLTK bindings to C to allow a window typeclass to work from Mercury. */

#ifndef __cplusplus
extern "C"{
#endif

#define FLTK_EVENT_KEY_NAME_MAX 15
struct FLTK_Event{
    enum {
        eQuitEventType,
        eResizeEventType,
        eMouseEventType,
        eKeyEventType,
    } m_type;
    union {
        struct {
            unsigned char m_click;
            unsigned short m_x, m_y;
            enum {
                eLeftMouseButton,
                eRightMouseButton,
                eMiddleMouseButton
            } m_button;
        } m_mouse;
        struct {
            unsigned char m_fullscreen;
            unsigned short m_w, m_h;
        } m_resize;
        struct {
            unsigned char m_pressed;
            char m_name[FLTK_EVENT_KEY_NAME_MAX];
        } m_key;
    } m_value;
};

struct FLTK_Window{
    void *m_data;
    void *m_render_argument;
    void (*m_render_callback)(void*);
    unsigned short m_w, m_h;
    unsigned short m_mouse_x, m_mouse_y;
    unsigned short m_gl_major, m_gl_minor;
};

unsigned FLTK_Check(struct FLTK_Window *window, struct FLTK_Event *out_event);
void FLTK_Wait(struct FLTK_Window *window, struct FLTK_Event *out_event);

/* If successful, the m_data of in_out_window is not NULL. */
void FLTK_CreateWindow(struct FLTK_Window *in_out_window, char *title);
void FLTK_DestroyWindowV(void *window, void *unused_arg);
void FLTK_DestroyWindow(struct FLTK_Window *window, void *unused_arg);
void FLTK_FlushWindow(struct FLTK_Window *window);
void *FLTK_GetContext(struct FLTK_Window *window);

#ifndef __cplusplus
}
#endif
