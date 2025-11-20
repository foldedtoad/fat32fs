;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------

PORTB = $AC00
PORTA = $AC01
DDRB  = $AC02
DDRA  = $AC03

.if 1
SD_SCK  = %00000001  ; PB0 - Serial Clock
SD_MOSI = %00000010  ; PB1 - Master Out Slave In
SD_MISO = %00000100  ; PB2 - Master In Slave In
SD_CS   = %00001000  ; PB3 - Chip Select 0

.else
SD_SCK_SET  = %00000001  ; PB0 - Serial Clock
SD_MOSI_SET = %00000010  ; PB1 - Master Out Slave In
SD_MISO_SET = %00000100  ; PB2 - Master In Slave In
SD_CS_SET   = %00001000  ; PB3 - Chip Select

SD_SCK_CLR  = %11111110  ; PB0 - Serial Clock
SD_MOSI_CLR = %11111101  ; PB1 - Master Out Slave In
SD_MISO_CLR = %11111011  ; PB2 - Master In Slave In
SD_CS_CLR   = %11110111  ; PB3 - Chip Select
.endif

PORTB_OUTPUTPINS = SD_CS | SD_SCK | SD_MOSI
