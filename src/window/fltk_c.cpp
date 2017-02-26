#include "fltk_c.h"

#include <FL/Fl_Window.H>
#include <FL/Fl_Image.H>
#include <FL/Fl.H>

#include <vector>

#if !((defined _WIN32) || (defined __CYGWIN__) || (defined CYGWIN) || (defined __MSYS__) || (defined MSYS) || (defined __MSYS2__) || (defined MSYS2))
#define FLTK_USES_X11 1
#endif

class FLTK_WrapWindow : Fl_Gl_Window {
    void *const m_render_argument;
    void (*const m_render_callback)(void*);

    std::vector<FLTK_Event> m_events;
    unsigned short m_mouse_x, m_mouse_y;
    unsigned char m_key_state;
    enum EnumKeyStateBits {
        eShiftKey   = 1<<0,
        eControlKey = 1<<1,
        eAltKey     = 1<<2
    };
    
    void handleKey(bool pressed);
    void setMouse(){
        m_mouse_x = Fl::event_x();
        m_mouse_y = Fl::event_y();
    }
    
public:
    
    void getEvent(FLTK_Event &to) { to = m_events.back(); m_events.pop_back(); }
    bool empty() const { return m_events.empty(); }
    void clearEvents() { m_events.clear(); }
    
    unsigned short getMouseX() const { return m_mouse_x; }
    unsigned short getMouseY() const { return m_mouse_y; }
    
    FLTK_WrapWindow(unsigned a_w, unsigned a_h, const char *a_title, void *a_arg, void(*a_cb)(void*))
      : Fl_Gl_Window(a_w, a_h, a_title)
      , m_render_argument(a_arg)
      , m_render_callback(a_cb)
      , m_key_state(0){
        m_events.reserve(16);
        m_events.resize(1);
        FLTK_Event &event = m_events.back();
        event.m_type = eResizeEventType;
        event.m_value.m_resize.m_w = a_w;
        event.m_value.m_resize.m_h = a_h;
    }
    
    virtual int handle(int e){
        bool pressed = false;
        {
            const int state = Fl::event_state();
            m_key_state = 0;
            if(state & FL_SHIFT)
                m_key_state |= eShiftKey;
            
            if(state & FL_CTRL)
                m_key_state |= eControlKey;
            
            if(state & FL_ALT)
                m_key_state |= eAltKey;
        }
        
        switch(e){
            case FL_ENTER:
                return 1; // Ask for move and drag events.
            case FL_MOVE:
            case FL_DRAG:
                setMouse();
                return 1;
            case FL_PUSH:
                pressed = true; // FALLTHROUGH
            case FL_RELEASE:
                setMouse();
                m_events.resize(m_events.size()+1);
                {
                    FLTK_Event &event = m_events.back();
                    event.m_type = eMouseEventType;
                    event.m_value.m_mouse.m_click = pressed;
                    event.m_value.m_mouse.m_x = m_mouse_x;
                    event.m_value.m_mouse.m_y = m_mouse_y;
                    const int button = Fl::event_button();
                    event.m_value.m_mouse.m_button =
                        (button == FL_MIDDLE_MOUSE) ? eMiddleMouseButton :
                        (button == FL_RIGHT_MOUSE) ? eRightMouseButton :
                        eLeftMouseButton;
                }
                return 1;
            case FL_KEYDOWN:
                pressed = true; // FALLTHROUGH
            case FL_KEYUP:
                handleKey(pressed);
                return 1;
            default:
            return Fl_Gl_Window::handle(e);
        }
    }
    
    virtual void resize(int a_x, int a_y, int a_w, int a_h){
        m_events.resize(1);
        FLTK_Event &event = m_events.back();
        event.m_type = eResizeEventType;
        event.m_value.m_resize.m_w = a_w;
        event.m_value.m_resize.m_h = a_h;
        Fl_Gl_Window::resize(a_x, a_y, a_w, a_h);
    }
    
protected:
    virtual void draw(){
        if(valid())
            m_render_callback(m_render_argument);
    }
};

