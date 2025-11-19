;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------

PORTB = $AC00
PORTA = $AC01
DDRB  = $AC02
DDRA  = $AC03

SD_SCK  = %00000001  ; PB0 - Serial Clock
SD_MOSI = %00000010  ; PB1 - Master Out Slave In
SD_MISO = %00000100  ; PB2 - Master In Slave In
SD_CS   = %00001000  ; PB3 - Chip Select 0

PORTB_OUTPUTPINS = SD_CS | SD_SCK | SD_MOSI
