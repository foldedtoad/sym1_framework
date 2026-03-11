; =============================================================================
; tui_demo.asm  —  Full TUI Library Demonstration for SYM-1
; =============================================================================
; Demonstrates:
;   - Title & status bars
;   - Multiple bordered panels (windows)
;   - Attribute / color cycling
;   - Keyboard navigation (arrow keys)
;   - Input field (tui_getline)
;   - Hex and decimal display helpers
; =============================================================================

        .include "sym1.inc"
        .include "macros.inc"
        .include "tui.inc"

        .import tui_init, tui_exit, tui_gotoxy, tui_puts, tui_putch
        .import tui_puth, tui_putdec
        .import tui_title_bar, tui_status_bar
        .import tui_box, tui_hline, tui_vline
        .import tui_set_attr, tui_attr_reset
        .import tui_clear, tui_clreol
        .import tui_getch, tui_getline
        .import tui_cursor_on, tui_cursor_off
        .import tui_fill_rect

        .segment "STARTUP"

; =============================================================================
; Main entry
; =============================================================================
main:
        jsr  tui_init

; --- Persistent chrome (redrawn on refresh) ---
@draw_chrome:
        LOAD_PTR str_title
        jsr  tui_title_bar

        ; Draw three panels
        jsr  draw_panel_left
        jsr  draw_panel_right
        jsr  draw_panel_bottom

        ; Populate panels with content
        jsr  fill_left_panel
        jsr  fill_right_panel

        ; Status bar
        LOAD_PTR str_status_main
        jsr  tui_status_bar

; --- Main event loop ---
@loop:
        jsr  tui_getch
        cmp  #'q'
        beq  @quit
        cmp  #'Q'
        beq  @quit
        cmp  #'r'
        beq  @refresh
        cmp  #'i'
        beq  @input_demo
        cmp  #'c'
        beq  @color_demo
        jmp  @show_key

@refresh:
        jsr  tui_clear
        jmp  @draw_chrome

@input_demo:
        jsr  do_input_demo
        jmp  @loop

@color_demo:
        jsr  do_color_demo
        jmp  @loop

@show_key:
        ; Display last key in the right panel
        jsr  show_last_key
        jmp  @loop

@quit:
        jsr  tui_exit           ; never returns

; =============================================================================
; draw_panel_left — left panel: "System Info" (col 0, row 1, w=38, h=15)
; =============================================================================
draw_panel_left:
        PUSH_AXY
        lda  #TUI_BORDER_ATTR
        sta  TUI_ATTR
        jsr  tui_set_attr
        BOX  0, 1, 38, 15

        ; Panel title
        lda  #TUI_TITLE_ATTR
        sta  TUI_ATTR
        jsr  tui_set_attr
        lda  #1
        sta  TUI_COL
        lda  #1
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_panel_sysinfo
        jsr  tui_puts

        jsr  tui_attr_reset
        POP_AXY
        rts

; =============================================================================
; draw_panel_right — right panel: "Key Events" (col 40, row 1, w=40, h=15)
; =============================================================================
draw_panel_right:
        PUSH_AXY
        lda  #TUI_BORDER_ATTR
        sta  TUI_ATTR
        jsr  tui_set_attr
        BOX  40, 1, 40, 15

        lda  #TUI_TITLE_ATTR
        sta  TUI_ATTR
        jsr  tui_set_attr
        lda  #41
        sta  TUI_COL
        lda  #1
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_panel_keys
        jsr  tui_puts

        jsr  tui_attr_reset
        POP_AXY
        rts

; =============================================================================
; draw_panel_bottom — command panel (col 0, row 16, w=80, h=7)
; =============================================================================
draw_panel_bottom:
        PUSH_AXY
        lda  #TUI_BORDER_ATTR
        sta  TUI_ATTR
        jsr  tui_set_attr
        BOX  0, 16, 80, 7

        lda  #TUI_TITLE_ATTR
        sta  TUI_ATTR
        jsr  tui_set_attr
        lda  #1
        sta  TUI_COL
        lda  #16
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_panel_cmd
        jsr  tui_puts

        ; Command key hints
        jsr  tui_attr_reset
        lda  #2
        sta  TUI_COL
        lda  #18
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_hints
        jsr  tui_puts

        POP_AXY
        rts

