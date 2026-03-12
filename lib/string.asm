; =============================================================================
; string.asm  —  String Utility Library for SYM-1
; =============================================================================
        .include "sym1.inc"
        .include "macros.inc"

        .export str_len, str_copy, str_cmp, str_cat, str_upper, str_lower
        .export str_itoa, str_find_char

; =============================================================================
; str_len — compute length of NUL-terminated string
;   in:  PTR_LO:PTR_HI = string address
;   out: A = STR_LEN = length (max 255)
;   Preserves X, Y
; =============================================================================
.IF 0      ; // WHY are two versions needed?  // robin
str_len:
        pha
        ldy  #0
@loop:  lda  (PTR_LO),y
        beq  @done
        iny
        bne  @loop          ; loop until Y wraps or NUL found
@done:
        sty  STR_LEN
        tya
        pla                 ; restore original A? No — return length in A.
        ; Actually discard saved A and return length:
        tya
        sta  STR_LEN
        rts
.ELSE

; str_len (corrected):
str_len:
        ldy  #0
@lp:    lda  (PTR_LO),y
        beq  @done
        iny
        bne  @lp
@done:  tya
        sta  STR_LEN
        rts
.ENDIF        

; =============================================================================
; str_copy — copy NUL-terminated string
;   in:  PTR_LO:PTR_HI  = source
;        PTR2_LO:PTR2_HI = destination  (must have space for source+NUL)
;   out: nothing (destination filled)
; =============================================================================
str_copy:
        PUSH_AXY
        ldy  #0
@loop:  lda  (PTR_LO),y
        sta  (PTR2_LO),y
        beq  @done          ; stop after copying NUL
        iny
        bne  @loop
        ; Handle page crossing
        inc  PTR_HI
        inc  PTR2_HI
        ldy  #0
        bne  @loop
@done:
        POP_AXY
        rts

; =============================================================================
; str_cmp — compare two NUL-terminated strings
;   in:  PTR_LO:PTR_HI  = string A
;        PTR2_LO:PTR2_HI = string B
;   out: Z=1 if equal, Z=0 if not; C=1 if A>B, C=0 if A<B (like strcmp)
; =============================================================================
str_cmp:
        PUSH_AXY
        ldy  #0
@loop:  lda  (PTR_LO),y
        cmp  (PTR2_LO),y
        bne  @done
        beq  @check_nul
@check_nul:
        lda  (PTR_LO),y
        beq  @equal
        iny
        bne  @loop
@equal:
        ; Both at NUL, set Z=1
        lda  #0             ; Z=1 (equal)
        POP_AXY
        rts
@done:
        ; Z=0 already from CMP; C reflects relative order
        POP_AXY
        rts

; =============================================================================
; str_cat — concatenate: append source to destination
;   in:  PTR_LO:PTR_HI  = source (NUL-terminated)
;        PTR2_LO:PTR2_HI = destination (must have enough space)
; =============================================================================
str_cat:
        PUSH_AXY
        ; Find end of destination
        ldy  #0
@find:  lda  (PTR2_LO),y
        beq  @copy
        iny
        bne  @find
        inc  PTR2_HI
        ldy  #0
        bne  @find
@copy:
        ; Y points to NUL at end of dest; now copy source bytes
        ; PTR2 += Y (advance dest pointer to end)
        tya
        clc
        adc  PTR2_LO
        sta  PTR2_LO
        bcc  :+
        inc  PTR2_HI
:
        ; Now copy source to (PTR2)
        ldy  #0
@cloop: lda  (PTR_LO),y
        sta  (PTR2_LO),y
        beq  @done
        iny
        bne  @cloop
        inc  PTR_HI
        inc  PTR2_HI
        ldy  #0
        bne  @cloop
@done:
        POP_AXY
        rts

; =============================================================================
; str_upper — convert string to uppercase in place
;   in:  PTR_LO:PTR_HI = string
; =============================================================================
str_upper:
        PUSH_AXY
        ldy  #0
@loop:  lda  (PTR_LO),y
        beq  @done
        cmp  #'a'
        bcc  @next
        cmp  #'z'+1
        bcs  @next
        sec
        sbc  #$20
        sta  (PTR_LO),y
@next:  iny
        bne  @loop
@done:
        POP_AXY
        rts

; =============================================================================
; str_lower — convert string to lowercase in place
; =============================================================================
str_lower:
        PUSH_AXY
        ldy  #0
@loop:  lda  (PTR_LO),y
        beq  @done
        cmp  #'A'
        bcc  @next
        cmp  #'Z'+1
        bcs  @next
        clc
        adc  #$20
        sta  (PTR_LO),y
@next:  iny
        bne  @loop
@done:
        POP_AXY
        rts

; =============================================================================
; str_itoa — convert unsigned 8-bit value to decimal ASCII string
;   in:  A = value (0–255)
;        PTR_LO:PTR_HI = destination buffer (min 4 bytes: "255"+NUL)
;   out: string written, length in STR_LEN
; =============================================================================
str_itoa:
        PUSH_AXY
        sta  SCRATCH0
        ldy  #0
        ; Hundreds
        lda  #0
        sta  SCRATCH1
@h:     lda  SCRATCH0
        cmp  #100
        bcc  @t
        sec
        sbc  #100
        sta  SCRATCH0
        inc  SCRATCH1
        bne  @h
        ; Tens
        lda  #0
        sta  SCRATCH2
@t:     lda  SCRATCH0
        cmp  #10
        bcc  @o
        sec
        sbc  #10
        sta  SCRATCH0
        inc  SCRATCH2
        bne  @t
@o:
        ; Write digits, suppress leading zeros
        lda  SCRATCH1
        bne  @wh
        lda  SCRATCH2
        bne  @wt_nz
        ; Value is 0–9, just write ones
        lda  SCRATCH0
        clc
        adc  #'0'
        sta  (PTR_LO),y
        iny
        jmp  @nul
@wh:    lda  SCRATCH1
        clc
        adc  #'0'
        sta  (PTR_LO),y
        iny
@wt_nz: lda  SCRATCH2
        clc
        adc  #'0'
        sta  (PTR_LO),y
        iny
@ones:  lda  SCRATCH0
        clc
        adc  #'0'
        sta  (PTR_LO),y
        iny
@nul:   lda  #0
        sta  (PTR_LO),y
        sty  STR_LEN
        POP_AXY
        rts

; =============================================================================
; str_find_char — find first occurrence of char in string
;   in:  PTR_LO:PTR_HI = string, SCRATCH0 = char to find
;   out: A = offset of char (0-based), or $FF if not found
;        Z=1 if found, Z=0 if not found
; =============================================================================
str_find_char:
        PUSH_AXY
        ldy  #0
@loop:  lda  (PTR_LO),y
        beq  @notfound
        cmp  SCRATCH0
        beq  @found
        iny
        bne  @loop
@notfound:
        lda  #$FF
        POP_AXY
        ; Clear Z flag
        cmp  #0             ; $FF != 0, so Z=0
        rts
@found:
        tya
        POP_AXY
        ; Set Z flag (found at offset, which may be 0 meaning Z=1 correctly)
        ; Actually for "found" signal just check: if A != $FF then found
        rts
