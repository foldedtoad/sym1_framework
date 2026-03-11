; =============================================================================
; via.inc  —  6522 VIA (Versatile Interface Adapter) Register Definitions
; =============================================================================

VIA_ORB     = VIA_BASE+$0    ; Output Register B  / Input Register B
VIA_ORA     = VIA_BASE+$1    ; Output Register A  / Input Register A
VIA_DDRB    = VIA_BASE+$2    ; Data Direction Register B (1=output)
VIA_DDRA    = VIA_BASE+$3    ; Data Direction Register A (1=output)
VIA_T1CL    = VIA_BASE+$4    ; Timer 1 Counter Low  (read clears IRQ)
VIA_T1CH    = VIA_BASE+$5    ; Timer 1 Counter High
VIA_T1LL    = VIA_BASE+$6    ; Timer 1 Latch Low
VIA_T1LH    = VIA_BASE+$7    ; Timer 1 Latch High
VIA_T2CL    = VIA_BASE+$8    ; Timer 2 Counter Low  (read clears IRQ)
VIA_T2CH    = VIA_BASE+$9    ; Timer 2 Counter High
VIA_SR      = VIA_BASE+$A    ; Shift Register
VIA_ACR     = VIA_BASE+$B    ; Auxiliary Control Register
VIA_PCR     = VIA_BASE+$C    ; Peripheral Control Register
VIA_IFR     = VIA_BASE+$D    ; Interrupt Flag Register
VIA_IER     = VIA_BASE+$E    ; Interrupt Enable Register
VIA_ORAH    = VIA_BASE+$F    ; ORA without handshake

; IFR / IER bit masks
VIA_IRQ_CA2 = %00000001
VIA_IRQ_CA1 = %00000010
VIA_IRQ_SR  = %00000100
VIA_IRQ_CB2 = %00001000
VIA_IRQ_CB1 = %00010000
VIA_IRQ_T2  = %00100000
VIA_IRQ_T1  = %01000000
VIA_IRQ_ANY = %10000000     ; Set when any enabled IRQ is pending

; ACR bits
VIA_ACR_PA_LATCH  = %00000001
VIA_ACR_PB_LATCH  = %00000010
VIA_ACR_SR_MASK   = %00011100
VIA_ACR_T2_PB6    = %00100000   ; T2 count PB6 pulses
VIA_ACR_T1_CONT   = %01000000   ; T1 continuous mode
VIA_ACR_T1_PB7    = %10000000   ; T1 output on PB7
