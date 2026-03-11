; =============================================================================
; tui.inc  —  Full-Screen TUI Library Public API
; =============================================================================
; Terminal: ANSI/VT100 escape sequences, 80×24 characters
; All routines preserve A, X, Y unless documented otherwise.
; =============================================================================

; -----------------------------------------------------------------------------
; Attribute byte layout  (stored in TUI_ATTR)
;
;   Bits 7–4 : background color index (0–7, see colors below)
;   Bits 3–0 : foreground color index (0–7)
;
; High-level helpers set TUI_ATTR; raw escape is emitted by tui_set_attr.
; -----------------------------------------------------------------------------

; Color indices
TUI_BLACK   = 0
TUI_RED     = 1
TUI_GREEN   = 2
TUI_YELLOW  = 3
TUI_BLUE    = 4
TUI_MAGENTA = 5
TUI_CYAN    = 6
TUI_WHITE   = 7

; Build an attribute byte:  FG | (BG << 4)
.define TUI_ATTR_BYTE(fg, bg)  ((bg << 4) | fg)

; Common pre-built attributes
TUI_NORMAL      = TUI_ATTR_BYTE(TUI_WHITE,   TUI_BLACK)
TUI_REVERSE     = TUI_ATTR_BYTE(TUI_BLACK,   TUI_WHITE)
TUI_HIGHLIGHT   = TUI_ATTR_BYTE(TUI_YELLOW,  TUI_BLACK)
TUI_TITLE_ATTR  = TUI_ATTR_BYTE(TUI_BLACK,   TUI_CYAN)
TUI_STATUS_ATTR = TUI_ATTR_BYTE(TUI_BLACK,   TUI_GREEN)
TUI_ERROR_ATTR  = TUI_ATTR_BYTE(TUI_WHITE,   TUI_RED)
TUI_BORDER_ATTR = TUI_ATTR_BYTE(TUI_CYAN,    TUI_BLACK)

; -----------------------------------------------------------------------------
; Box-drawing characters (use VT100 alternate character set via ACS)
; These are the ACS code values to pass to tui_putch_acs
; -----------------------------------------------------------------------------
ACS_ULCORNER    = 'l'   ; ┌
ACS_URCORNER    = 'k'   ; ┐
ACS_LLCORNER    = 'm'   ; └
ACS_LRCORNER    = 'j'   ; ┘
ACS_HLINE       = 'q'   ; ─
ACS_VLINE       = 'x'   ; │
ACS_LTEE        = 't'   ; ├
ACS_RTEE        = 'u'   ; ┤
ACS_BTEE        = 'v'   ; ┴
ACS_TTEE        = 'w'   ; ┬
ACS_PLUS        = 'n'   ; ┼
ACS_DIAMOND     = '`'   ; ◆
ACS_CKBOARD     = 'a'   ; ▒

; -----------------------------------------------------------------------------
; Screen dimensions
; -----------------------------------------------------------------------------
TUI_COLS    = 80
TUI_ROWS    = 24
TUI_LAST_COL = TUI_COLS - 1     ; 79
TUI_LAST_ROW = TUI_ROWS - 1     ; 23

; -----------------------------------------------------------------------------
; Key codes returned by tui_getch
; -----------------------------------------------------------------------------
KEY_UP      = $80
KEY_DOWN    = $81
KEY_LEFT    = $82
KEY_RIGHT   = $83
KEY_HOME    = $84
KEY_END     = $85
KEY_PGUP    = $86
KEY_PGDN    = $87
KEY_F1      = $88
KEY_F2      = $89
KEY_F3      = $8A
KEY_F4      = $8B
KEY_F5      = $8C
KEY_F6      = $8D
KEY_F7      = $8E
KEY_F8      = $8F
KEY_INS     = $90
KEY_DEL     = $91
KEY_ENTER   = $0D
KEY_ESC     = $1B
KEY_BS      = $08
KEY_TAB     = $09

; -----------------------------------------------------------------------------
; Public routine entry points  (resolved by linker / tui.asm)
; Declare as .import in your source if building as separate object.
; -----------------------------------------------------------------------------

; Core init / cleanup
;   tui_init       — initialise terminal, clear screen, hide cursor
;   tui_exit       — restore terminal, show cursor, return to monitor

; Cursor positioning
;   tui_gotoxy     — move cursor: TUI_COL→col, TUI_ROW→row
;   tui_home       — cursor to 0,0
;   tui_cursor_on  — show hardware cursor
;   tui_cursor_off — hide hardware cursor

; Output
;   tui_putch      — print char in A at current cursor, advance col
;   tui_putch_acs  — print VT100 ACS char (box drawing)
;   tui_puts       — print NUL-string pointed to by PTR_LO:PTR_HI
;   tui_puth       — print A as two uppercase hex digits
;   tui_putdec     — print A as decimal (0–255, leading-space padded to 3)
;   tui_newline    — CR+LF

; Screen operations
;   tui_clear      — clear entire screen (ANSI ED2)
;   tui_clreol     — clear from cursor to end of line
;   tui_clreos     — clear from cursor to end of screen
;   tui_scroll_up  — scroll viewport up one line

; Attributes / color
;   tui_set_attr   — apply TUI_ATTR to terminal (emit SGR sequences)
;   tui_attr_reset — reset all attributes to normal

; Box drawing
;   tui_box        — draw single-line box
;               in: SCRATCH0=x, SCRATCH1=y, SCRATCH2=w, SCRATCH3=h
;   tui_box_double — draw double-line box (same args)
;   tui_hline      — draw horizontal line
;               in: TUI_COL, TUI_ROW = start; SCRATCH0 = length
;   tui_vline      — draw vertical line
;               in: TUI_COL, TUI_ROW = start; SCRATCH0 = length

; Window / panel helpers
;   tui_fill_rect  — fill rectangle with char
;               in: SCRATCH0=x,SCRATCH1=y,SCRATCH2=w,SCRATCH3=h, A=fill char
;   tui_title_bar  — draw top status bar (row 0) with string PTR_LO:PTR_HI
;   tui_status_bar — draw bottom status bar (row 23) with string PTR_LO:PTR_HI

; Input
;   tui_getch      — read one key, returns raw char or KEY_* constant in A
;   tui_getline    — line editor: PTR_LO:PTR_HI=buffer, SCRATCH0=maxlen
;               returns: buffer filled, length in A
