;
; sdcard_app.s - Example program using SD card
; Demonstrates initialization, reading, and writing blocks
; Assemble with: ca65 sdcard_example.s

.include "sym1.inc"
.include "sym1_ext.inc"
.include "zp_memory.inc"

.import fat32_workspace, fat32_readbuffer
.import print_msg

.export HexDump

.segment "CODE"

;-----------------------------------------------------------------------------
;  hd_offset
;-----------------------------------------------------------------------------
hd_offset:   
        lda #'0'
        jsr OUTCHR
        lda #'x'
        jsr OUTCHR
        lda zp_hd_addr_hi
        jsr OUTBYT
        lda zp_hd_addr_lo       
        jsr OUTBYT
        lda #' '
        jsr OUTCHR
        rts

;-----------------------------------------------------------------------------
;  HexDump
;  HD_ADDR_LO/HD_ADDR_HI are scratch areas.
;  fat32_workspace contains the area to be dumped.
;-----------------------------------------------------------------------------
HexDump:
        lda #$00
        sta zp_hd_addr_lo
        sta zp_hd_addr_hi
        jsr hd_offset

        ldx #$00
@loop_1:
        lda fat32_readbuffer,x
        jsr OUTBYT
        lda #' '
        jsr OUTCHR
        inx
        txa
        and #15       ; 16 chars output, then a newline
        bne @skip_1
        jsr CRLF
        lda zp_hd_addr_lo
        adc #16
        sta zp_hd_addr_lo
        lda #$00
        cmp zp_hd_addr_lo
        beq @skip_3
        jsr hd_offset
@skip_1:
        cpx #$00
        bne @loop_1
@skip_3:  
.if 0   ; do not print last 256 bytes.
        inc zp_hd_addr_hi
        jsr hd_offset
        ldx #$00
@loop_2:
        lda fat32_readbuffer+256,x
        jsr OUTBYT
        lda #' '
        jsr OUTCHR
        inx
        txa
        and #15       ; 16 chars output, then a newline
        bne @skip_2
        lda zp_hd_addr_lo
        adc #16
        jsr CRLF
        sta zp_hd_addr_lo
        lda #$00
        cmp zp_hd_addr_lo
        beq @skip_4
        jsr hd_offset
@skip_2:
        cpx #$00
        bne @loop_2
@skip_4:

.endif
        rts
