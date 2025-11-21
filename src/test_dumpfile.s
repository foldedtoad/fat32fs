;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
.include "sym1.inc"
.include "sym1_ext.inc"
.include "zp_memory.inc"

;-----------------------------------------------------------------------------
; imports/exports
;-----------------------------------------------------------------------------

.import fat32_init, fat32_file_read, fat32_finddirent
.import fat32_openroot, fat32_opendirent
.import sd_init

.export fat32_workspace, print_msg

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
.segment "DATA"

; 512-byte working buffer (one sector)
fat32_workspace:
        .res 512, $00

buffer:
        .res $400, $00

subdirname:
  .asciiz "SUBFOLDR   "
filename:
  .asciiz "DEEPFILETXT"

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
.segment "CODE"

main:
    ; Print banner
    ldx #<msg_banner
    ldy #>msg_banner
    jsr print_msg

    ; Initialize
    ldx #<msg_sd_init
    ldy #>msg_sd_init
    jsr print_msg

    jsr sd_init
    bcc @sd_init_ok

    ldx #<msg_fail
    ldy #>msg_fail
    jsr print_msg
    jmp @exit
@sd_init_ok:

    ldx #<msg_ok
    ldy #>msg_ok
    jsr print_msg

    ldx #<msg_fs_init
    ldy #>msg_fs_init
    jsr print_msg

    jsr fat32_init
    bcc @fat32_init_ok
   
    ; Error during FAT32 initialization
    ldx #<msg_fail
    ldy #>msg_fail
    jsr print_msg
    jmp @exit
@fat32_init_ok:

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
    jmp @exit
    
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
    jmp @exit

@foundfile:
 
    ; Open file
    ldx #<msg_open_file
    ldy #>msg_open_file
    jsr print_msg

    jsr fat32_opendirent
    
    ; Read file contents into buffer
    lda #<buffer
    sta fat32_address+0
    lda #>buffer
    sta fat32_address+1
    
    ldx #<msg_read_file
    ldy #>msg_read_file
    jsr print_msg

    jsr fat32_file_read
    
    ; Dump data to Console
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

    cpy #48
    bne @printloop

@exit:
    rts

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
; Messages
;-----------------------------------------------------------------------------
.segment "RODATA"

msg_banner:
        .byte "SYM-1 FAT32 File System Test", 13, 10, 0     
msg_sd_init:
        .byte "Initialize SDCard...", 0      
msg_fs_init:
        .byte "Initialize File System...", 0     
msg_openroot:
        .byte "Open Root", 13, 10, 0  
msg_find_dir:
        .byte "Find Directory Entry: ", 0
msg_find_file:
        .byte "Find File: ", 0
msg_open_file:
        .byte "Open File: ", 0 
msg_read_file:
        .byte "Read File: ", 0                     
msg_ok:
        .byte "OK", 13, 10, 0
msg_fail:
        .byte "FAILED ", 0

