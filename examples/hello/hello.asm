; =============================================================================
; hello.asm  —  Hello World for SYM-1
; Demonstrates: basic TUI init, title bar, centered text, status bar, exit
; =============================================================================

        .include "sym1.inc"
        .include "macros.inc"
        .include "tui.inc"

        .import tui_init, tui_exit, tui_gotoxy, tui_puts
        .import tui_title_bar, tui_status_bar, tui_getch, tui_box
        .import tui_set_attr, tui_attr_reset, tui_cursor_off

        .segment "STARTUP"

; Program entry point at $0500
        jsr  tui_init           ; Clear screen, setup terminal

        ; --- Title bar ---
        LOAD_PTR msg_title
        jsr  tui_title_bar

        ; --- Draw a centered box ---
        lda  #TUI_BORDER_ATTR
        sta  TUI_ATTR
        jsr  tui_set_attr
        BOX  20, 8, 40, 8       ; x=20, y=8, w=40, h=8

        ; --- Print hello message inside box ---
        jsr  tui_attr_reset
        lda  #TUI_HIGHLIGHT
        sta  TUI_ATTR
        jsr  tui_set_attr

        lda  #30                ; col = center of box
        sta  TUI_COL
        lda  #11
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR msg_hello
        jsr  tui_puts

        lda  #30
        sta  TUI_COL
        lda  #12
        sta  TUI_ROW
        jsr  tui_gotoxy
        jsr  tui_attr_reset
        LOAD_PTR msg_sub
        jsr  tui_puts

        lda  #24
        sta  TUI_COL
        lda  #14
        sta  TUI_ROW
        jsr  tui_gotoxy
        LOAD_PTR msg_version
        jsr  tui_puts

        ; --- Status bar ---
        LOAD_PTR msg_status
        jsr  tui_status_bar

        ; --- Wait for any keypress, then exit ---
        jsr  tui_getch
        jsr  tui_exit           ; Restore terminal, jump to MONITR

; -----------------------------------------------------------------------------
; String data
; -----------------------------------------------------------------------------
        .segment "RODATA"
msg_title:
        .byte " SYM-1 Framework — Hello World ", 0

msg_hello:
        .byte "Hello, World!", 0

msg_sub:
        .byte "SYM-1  6502  Assembly", 0

msg_version:
        .byte "SYM-1 Framework v1.0  |  4K RAM", 0

msg_status:
        .byte " Press any key to exit to monitor...", 0