; =============================================================================
; fill_left_panel — populate the system info panel
; =============================================================================
fill_left_panel:
        PUSH_AXY

        ; Row: CPU
        lda  #2
        sta  TUI_COL
        lda  #3
        sta  TUI_ROW
        jsr  tui_gotoxy
        lda  #TUI_HIGHLIGHT
        sta  TUI_ATTR
        jsr  tui_set_attr
        LOAD_PTR str_lbl_cpu
        jsr  tui_puts
        jsr  tui_attr_reset
        LOAD_PTR str_val_cpu
        jsr  tui_puts

        ; Row: Board
        lda  #2
        sta  TUI_COL
        lda  #4
        sta  TUI_ROW
        jsr  tui_gotoxy
        lda  #TUI_HIGHLIGHT
        sta  TUI_ATTR
        jsr  tui_set_attr
        LOAD_PTR str_lbl_board
        jsr  tui_puts
        jsr  tui_attr_reset
        LOAD_PTR str_val_board
        jsr  tui_puts

        ; Row: RAM
        lda  #2
        sta  TUI_COL
        lda  #5
        sta  TUI_ROW
        jsr  tui_gotoxy
        lda  #TUI_HIGHLIGHT
        sta  TUI_ATTR
        jsr  tui_set_attr
        LOAD_PTR str_lbl_ram
        jsr  tui_puts
        jsr  tui_attr_reset
        LOAD_PTR str_val_ram
        jsr  tui_puts

        ; Row: Monitor
        lda  #2
        sta  TUI_COL
        lda  #6
        sta  TUI_ROW
        jsr  tui_gotoxy
        lda  #TUI_HIGHLIGHT
        sta  TUI_ATTR
        jsr  tui_set_attr
        LOAD_PTR str_lbl_mon
        jsr  tui_puts
        jsr  tui_attr_reset
        LOAD_PTR str_val_mon
        jsr  tui_puts

        ; Row: Serial
        lda  #2
        sta  TUI_COL
        lda  #7
        sta  TUI_ROW
        jsr  tui_gotoxy
        lda  #TUI_HIGHLIGHT
        sta  TUI_ATTR
        jsr  tui_set_attr
        LOAD_PTR str_lbl_ser
        jsr  tui_puts
        jsr  tui_attr_reset
        LOAD_PTR str_val_ser
        jsr  tui_puts

        ; Separator line
        lda  #2
        sta  TUI_COL
        lda  #9
        sta  TUI_ROW
        lda  #TUI_BORDER_ATTR
        sta  TUI_ATTR
        jsr  tui_set_attr
        lda  #34
        sta  SCRATCH0
        jsr  tui_hline

        ; Memory map mini-legend
        jsr  tui_attr_reset
        lda  #2
        sta  TUI_COL
        lda  #10
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_memmap_hdr
        jsr  tui_puts

        lda  #2
        sta  TUI_COL
        lda  #11
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_memmap_1
        jsr  tui_puts

        lda  #2
        sta  TUI_COL
        lda  #12
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_memmap_2
        jsr  tui_puts

        lda  #2
        sta  TUI_COL
        lda  #13
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_memmap_3
        jsr  tui_puts

        lda  #2
        sta  TUI_COL
        lda  #14
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_memmap_4
        jsr  tui_puts

        jsr  tui_attr_reset
        POP_AXY
        rts

; =============================================================================
; fill_right_panel — initial content of key event panel
; =============================================================================
fill_right_panel:
        PUSH_AXY
        lda  #41
        sta  TUI_COL
        lda  #3
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_press_key
        jsr  tui_puts
        POP_AXY
        rts

; =============================================================================
; show_last_key — display key info in right panel
;   A = key code on entry
; =============================================================================
show_last_key:
        sta  SCRATCH0           ; save key
        PUSH_AXY

        lda  #41
        sta  TUI_COL
        lda  #3
        sta  TUI_ROW
        jsr  tui_gotoxy
        jsr  tui_clreol

        LOAD_PTR str_key_dec
        jsr  tui_puts
        lda  SCRATCH0
        jsr  tui_putdec

        lda  #41
        sta  TUI_COL
        lda  #4
        sta  TUI_ROW
        jsr  tui_gotoxy
        jsr  tui_clreol
        LOAD_PTR str_key_hex
        jsr  tui_puts
        lda  SCRATCH0
        jsr  tui_puth

        lda  #41
        sta  TUI_COL
        lda  #5
        sta  TUI_ROW
        jsr  tui_gotoxy
        jsr  tui_clreol
        LOAD_PTR str_key_char
        jsr  tui_puts
        lda  SCRATCH0
        cmp  #$20
        bcc  @not_printable
        cmp  #$7F
        bcs  @not_printable
        jsr  tui_putch
        jmp  @done
@not_printable:
        LOAD_PTR str_non_print
        jsr  tui_puts
@done:
        POP_AXY
        rts

; =============================================================================
; do_input_demo — show an input dialog in the bottom panel
; =============================================================================
do_input_demo:
        PUSH_AXY

        ; Clear bottom panel interior
        lda  #' '
        ; tui_fill_rect SCRATCH0=1,SCRATCH1=17,SCRATCH2=78,SCRATCH3=5
        lda  #1
        sta  SCRATCH0
        lda  #17
        sta  SCRATCH1
        lda  #78
        sta  SCRATCH2
        lda  #5
        sta  SCRATCH3
        lda  #' '
        jsr  tui_fill_rect

        lda  #2
        sta  TUI_COL
        lda  #17
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_input_prompt
        jsr  tui_puts

        ; Input field
        lda  #2
        sta  TUI_COL
        lda  #18
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_input_field_lbl
        jsr  tui_puts

        jsr  tui_cursor_on
        LOAD_PTR input_buf
        lda  #30
        sta  SCRATCH0
        jsr  tui_getline
        sta  SCRATCH1           ; save length
        jsr  tui_cursor_off

        ; Echo result
        lda  #2
        sta  TUI_COL
        lda  #20
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_echo_lbl
        jsr  tui_puts
        LOAD_PTR input_buf
        jsr  tui_puts

        lda  #2
        sta  TUI_COL
        lda  #21
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_len_lbl
        jsr  tui_puts
        lda  SCRATCH1
        jsr  tui_putdec

        ; Wait for key
        jsr  tui_getch

        ; Restore bottom panel
        jsr  draw_panel_bottom

        POP_AXY
        rts

