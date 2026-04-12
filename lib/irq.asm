; -----------------------------------------------------------------------------
; Description:
;   This program initializes a 6522 VIA located at $AC00.
;   It uses an interrupt-driven approach handle device alerts.
; -----------------------------------------------------------------------------
.include "sym1.inc"
.include "sym1_ext.inc"

; -----------------------------------------------------------------------------
; Imports & Exports
; -----------------------------------------------------------------------------

.export _Interrupts_Init
.import _Interrupt_Callback

; -----------------------------------------------------------------------------
; MEMORY LAYOUT & CONSTANTS
; -----------------------------------------------------------------------------

; SYM-1 Interrupt Vectors (RAM)
IRQ_VEC_LO   = $A678    ; User IRQ Vector Low Byte
IRQ_VEC_HI   = $A679    ; User IRQ Vector High Byte

; VIA Base Address
VIA_BASE     = $AC00

; VIA Register Offsets
VIA_ORB      = VIA_BASE + $00 ; Output Register B
VIA_ORA      = VIA_BASE + $01 ; Output Register A (with handshake)
VIA_DDRB     = VIA_BASE + $02 ; Data Direction Register B
VIA_DDRA     = VIA_BASE + $03 ; Data Direction Register A
VIA_PCR      = VIA_BASE + $0C ; Peripheral Control Register
VIA_IFR      = VIA_BASE + $0D ; Interrupt Flag Register
VIA_IER      = VIA_BASE + $0E ; Interrupt Enable Register

; -----------------------------------------------------------------------------
; CODE SEGMENT
; -----------------------------------------------------------------------------
.segment "CODE"

_Interrupts_Init:

    ; Initialize the VIA
    ; ---------------------

    ; Disable VIA Interrupts initially to configure safely
    lda #IER_DISABLE
    sta VIA_IER

    ; Configure Port A Direction
    ; PA7 is ALERT set to Input
    ; PA6-PA0 are set to Input

    lda #%00000000   ; all inputs
    sta VIA_DDRA        

    ; Configure Peripheral Control Register (PCR)  
    lda VIA_PCR
    ora #PCR_CA1_NAE   ; Negative Active Edge for CA1
    sta VIA_PCR   

    ; Setup Interrupt System
    ; -------------------------

    ; Disable write protection using monitor routine
    jsr Disable_Write_Protect  

    ; Point the SYM-1 User IRQ Vector to our ISR
    lda #<ISR_Handler
    sta UIRQVC+0
    lda #>ISR_Handler
    sta UIRQVC+1

    ; Enable Interrupts on VIA
    lda #(IER_ENABLE + IER_CA1_ENA)
    sta VIA_IER

    ; Enable CPU Interrupts
    cli

    rts

; -----------------------------------------------------------------------------
; INTERRUPT SERVICE ROUTINE (ISR)
; -----------------------------------------------------------------------------
ISR_Handler: 

    lda VIA_IFR         ; Check if this interrupt came from our VIA CA1
    and #IFR_CA1
    beq ExitISR         ; If not CA1, ignore

    lda #IFR_CA1
    sta VIA_IFR         ; Clear Interrupt Flag

    jsr _Interrupt_Callback

ExitISR:
    rti 

; -----------------------------------------------------------------------------
; 
; -----------------------------------------------------------------------------
Disable_Write_Protect:
    pha 
    lda OR3A
    ora #$01       ; allow writing to SYSRAM
    sta OR3A
    lda DDR3A
    ora #$01       ; set as output direction
    sta DDR3A
    pla
    rts

.end               ; End of assembly