void FLTK_WrapWindow::handleKey(bool pressed){
    m_events.resize(m_events.size()+1);
    FLTK_Event &event = m_events.back();
    event.m_type = eKeyEventType;
    event.m_value.m_key.m_pressed = pressed;
#define ASSIGN_LITERAL(STR) memcpy(event.m_value.m_key.m_name, STR, sizeof(STR))
#define LITERAL_KEY(KEY, STR) case FL_##KEY: ASSIGN_LITERAL(STR); break
#define CHAR_KEY(KEY, CH) case FL_##KEY: event.m_value.m_key.m_name[0] = CH; event.m_value.m_key.m_name[1] = '\0'; break
    switch(Fl::event_key()){
        CHAR_KEY(Tab, '\t');
        case FL_KP_Enter: // FALLTHROUGH
        CHAR_KEY(Enter, '\n');
        LITERAL_KEY(Escape, "escape");
        LITERAL_KEY(BackSpace, "backspace");
        LITERAL_KEY(Print, "print");
        LITERAL_KEY(Pause, "pause");
        LITERAL_KEY(Insert, "insert");
        LITERAL_KEY(Home, "home");
        LITERAL_KEY(Page_Up, "page up");
        LITERAL_KEY(Page_Down, "page down");
        LITERAL_KEY(End, "end");
        LITERAL_KEY(Left, "left");
        LITERAL_KEY(Up, "up");
        LITERAL_KEY(Right, "right");
        LITERAL_KEY(Down, "down");
#ifdef FLTK_USES_X11
#define STATE_KEY(NAME, STR) case Fl_##NAME##_L: case Fl_##NAME##_L: ASSIGN_LITERAL(STR);\
if(pressed) m_key_state |= e##NAME##Key; else m_key_state &= ~e##NAME##Key; break
#else
#define STATE_KEY(NAME, STR) case Fl_##NAME##_L: case Fl_##NAME##_L: ASSIGN_LITERAL(STR); break
#endif
        STATE_KEY(Shift, "shift");
        STATE_KEY(Control, "control");
        STATE_KEY(Alt, "alt");
#undef STATE_KEY
            
        default:
            {
                const char *const text = Fl::event_text();
                for(unsigned i = 0; i < FLTK_EVENT_KEY_NAME_MAX; i++){
                    // TODO: Handle if truncation would cut off the end of a UTF codepoint.
                    const char c = text[i];
                    if(c == '\0'){
                        event.m_value.m_key.m_name[i] = c;
                        return;
                    }
                    else if(c >= 'A' && c <= 'Z')
                        event.m_value.m_key.m_name[i] = (c - 'A') + 'a';
                    else
                        event.m_value.m_key.m_name[i] = c;
                }
            }
            event.m_value.m_key.m_name[FLTK_EVENT_KEY_NAME_MAX-1] = '\0';
    }
    
#undef CHAR_KEY
#undef LITERAL_KEY
#undef ASSIGN_LITERAL
}

unsigned FLTK_Check(struct FLTK_Window *arg, struct FLTK_Event *out_event){
    FLTK_WrapWindow &window = *static_cast<>FLTK_WrapWindow*>(arg->m_data);
    if(!window.shown()){
        out_event->m_type = eQuitEventType;
        return 1;
    }
    
    if(window.empty())
        Fl::check();
    if(window.empty())
        return 0;
    
    window.getEvent(*out_event);
    return 1;
}

void FLTK_Wait(struct FLTK_Window *window, struct FLTK_Event *out_event){
    FLTK_WrapWindow &window = *static_cast<FLTK_WrapWindow*>(arg->m_data);
    if(!window.shown()){
        out_event->m_type = eQuitEventType;
        return;
    }
    while(window.empty())
        Fl::wait();
    
    window.getEvent(*out_event);
}

/* If successful, the m_data of in_out_window is not NULL. */
void FLTK_CreateWindow(struct FLTK_Window *in_out_window, char *title){
    FLTK_WrapWindow *const window = new FLTK_WrapWindow(
        in_out_window->m_w, in_out_window->m_h, title, m_render_argument, m_render_callback);
    window->show();
    window->context(NULL, 1);
    window->make_current();
}

void FLTK_DestroyWindowV(void *arg, void *unused_arg){
    FLTK_DestroyWindow(static_cast<FLTK_Window*>(arg), unused_arg);
}

void FLTK_DestroyWindow(struct FLTK_Window *arg, void *unused_arg){
    delete static_cast<FLTK_WrapWindow*>(arg->m_data);
}

void FLTK_FlushWindow(struct FLTK_Window *window){
    static_cast<FLTK_WrapWindow*>(arg->m_data)->flush();
}

void *FLTK_GetContext(struct FLTK_Window *arg){
    return static_cast<FLTK_WrapWindow*>(arg->m_data)->context();
}