; =============================================================================
; do_color_demo — show all 8×8 attribute combinations in the bottom panel
; =============================================================================
do_color_demo:
        PUSH_AXY

        lda  #1
        sta  SCRATCH0
        lda  #17
        sta  SCRATCH1
        lda  #78
        sta  SCRATCH2
        lda  #5
        sta  SCRATCH3
        lda  #' '
        jsr  tui_fill_rect

        lda  #2
        sta  TUI_COL
        lda  #17
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR str_color_hdr
        jsr  tui_puts

        ; Outer loop: background (0–7)
        lda  #0
        sta  SCRATCH2           ; bg index
@bg:
        lda  #0
        sta  SCRATCH3           ; fg index
@fg:
        ; Build attribute: (bg<<4)|fg
        lda  SCRATCH2
        asl  a
        asl  a
        asl  a
        asl  a
        ora  SCRATCH3
        sta  TUI_ATTR
        jsr  tui_set_attr
        ; Print a two-char sample "FG"
        lda  #'F'
        jsr  tui_putch
        lda  #'G'
        jsr  tui_putch
        lda  #' '
        jsr  tui_putch
        ; Next fg
        inc  SCRATCH3
        lda  SCRATCH3
        cmp  #8
        bcc  @fg
        ; Next bg — newline (move to next display row)
        jsr  tui_attr_reset
        inc  SCRATCH2
        ; Advance row in bottom panel
        lda  SCRATCH2
        clc
        adc  #17
        cmp  #22
        bcs  @color_done
        sta  TUI_ROW
        lda  #2
        sta  TUI_COL
        jsr  tui_gotoxy
        lda  SCRATCH2
        cmp  #8
        bcc  @bg
@color_done:
        jsr  tui_attr_reset
        jsr  tui_getch
        jsr  draw_panel_bottom
        POP_AXY
        rts

; =============================================================================
; BSS — input buffer
; =============================================================================
        .segment "BSS"
input_buf:
        .res 32, 0

; =============================================================================
; String data (RODATA)
; =============================================================================
        .segment "RODATA"

str_title:
        .byte "  SYM-1 TUI Framework Demo  |  Press Q to quit  ", 0

str_status_main:
        .byte " [Q]uit  [R]efresh  [I]nput demo  [C]olor demo  |  Any key: show key code", 0

str_panel_sysinfo:
        .byte "[ System Information ]", 0

str_panel_keys:
        .byte "[ Key Events ]", 0

str_panel_cmd:
        .byte "[ Command / Output ]", 0

str_hints:
        .byte "Q=Quit  R=Refresh  I=Input  C=Colors  Arrow keys=KEY_UP/DOWN/LEFT/RIGHT", 0

str_lbl_cpu:    .byte "CPU   : ", 0
str_val_cpu:    .byte "MOS 6502  @ ~1 MHz", 0
str_lbl_board:  .byte "Board : ", 0
str_val_board:  .byte "SYM-1 Single Board Computer", 0
str_lbl_ram:    .byte "RAM   : ", 0
str_val_ram:    .byte "4096 bytes  ($0000-$0FFF)", 0
str_lbl_mon:    .byte "ROM   : ", 0
str_val_mon:    .byte "Supermonitor V1.1  ($8000)", 0
str_lbl_ser:    .byte "Serial: ", 0
str_val_ser:    .byte "6551 ACIA  9600 8N1  TTL", 0

str_memmap_hdr: .byte "Memory map:", 0
str_memmap_1:   .byte "  $0000 ZP/Stack/Framebuf", 0
str_memmap_2:   .byte "  $0500 User code", 0
str_memmap_3:   .byte "  $0C00 TUI library", 0
str_memmap_4:   .byte "  $8000 Supermonitor (ROM)", 0

str_press_key:  .byte "Press any key...", 0
str_key_dec:    .byte "Decimal : ", 0
str_key_hex:    .byte "Hex     : $", 0
str_key_char:   .byte "Char    : ", 0
str_non_print:  .byte "(non-printable)", 0

str_input_prompt:    .byte "Input Demo — type something and press Enter:", 0
str_input_field_lbl: .byte "> ", 0
str_echo_lbl:        .byte "You typed : ", 0
str_len_lbl:         .byte "Length    : ", 0

str_color_hdr:  .byte "Color Demo — all 64 FG/BG combinations (3 chars each):", 0
