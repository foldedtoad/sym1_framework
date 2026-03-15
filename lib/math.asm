; =============================================================================
; math.asm  —  8-bit and 16-bit Math Helpers for SYM-1
; =============================================================================
        .include "sym1.inc"
        .include "macros.inc"

        .export math_add16, math_sub16, math_mul8, math_div8
        .export math_mul16, math_abs, math_min, math_max

; =============================================================================
; math_add16 — 16-bit addition
;   in:  MATH_A_LO:MATH_A_HI + MATH_B_LO:MATH_B_HI
;   out: MATH_R_LO:MATH_R_HI = sum; C = carry out
; =============================================================================
math_add16:
        clc
        lda  MATH_A_LO
        adc  MATH_B_LO
        sta  MATH_R_LO
        lda  MATH_A_HI
        adc  MATH_B_HI
        sta  MATH_R_HI
        rts

; =============================================================================
; math_sub16 — 16-bit subtraction
;   out: MATH_R = MATH_A - MATH_B; C=0 if borrow (A < B)
; =============================================================================
math_sub16:
        sec
        lda  MATH_A_LO
        sbc  MATH_B_LO
        sta  MATH_R_LO
        lda  MATH_A_HI
        sbc  MATH_B_HI
        sta  MATH_R_HI
        rts

; =============================================================================
; math_mul8 — unsigned 8×8 → 16-bit multiply
;   in:  A = multiplicand, SCRATCH0 = multiplier
;   out: MATH_R_LO:MATH_R_HI = product
;   Clobbers: A, SCRATCH0, SCRATCH1
; =============================================================================
math_mul8:
        sta  SCRATCH1           ; save multiplicand
        lda  #0
        sta  MATH_R_LO
        sta  MATH_R_HI
        ldx  #8                 ; 8 bits
@loop:
        lsr  SCRATCH0           ; shift multiplier right, LSB into C
        bcc  @next              ; if LSB was 0, skip add
        clc
        lda  MATH_R_LO
        adc  SCRATCH1
        sta  MATH_R_LO
        lda  MATH_R_HI
        adc  #0
        sta  MATH_R_HI
@next:
        asl  SCRATCH1           ; shift multiplicand left
        dex
        bne  @loop
        rts

; =============================================================================
; math_div8 — unsigned 8÷8 division
;   in:  A = dividend, SCRATCH0 = divisor
;   out: A = quotient, MATH_R_LO = remainder
;   Traps on division by zero (calls tui_exit / MONITR)
; =============================================================================
math_div8:
        sta  SCRATCH1           ; dividend
        lda  SCRATCH0
        beq  @divzero
        lda  #0
        sta  MATH_R_LO          ; remainder = 0
        ldx  #8
@loop:
        asl  SCRATCH1           ; shift dividend MSB into C
        rol  MATH_R_LO          ; shift into remainder
        lda  MATH_R_LO
        cmp  SCRATCH0
        bcc  @next
        sec
        sbc  SCRATCH0
        sta  MATH_R_LO
        inc  SCRATCH1           ; set quotient bit
@next:
        dex
        bne  @loop
        lda  SCRATCH1           ; quotient in A
        rts
@divzero:
        jmp  WARM ; was MONITR             ; trap to monitor

; =============================================================================
; math_mul16 — unsigned 16×8 → 16-bit multiply (truncated)
;   in:  MATH_A_LO:MATH_A_HI = 16-bit value, SCRATCH0 = 8-bit multiplier
;   out: MATH_R_LO:MATH_R_HI = lower 16 bits of product
; =============================================================================
math_mul16:
        lda  #0
        sta  MATH_R_LO
        sta  MATH_R_HI
        ldx  #8
@loop:
        lsr  SCRATCH0
        bcc  @next
        clc
        lda  MATH_R_LO
        adc  MATH_A_LO
        sta  MATH_R_LO
        lda  MATH_R_HI
        adc  MATH_A_HI
        sta  MATH_R_HI
@next:
        asl  MATH_A_LO
        rol  MATH_A_HI
        dex
        bne  @loop
        rts

; =============================================================================
; math_abs — absolute value of signed 8-bit number
;   in:  A = signed value
;   out: A = |value|
; =============================================================================
math_abs:
        bpl  @done
        eor  #$FF
        clc
        adc  #1
@done:  rts

; =============================================================================
; math_min — return smaller of two unsigned bytes
;   in:  A = value1, SCRATCH0 = value2
;   out: A = minimum
; =============================================================================
math_min:
        cmp  SCRATCH0
        bcc  @done      ; A < SCRATCH0, A is min
        lda  SCRATCH0
@done:  rts

; =============================================================================
; math_max — return larger of two unsigned bytes
; =============================================================================
math_max:
        cmp  SCRATCH0
        bcs  @done      ; A >= SCRATCH0, A is max
        lda  SCRATCH0
@done:  rts
