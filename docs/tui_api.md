# TUI Library API Reference

The TUI library (`lib/tui.asm`) provides an ncurses-inspired full-screen
terminal interface using **ANSI/VT100 escape sequences** over the SYM-1's
TTL serial connection.  It targets an **80×24** character terminal.

---

## Coordinate System

All coordinates are **0-based**:
- Column 0–79 (left→right)
- Row 0–23 (top→bottom)

Stored in zero-page variables `TUI_COL` ($E0) and `TUI_ROW` ($E1).

---

## Attribute Byte

`TUI_ATTR` ($E2) holds the current color attribute:

```
 7  6  5  4  3  2  1  0
[  BG color  ][  FG color  ]
```

Color indices (0–7): BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE

Build with: `.define TUI_ATTR_BYTE(fg, bg)  ((bg << 4) | fg)`

Pre-built constants: `TUI_NORMAL`, `TUI_REVERSE`, `TUI_HIGHLIGHT`,
`TUI_TITLE_ATTR`, `TUI_STATUS_ATTR`, `TUI_ERROR_ATTR`, `TUI_BORDER_ATTR`

---

## Initialization

### `tui_init`
Initialize terminal: reset attributes, clear screen, hide cursor, zero `TUI_COL`/`TUI_ROW`.
- **Preserves:** A, X, Y
- **Call first** before any other TUI routine.

### `tui_exit`
Restore terminal (show cursor, reset attributes), then **`JMP MONITR`** — does not return.
- Call this to cleanly exit your program.

---

## Cursor Control

### `tui_gotoxy`
Move cursor to (`TUI_COL`, `TUI_ROW`).  Set those ZP variables first.
```asm
lda  #10
sta  TUI_COL
lda  #5
sta  TUI_ROW
jsr  tui_gotoxy
```

### `tui_home`
Move cursor to (0, 0).

### `tui_cursor_on` / `tui_cursor_off`
Show or hide the hardware cursor (VT100 `ESC[?25h/l`).

---

## Output

### `tui_putch`
Print character in **A** at current position, advance `TUI_COL`.

### `tui_putch_acs`
Print a VT100 ACS (box-drawing) character.  Pass the ACS code in A.
Available codes: `ACS_ULCORNER`, `ACS_URCORNER`, `ACS_LLCORNER`, `ACS_LRCORNER`,
`ACS_HLINE`, `ACS_VLINE`, `ACS_LTEE`, `ACS_RTEE`, `ACS_BTEE`, `ACS_TTEE`,
`ACS_PLUS`, `ACS_DIAMOND`, `ACS_CKBOARD`.

### `tui_puts`
Print NUL-terminated string at `PTR_LO:PTR_HI`.
```asm
LOAD_PTR my_string   ; sets PTR_LO/PTR_HI
jsr  tui_puts
```

### `tui_puth`
Print **A** as two uppercase hex digits (e.g. `$FF` → `FF`).

### `tui_putdec`
Print **A** (0–255) as a 3-character right-aligned decimal (e.g. `42` → `" 42"`).

### `tui_newline`
Emit CR+LF, advance `TUI_ROW`, reset `TUI_COL` to 0.

---

## Screen Operations

### `tui_clear`
Clear entire screen (ANSI `ESC[2J`), home cursor.

### `tui_clreol`
Clear from cursor to end of current line.

### `tui_clreos`
Clear from cursor to end of screen.

### `tui_scroll_up`
Scroll viewport up one line (`ESC D`).

---

## Attributes / Color

### `tui_set_attr`
Emit ANSI SGR escape sequence for current `TUI_ATTR`.  Call after changing `TUI_ATTR`.
```asm
lda  #TUI_ERROR_ATTR
sta  TUI_ATTR
jsr  tui_set_attr
```

### `tui_attr_reset`
Reset all attributes to normal, set `TUI_ATTR = TUI_NORMAL`.

---

## Box Drawing

### `tui_box`
Draw a single-line box.
```asm
; Draw box at (x=5, y=3), width=30, height=10
lda  #5   : sta  SCRATCH0   ; x
lda  #3   : sta  SCRATCH1   ; y
lda  #30  : sta  SCRATCH2   ; width
lda  #10  : sta  SCRATCH3   ; height
jsr  tui_box
```
Or use the `BOX x, y, w, h` macro.

### `tui_hline`
Draw horizontal line.  Set `TUI_COL`, `TUI_ROW`, `SCRATCH0` = length.

### `tui_vline`
Draw vertical line.  Set `TUI_COL`, `TUI_ROW`, `SCRATCH0` = length.

---

## Panel Helpers

### `tui_title_bar`
Fill row 0 with `TUI_TITLE_ATTR` and print centered title string from `PTR_LO:PTR_HI`.

### `tui_status_bar`
Fill row 23 with `TUI_STATUS_ATTR` and print left-aligned string from `PTR_LO:PTR_HI`.

### `tui_fill_rect`
Fill a rectangle with a character.
```asm
lda  #x   : sta  SCRATCH0
lda  #y   : sta  SCRATCH1
lda  #w   : sta  SCRATCH2
lda  #h   : sta  SCRATCH3
lda  #' '           ; fill character
jsr  tui_fill_rect
```

---

## Input

### `tui_getch`
Read one keypress.  **Blocks** until a key is available.
- Returns plain ASCII characters as-is.
- Returns `KEY_*` constants for special keys (arrows, F1–F8, etc.).
- Uses the RIOT timer for ESC sequence disambiguation.

### `tui_getline`
Simple line editor.  Echoes input, supports Backspace.
```asm
LOAD_PTR  my_buffer      ; destination buffer
lda  #31                 ; max characters (buffer must be maxlen+1)
sta  SCRATCH0
jsr  tui_cursor_on
jsr  tui_getline         ; blocks until Enter
jsr  tui_cursor_off
; A = length of entered string
; my_buffer now contains NUL-terminated string
```

---

## Memory Cost

| Component       | Approx. Size |
|-----------------|--------------|
| Core + cursor   | ~180 bytes   |
| Output routines | ~140 bytes   |
| Attribute/color | ~80 bytes    |
| Box drawing     | ~200 bytes   |
| Panel helpers   | ~120 bytes   |
| Input (getch)   | ~150 bytes   |
| Input (getline) | ~80 bytes    |
| String constants| ~60 bytes    |
| **Total**       | **~1010 bytes** |

The TUI library fits comfortably in its assigned region ($0C00–$0EFF, 768 bytes reserved),
though some examples may require adjusting the linker config to give it ~1K.
Update `sym1.cfg` to `size = $0400` for the TUI segment if needed.
