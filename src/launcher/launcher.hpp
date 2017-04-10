// generated by Fast Light User Interface Designer (fluid) version 1.0304

#ifndef launcher_hpp
#define launcher_hpp
#include <FL/Fl.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Wizard.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Round_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Int_Input.H>

class CinnabarLauncher : public Fl_Window {
  void _CinnabarLauncher();
public:
  CinnabarLauncher(int X, int Y, int W, int H, const char *L = 0);
  CinnabarLauncher(int W, int H, const char *L = 0);
  CinnabarLauncher();
  Fl_Button *play_button;
private:
  inline void cb_play_button_i(Fl_Button*, void*);
  static void cb_play_button(Fl_Button*, void*);
public:
  Fl_Button *options_button;
private:
  inline void cb_options_button_i(Fl_Button*, void*);
  static void cb_options_button(Fl_Button*, void*);
  inline void cb_Exit_i(Fl_Button*, void*);
  static void cb_Exit(Fl_Button*, void*);
public:
  Fl_Wizard *wiz;
  Fl_Group *logo_group;
  Fl_Group *options_group;
  Fl_Round_Button *en_fltk;
  Fl_Round_Button *en_glow;
  Fl_Check_Button *en_gl4;
  Fl_Check_Button *en_windowed;
  Fl_Int_Input *win_w;
  Fl_Int_Input *win_h;
private:
  inline void cb_Save_i(Fl_Button*, void*);
  static void cb_Save(Fl_Button*, void*);
public:
  void save();
};
int main(int argc, char **argv);
#endif