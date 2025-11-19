;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
  ;.org $e000

.include "sym1.inc"
.include "sym1_ext.inc"
.include "zp_memory.inc"

;-----------------------------------------------------------------------------
; imports/exports
;-----------------------------------------------------------------------------

.import fat32_init, fat32_file_read, fat32_finddirent
.import fat32_openroot, fat32_opendirent
.import via_init
.import sd_init

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
.segment "DATA"

buffer = $400

subdirname:
  .asciiz "SUBFOLDR   "
filename:
  .asciiz "DEEPFILETXT"

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
.segment "CODE"

reset:
.if 0
    ldx #$ff
    txs
.endif

    ; Print banner
    ldx #<msg_banner
    ldy #>msg_banner
    jsr print_msg

    ; Initialise
    jsr via_init
    
    ldx #<msg_sd_init
    ldy #>msg_sd_init
    jsr print_msg

    jsr sd_init

    ldx #<msg_fs_init
    ldy #>msg_fs_init
    jsr print_msg

    jsr fat32_init
    bcc @initsuccess
   
    ; Error during FAT32 initialization
    ldx #<msg_fail
    ldy #>msg_fail
    jsr print_msg
    jsr OBCRLF
    jmp loop
  
@initsuccess:

    ldx #<msg_ok
    ldy #>msg_ok
    jsr print_msg

    ; Open root directory
    ldx #<msg_openroot
    ldy #>msg_openroot
    jsr print_msg

    jsr fat32_openroot
    
    ; Find subdirectory by name
    ldx #<msg_find_dir
    ldy #>msg_find_dir
    jsr print_msg
    ldx #<subdirname
    ldy #>subdirname
    jsr print_msg
    jsr CRLF

    ldx #<subdirname
    ldy #>subdirname
    jsr fat32_finddirent
    bcc @foundsubdir

    ; Subdirectory not found
    ldx #<msg_fail
    ldy #>msg_fail
    jsr print_msg
    jmp loop
    
@foundsubdir:

    ; Open subdirectory
    jsr fat32_opendirent

    ; Find file by name
    ldx #<msg_find_file
    ldy #>msg_find_file
    jsr print_msg
    ldx #<filename
    ldy #>filename
    jsr print_msg
    jsr CRLF

    ldx #<filename
    ldy #>filename
    jsr fat32_finddirent
    bcc @foundfile

    ; File not found
    ldx #<msg_fail
    ldy #>msg_fail
    jsr print_msg   
    jmp loop

@foundfile:
 
    ; Open file
    jsr fat32_opendirent
    
    ; Read file contents into buffer
    lda #<buffer
    sta fat32_address+0
    lda #>buffer
    sta fat32_address+1
    
    jsr fat32_file_read
    
    ; Dump data to LCD
    jsr CRLF
    jsr CRLF
    jsr CRLF

    ldy #0
@printloop:
    lda buffer,y
    jsr OUTCHR

    iny

    cpy #16
    bne @not16
    jsr CRLF
@not16:

    cpy #32
    bne @printloop

    ; loop forever
loop:
    jmp loop

;-----------------------------------------------------------------------------
; print_msg - Print null-terminated string
; Inputs: X/Y = pointer to string (lo/hi)
;-----------------------------------------------------------------------------
print_msg:
        stx zp_prt_msg_lo
        sty zp_prt_msg_hi
        ldy #$00
@loop:
        lda (zp_prt_msg_lo),y
        beq @done
        jsr OUTCHR
        iny
        bne @loop
@done:
        rts    

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
.if 0
    .org $fffc
    .word reset
    .word $0000
.endif

;-----------------------------------------------------------------------------
; Messages
;-----------------------------------------------------------------------------
.segment "RODATA"

msg_banner:
        .byte "SYM-1 FAT32 File System Test", 13, 10, 0
msg_sd_init:
        .byte "Initialize SD card...", 0
msg_card_type:
        .byte "Card type: ", 0        
msg_fs_init:
        .byte "Initialize File System card...", 0
msg_openroot:
        .byte "Open Root", 13, 10, 0  
msg_find_dir:
        .byte "Find Directory Entry: ", 0
msg_find_file:
        .byte "Find File: ", 0             
msg_ok:
        .byte "OK", 13, 10, 0
msg_fail:
        .byte "FAILED - Error: ", 0

