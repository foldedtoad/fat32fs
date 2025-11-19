;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
.include "hwconfig.inc"

.export via_init

via_init:
  lda #%11111111          ; Set all pins on port B to output
  sta DDRA
  lda #PORTB_OUTPUTPINS   ; Set various pins on port A to output
  sta DDRA
  rts
