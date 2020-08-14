/*
 * Modififer Key
 *
 *     -> XCB_MOD_MASK_1 (Alt)
 *     -> XCB_MOD_MASK_4 (Super/Windows)
 */
#define MOD XCB_MOD_MASK_4

/*
 * Movement speed (in pixels)
 */
static const uint16_t movements[] = {
    20,     /* Movement step (slow) */
    40,     /* Movement step (fast) */
    15,     /* Mouse (slow)         */
    400     /* Mouse (fast)         */
};
/* resize by line like in mcwm -- jmbi */
static const bool  resize_by_line = true;
/* the ratio used when resizing and keeping the aspect */
static const float  resize_keep_aspect_ratio = 1.03;

/*
 * Offsets
 */
static const uint8_t offsets[] = {
    0,    /* x offset   */
    0,    /* y offset   */
    0,    /* Max width  */
    0     /* Max height */
};

/*
 * Colour Settings
 */
static const char *colors[] = {
  "#859900",  /* Focused colour          */
  "#2aa198",  /* Unfocused colour        */
  "#b58900",  /* Fixed colour            */
  "#dc322f",  /* Unkillable colour       */
  "#eee8d5",  /* Fixed-Unkillable colour */
  "#93a1a1",  /* Outer border colour     */
  "#586e75"   /* Empty colour            */
};
/* if this is set to true the inner border and outer borders colors will be swapped */
static const bool inverted_colors = false;

/*
 * Default Cursor position (Relative to the current window):
 *
 *     -> TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, MIDDLE
 */
#define CURSOR_POSITION TOP_LEFT

/*
 * Border Settings
 */
static const uint8_t borders[] = {
    3,     /* Outer border size  */
    6,     /* Full border width  */
    6,     /* Magnet border size */
    6      /* Resize border size */
};

/*
 * Windows that won't have a border.
 *
 *     -> Uses substring comparison to 'WM_NAME' attribute of window.
 *     -> Test using 'xprop WM_NAME'.
 */
#define LOOK_INTO "WM_NAME"
static const char *ignore_names[] = {"bar", "xclock"};

/*
 * Programs
 */
static const char *terminal[]  = { "terminator", NULL };

/*
 * Custom foo
 */
static void halfandcentered(const Arg *arg)
{
	Arg arg2 = {.i=TWOBWM_MAXHALF_VERTICAL_LEFT};
	maxhalf(&arg2);
	Arg arg3 = {.i=TWOBWM_TELEPORT_CENTER};
	teleport(&arg3);
}

static void maxwithborders(const Arg *arg)
{
	Arg arg2 = {.i=TWOBWM_MAXHALF_VERTICAL_LEFT};
	maxhalf(&arg2);
	Arg arg3 = {.i=TWOBWM_MAXIMIZE_HORIZONTALLY};
	maxvert_hor(&arg3);
}

/*
 * Sloppy focus behavior
 *
 * Command to execute when switching from sloppy focus to click to focus
 * The strings "Sloppy" and "Click" will be passed as the last argument
 * If NULL this is ignored
 */
static const char *sloppy_switch_cmd[] = {};
//static const char *sloppy_switch_cmd[] = { "notify-send", "toggle sloppy", NULL };
static void toggle_sloppy(const Arg *arg)
{
	is_sloppy = !is_sloppy;
	if (arg->com != NULL && LENGTH(arg->com) > 0) {
		start(arg);
	}
}

/*
 * Keybindings
 *
 *     -> Use 'xbindkeys --key' to find keycodes.
 *
 */
