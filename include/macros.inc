; =============================================================================
; macros.inc  —  Convenience Macros for SYM-1 / ca65
; =============================================================================

; -----------------------------------------------------------------------------
; PUSH / POP  — save/restore registers through the stack
; -----------------------------------------------------------------------------
.macro  PUSH_AXY
        pha
        txa
        pha
        tya
        pha
.endmacro

.macro  POP_AXY
        pla
        tay
        pla
        tax
        pla
.endmacro

.macro  PUSH_AX
        pha
        txa
        pha
.endmacro

.macro  POP_AX
        pla
        tax
        pla
.endmacro

; -----------------------------------------------------------------------------
; 16-bit load into zero-page pointer
;   LOAD_PTR  addr       — PTR_LO:PTR_HI = addr
;   LOAD_PTR2 addr       — PTR2_LO:PTR2_HI = addr
; -----------------------------------------------------------------------------
.macro  LOAD_PTR  addr
        lda  #<(addr)
        sta  PTR_LO
        lda  #>(addr)
        sta  PTR_HI
.endmacro

.macro  LOAD_PTR2  addr
        lda  #<(addr)
        sta  PTR2_LO
        lda  #>(addr)
        sta  PTR2_HI
.endmacro

; -----------------------------------------------------------------------------
; CALL_MON  — call a Supermonitor entry point, preserving X and Y
; (Supermonitor may clobber X/Y on some calls — use where needed)
; -----------------------------------------------------------------------------
.macro  CALL_MON  entry
        jsr  entry
.endmacro

; -----------------------------------------------------------------------------
; PRINT_CHAR  c  — print an immediate character constant
; -----------------------------------------------------------------------------
.macro  PRINT_CHAR  c
        lda  #c
        jsr  MONOUT
.endmacro

; -----------------------------------------------------------------------------
; PRINT_STR  label  — print a NUL-terminated string via Supermonitor MONPRT
;   label must be a .byte sequence ending in $00
; -----------------------------------------------------------------------------
.macro  PRINT_STR  label
        ldx  #<(label)
        ldy  #>(label)
        jsr  MONPRT
.endmacro

; -----------------------------------------------------------------------------
; SET_CURSOR  col, row  — position TUI cursor (immediate values)
; -----------------------------------------------------------------------------
.macro  SET_CURSOR  col, row
        lda  #col
        sta  TUI_COL
        lda  #row
        sta  TUI_ROW
        jsr  tui_gotoxy
.endmacro

; -----------------------------------------------------------------------------
; BOX  x, y, w, h  — draw a single-line box at immediate coords
; -----------------------------------------------------------------------------
.macro  BOX  x_axis, y_axis, width, height
        lda  #x_axis
        sta  SCRATCH0
        lda  #y_axis
        sta  SCRATCH1
        lda  #width
        sta  SCRATCH2
        lda  #height
        sta  SCRATCH3
        jsr  tui_box
.endmacro

; -----------------------------------------------------------------------------
; NOP_DELAY  n  — burn n*2 cycles (very rough, use RIOT timer for precision)
; -----------------------------------------------------------------------------
.macro  NOP_DELAY  n
        .repeat n
        nop
        .endrepeat
.endmacro

; -----------------------------------------------------------------------------
; BEQ_OR_BNE shorthand for skip-if-zero / skip-if-nonzero one instruction
; -----------------------------------------------------------------------------
.macro  SKIP_IF_ZERO
        bne  *+4
.endmacro

.macro  SKIP_IF_NZ
        beq  *+4
.endmacro

; -----------------------------------------------------------------------------
; 16-bit increment of a zero-page word
; -----------------------------------------------------------------------------
.macro  INC16  zp_lo
        inc  zp_lo
        bne  :+
        inc  zp_lo+1
:
.endmacro

; -----------------------------------------------------------------------------
; 16-bit decrement
; -----------------------------------------------------------------------------
.macro  DEC16  zp_lo
        lda  zp_lo
        bne  :+
        dec  zp_lo+1
:       dec  zp_lo
.endmacro