#define DESKTOPCHANGE(K,N) \
{  MOD ,             K,              changeworkspace, {.i=N}}, \
{  MOD |SHIFT,       K,              sendtoworkspace, {.i=N}},
static key keys[] = {
    /* Modifier            Key            Function           Argument */
    // Focus to next/previous window
    {  MOD ,              XK_Tab,        focusnext,         {.i=TWOBWM_FOCUS_NEXT}},
    {  MOD |SHIFT,        XK_Tab,        focusnext,         {.i=TWOBWM_FOCUS_PREVIOUS}},
    // Kill a window
    {  MOD ,              XK_q,          deletewin,         {}},
    // Resize a window
    {  MOD |SHIFT,        XK_k,          resizestep,        {.i=TWOBWM_RESIZE_UP}},
    {  MOD |SHIFT,        XK_j,          resizestep,        {.i=TWOBWM_RESIZE_DOWN}},
    {  MOD |SHIFT,        XK_l,          resizestep,        {.i=TWOBWM_RESIZE_RIGHT}},
    {  MOD |SHIFT,        XK_h,          resizestep,        {.i=TWOBWM_RESIZE_LEFT}},
    // Resize a window slower
    {  MOD |SHIFT|CONTROL,XK_k,          resizestep,        {.i=TWOBWM_RESIZE_UP_SLOW}},
    {  MOD |SHIFT|CONTROL,XK_j,          resizestep,        {.i=TWOBWM_RESIZE_DOWN_SLOW}},
    {  MOD |SHIFT|CONTROL,XK_l,          resizestep,        {.i=TWOBWM_RESIZE_RIGHT_SLOW}},
    {  MOD |SHIFT|CONTROL,XK_h,          resizestep,        {.i=TWOBWM_RESIZE_LEFT_SLOW}},
    // Move a window
    {  MOD ,              XK_k,          movestep,          {.i=TWOBWM_MOVE_UP}},
    {  MOD ,              XK_j,          movestep,          {.i=TWOBWM_MOVE_DOWN}},
    {  MOD ,              XK_l,          movestep,          {.i=TWOBWM_MOVE_RIGHT}},
    {  MOD ,              XK_h,          movestep,          {.i=TWOBWM_MOVE_LEFT}},
    // Move a window slower
    {  MOD |CONTROL,      XK_k,          movestep,          {.i=TWOBWM_MOVE_UP_SLOW}},
    {  MOD |CONTROL,      XK_j,          movestep,          {.i=TWOBWM_MOVE_DOWN_SLOW}},
    {  MOD |CONTROL,      XK_l,          movestep,          {.i=TWOBWM_MOVE_RIGHT_SLOW}},
    {  MOD |CONTROL,      XK_h,          movestep,          {.i=TWOBWM_MOVE_LEFT_SLOW}},
    // Teleport the window to an area of the screen.
    // Center:
    {  MOD ,              XK_g,          teleport,          {.i=TWOBWM_TELEPORT_CENTER}},
    // Center y:
    {  MOD |SHIFT,        XK_g,          teleport,          {.i=TWOBWM_TELEPORT_CENTER_Y}},
    // Center x:
    {  MOD |CONTROL,      XK_g,          teleport,          {.i=TWOBWM_TELEPORT_CENTER_X}},
    // Top left:
    {  MOD ,              XK_y,          teleport,          {.i=TWOBWM_TELEPORT_TOP_LEFT}},
    // Top right:
    {  MOD ,              XK_u,          teleport,          {.i=TWOBWM_TELEPORT_TOP_RIGHT}},
    // Bottom left:
    {  MOD ,              XK_b,          teleport,          {.i=TWOBWM_TELEPORT_BOTTOM_LEFT}},
    // Bottom right:
    {  MOD ,              XK_n,          teleport,          {.i=TWOBWM_TELEPORT_BOTTOM_RIGHT}},
    // Resize while keeping the window aspect
    {  MOD ,              XK_bracketleft,        resizestep_aspect, {.i=TWOBWM_RESIZE_KEEP_ASPECT_SHRINK}},
    {  MOD ,              XK_bracketright,       resizestep_aspect, {.i=TWOBWM_RESIZE_KEEP_ASPECT_GROW}},
    // Maximize vertically
    {  MOD ,              XK_m,          maxvert_hor,       {.i=TWOBWM_MAXIMIZE_VERTICALLY}},
    // Maximize horizontally
    {  MOD |SHIFT,        XK_m,          maxvert_hor,       {.i=TWOBWM_MAXIMIZE_HORIZONTALLY}},
    // Maximize and move
    // vertically left
    {  MOD |SHIFT,        XK_y,          maxhalf,           {.i=TWOBWM_MAXHALF_VERTICAL_LEFT}},
    // vertically right
    {  MOD |SHIFT,        XK_u,          maxhalf,           {.i=TWOBWM_MAXHALF_VERTICAL_RIGHT}},
    // horizontally left
    {  MOD |SHIFT,        XK_b,          maxhalf,           {.i=TWOBWM_MAXHALF_HORIZONTAL_BOTTOM}},
    // horizontally right
    {  MOD |SHIFT,        XK_n,          maxhalf,           {.i=TWOBWM_MAXHALF_HORIZONTAL_TOP}},
    //fold half vertically
    {  MOD |SHIFT|CONTROL,XK_y,          maxhalf,           {.i=TWOBWM_MAXHALF_FOLD_VERTICAL}},
    //fold half horizontally
    {  MOD |SHIFT|CONTROL,XK_b,          maxhalf,           {.i=TWOBWM_MAXHALF_FOLD_HORIZONTAL}},
    //unfold vertically
    {  MOD |SHIFT|CONTROL,XK_u,          maxhalf,           {.i=TWOBWM_MAXHALF_UNFOLD_VERTICAL}},
    //unfold horizontally
    {  MOD |SHIFT|CONTROL,XK_n,          maxhalf,           {.i=TWOBWM_MAXHALF_UNFOLD_HORIZONTAL}},
    // Next/Previous screen
    {  MOD ,              XK_comma,      changescreen,      {.i=TWOBWM_NEXT_SCREEN}},
    {  MOD ,              XK_period,     changescreen,      {.i=TWOBWM_PREVIOUS_SCREEN}},
    // Raise or lower a window
    {  MOD ,              XK_r,          raiseorlower,      {}},
    // Next/Previous workspace
    {  MOD ,              XK_v,          nextworkspace,     {}},
    {  MOD ,              XK_c,          prevworkspace,     {}},
    // Move to Next/Previous workspace
    {  MOD |SHIFT ,       XK_v,          sendtonextworkspace,{}},
    {  MOD |SHIFT ,       XK_c,          sendtoprevworkspace,{}},
    // Make the window unkillable
    {  MOD ,              XK_a,          unkillable,        {}},
    // Make the window appear always on top
    {  MOD,               XK_t,          always_on_top,     {}},
    // Make the window stay on all workspaces
    {  MOD ,              XK_f,          fix,               {}},
    // Start programs
    {  MOD ,              XK_Return,     start,             {.com = terminal}},
    // Exit or restart 2bwm
    {  MOD |CONTROL,      XK_q,          twobwm_exit,       {.i=0}},
    {  MOD |CONTROL,      XK_r,          twobwm_restart,    {.i=0}},
    // Custom foo
    {  MOD ,              XK_space,      halfandcentered,   {.i=0}},
    {  MOD ,              XK_x,          maxwithborders,    {.i=0}},
    {  MOD |SHIFT,        XK_x,          maximize,          {}},
    {  MOD |SHIFT|CONTROL,XK_x,          fullscreen,        {}},
    {  MOD ,              XK_s,          toggle_sloppy,     {.com = sloppy_switch_cmd}},
    // Change current workspace
       DESKTOPCHANGE(     XK_1,                             0)
       DESKTOPCHANGE(     XK_2,                             1)
       DESKTOPCHANGE(     XK_3,                             2)
       DESKTOPCHANGE(     XK_4,                             3)
       DESKTOPCHANGE(     XK_5,                             4)
};
// the last argument makes it a root window only event
static Button buttons[] = {
    {  MOD        ,XCB_BUTTON_INDEX_1,     mousemotion,   {.i=TWOBWM_MOVE}, false},
    {  MOD        ,XCB_BUTTON_INDEX_3,     mousemotion,   {.i=TWOBWM_RESIZE}, false},
    {  MOD|SHIFT,  XCB_BUTTON_INDEX_1,     changeworkspace, {.i=0}, false},
    {  MOD|SHIFT,  XCB_BUTTON_INDEX_3,     changeworkspace, {.i=1}, false},
    {  MOD|ALT,    XCB_BUTTON_INDEX_1,     changescreen,    {.i=1}, false},
    {  MOD|ALT,    XCB_BUTTON_INDEX_3,     changescreen,    {.i=0}, false}
};
