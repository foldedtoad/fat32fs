; FAT32/SD interface library
;
.include "sym1.inc"
.include "sym1_ext.inc"
.include "zp_memory.inc"

;-----------------------------------------------------------------------------
; imports/exports
;-----------------------------------------------------------------------------
.import sd_init, sd_readsector
.import fat32_workspace
.import HexDump
.import print_msg

.export fat32_init, fat32_file_read, fat32_finddirent
.export fat32_openroot, fat32_opendirent
.export fat32_readbuffer, fat32_file_size

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
.segment "DATA"

fat32_readbuffer = fat32_workspace
fat32_filenamepointer   = fat32_bytesremaining  ; only used when searching for a file

FSTYPE_FAT32 = 12

;-----------------------------------------------------------------------------
; Initialize the module - read the MBR etc, find the partition,
; and set up the variables ready for navigating the filesystem
;-----------------------------------------------------------------------------
.segment "CODE"

fat32_init:

  ; Read the MBR and extract pertinent information

  ; Sector 0
  lda #0
  sta zp_sd_currentsector+0
  sta zp_sd_currentsector+1
  sta zp_sd_currentsector+2
  sta zp_sd_currentsector+3

  ; Target buffer
  lda #<fat32_readbuffer
  sta zp_sd_address+0
  lda #>fat32_readbuffer
  sta zp_sd_address+1
  
  ; Do the read
  jsr sd_readsector

.if 0
  ldx #<msg_mbr
  ldy #>msg_mbr
  jsr print_msg
  jsr HexDump
.endif

  ; Check some things
  lda fat32_readbuffer+510 ; Boot sector signature 55
  cmp #$55
  bne @fail
  lda fat32_readbuffer+511 ; Boot sector signature AA
  cmp #$AA
  bne @fail

  ; Find a FAT32 partition
  ldx #0
  lda fat32_readbuffer+$1c2,x
  cmp #FSTYPE_FAT32
  beq @foundpart
  ldx #16
  lda fat32_readbuffer+$1c2,x
  cmp #FSTYPE_FAT32
  beq @foundpart
  ldx #32
  lda fat32_readbuffer+$1c2,x
  cmp #FSTYPE_FAT32
  beq @foundpart
  ldx #48
  lda fat32_readbuffer+$1c2,x
  cmp #FSTYPE_FAT32
  beq @foundpart

@fail:
  lda #3
  sta zp_errorcode
  jmp @error

@foundpart:

  ; Read the FAT32 BPB
  lda fat32_readbuffer+$1c6,x
  sta zp_sd_currentsector+0
  lda fat32_readbuffer+$1c7,x
  sta zp_sd_currentsector+1
  lda fat32_readbuffer+$1c8,x
  sta zp_sd_currentsector+2
  lda fat32_readbuffer+$1c9,x
  sta zp_sd_currentsector+3

  jsr sd_readsector

.if 0
  ldx #<msg_fat
  ldy #>msg_fat
  jsr print_msg
  jsr HexDump
.endif

  ; Check some things
  lda fat32_readbuffer+510 ; BPB sector signature 55
  cmp #$55
  bne @fail
  lda fat32_readbuffer+511 ; BPB sector signature AA
  cmp #$AA
  bne @fail

  lda fat32_readbuffer+17 ; RootEntCnt should be 0 for FAT32
  ora fat32_readbuffer+18
  bne @fail

  lda fat32_readbuffer+19 ; TotSec16 should be 0 for FAT32
  ora fat32_readbuffer+20
  bne @fail

  ; Check bytes per filesystem sector, it should be 512 for any SD card that supports FAT32
  lda fat32_readbuffer+11 ; low byte should be zero
  bne @fail
  lda fat32_readbuffer+12 ; high byte is 2 (512), 4, 8, or 16
  cmp #2
  bne @fail

  ; Calculate the starting sector of the FAT
  clc
  lda zp_sd_currentsector+0
  adc fat32_readbuffer+14    ; reserved sectors lo
  sta fat32_fatstart+0
  sta fat32_datastart+0
  lda zp_sd_currentsector+1
  adc fat32_readbuffer+15    ; reserved sectors hi
  sta fat32_fatstart+1
  sta fat32_datastart+1
  lda zp_sd_currentsector+2
  adc #0
  sta fat32_fatstart+2
  sta fat32_datastart+2
  lda zp_sd_currentsector+3
  adc #0
  sta fat32_fatstart+3
  sta fat32_datastart+3

  ; Calculate the starting sector of the data area
  ldx fat32_readbuffer+16   ; number of FATs
@skipfatsloop:
  clc
  lda fat32_datastart+0
  adc fat32_readbuffer+36 ; fatsize 0
  sta fat32_datastart+0
  lda fat32_datastart+1
  adc fat32_readbuffer+37 ; fatsize 1
  sta fat32_datastart+1
  lda fat32_datastart+2
  adc fat32_readbuffer+38 ; fatsize 2
  sta fat32_datastart+2
  lda fat32_datastart+3
  adc fat32_readbuffer+39 ; fatsize 3
  sta fat32_datastart+3
  dex
  bne @skipfatsloop

  ; Sectors-per-cluster is a power of two from 1 to 128
  lda fat32_readbuffer+13
  sta fat32_sectorspercluster

  ; Remember the root cluster
  lda fat32_readbuffer+44
  sta fat32_rootcluster+0
  lda fat32_readbuffer+45
  sta fat32_rootcluster+1
  lda fat32_readbuffer+46
  sta fat32_rootcluster+2
  lda fat32_readbuffer+47
  sta fat32_rootcluster+3

  clc
  rts

@error:
  sec
  rts

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
fat32_seekcluster:
  ; Gets ready to read fat32_nextcluster, and advances it according to the FAT
  
  ; FAT sector = (cluster*4) / 512 = (cluster*2) / 256
  lda fat32_nextcluster
  asl
  lda fat32_nextcluster+1
  rol
  sta zp_sd_currentsector
  lda fat32_nextcluster+2
  rol
  sta zp_sd_currentsector+1
  lda fat32_nextcluster+3
  rol
  sta zp_sd_currentsector+2
  ; note: cluster numbers never have the top bit set, so no carry can occur

  ; Add FAT starting sector
  lda zp_sd_currentsector+0
  adc fat32_fatstart
  sta zp_sd_currentsector+0
  lda zp_sd_currentsector+1
  adc fat32_fatstart+1
  sta zp_sd_currentsector+1
  lda zp_sd_currentsector+2
  adc fat32_fatstart+2
  sta zp_sd_currentsector+2
  lda #0
  adc fat32_fatstart+3
  sta zp_sd_currentsector+3

  ; Target buffer
  lda #<fat32_readbuffer
  sta zp_sd_address+0
  lda #>fat32_readbuffer
  sta zp_sd_address+1

  jsr print_sector_addr
  
  ; Read the sector from the FAT
  jsr sd_readsector

.if 0
  ldx #<msg_sector
  ldy #>msg_sector
  jsr print_msg
  jsr HexDump
.endif

  ; Before using this FAT data, set currentsector ready to read the cluster itself
  ; We need to multiply the cluster number minus two by the number of sectors per 
  ; cluster, then add the data region start sector

  ; Subtract two from cluster number
  sec
  lda fat32_nextcluster
  sbc #2
  sta zp_sd_currentsector
  lda fat32_nextcluster+1
  sbc #0
  sta zp_sd_currentsector+1
  lda fat32_nextcluster+2
  sbc #0
  sta zp_sd_currentsector+2
  lda fat32_nextcluster+3
  sbc #0
  sta zp_sd_currentsector+3
  
  ; Multiply by sectors-per-cluster which is a power of two between 1 and 128
  lda fat32_sectorspercluster
@spcshiftloop:
  lsr
  bcs @spcshiftloopdone
  asl zp_sd_currentsector
  rol zp_sd_currentsector+1
  rol zp_sd_currentsector+2
  rol zp_sd_currentsector+3
  jmp @spcshiftloop
@spcshiftloopdone:

  ; Add the data region start sector
  clc
  lda zp_sd_currentsector+0
  adc fat32_datastart+0
  sta zp_sd_currentsector
  lda zp_sd_currentsector+1
  adc fat32_datastart+1
  sta zp_sd_currentsector+1
  lda zp_sd_currentsector+2
  adc fat32_datastart+2
  sta zp_sd_currentsector+2
  lda zp_sd_currentsector+3
  adc fat32_datastart+3
  sta zp_sd_currentsector+3

  ; Thats now ready for later code to read this sector in - tell it how many consecutive
  ; sectors it can now read
  lda fat32_sectorspercluster
  sta fat32_pendingsectors

  ; Now go back to looking up the next cluster in the chain
  ; Find the offset to this clusters entry in the FAT sector we loaded earlier

  ; Offset = (cluster*4) & 511 = (cluster & 127) * 4
  lda fat32_nextcluster
  and #$7f
  asl
  asl
  tay ; Y = low byte of offset

  ; Add the potentially carried bit to the high byte of the address
  lda zp_sd_address+1
  adc #0
  sta zp_sd_address+1

  ; Copy out the next cluster in the chain for later use
  lda (zp_sd_address),y
  sta fat32_nextcluster
  iny
  lda (zp_sd_address),y
  sta fat32_nextcluster+1
  iny
  lda (zp_sd_address),y
  sta fat32_nextcluster+2
  iny
  lda (zp_sd_address),y
  and #$0f
  sta fat32_nextcluster+3

  ; See if its the end of the chain
  ora #$f0
  and fat32_nextcluster+2
  and fat32_nextcluster+1
  cmp #$ff
  bne @notendofchain
  lda fat32_nextcluster+0
  cmp #$f8
  bcc @notendofchain

  ; Its the end of the chain, set the top bits so that we can tell this later on
  sta fat32_nextcluster+3
@notendofchain:

  rts

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
fat32_readnextsector:
  ; Reads the next sector from a cluster chain into the buffer at fat32_address.
  ;
  ; Advances the current sector ready for the next read and looks up the next cluster
  ; in the chain when necessary.
  ;
  ; On return, carry is clear if data was read, or set if the cluster chain has ended.

  ; Maybe there are pending sectors in the current cluster
  lda fat32_pendingsectors
  bne @readsector

  ; No pending sectors, check for end of cluster chain
  lda fat32_nextcluster+3
  bmi @endofchain

  ; Prepare to read the next cluster
  jsr fat32_seekcluster

@readsector:
  dec fat32_pendingsectors

  ; Set up target address  
  lda fat32_address+0
  sta zp_sd_address+0
  lda fat32_address+1
  sta zp_sd_address+1

  jsr print_sector_addr

  ; Read the sector
  jsr sd_readsector

.if 0
  ldx #<msg_sector2
  ldy #>msg_sector2
  jsr print_msg
  jsr HexDump
.endif

  ; Advance to next sector
  inc zp_sd_currentsector+0
  bne @sectorincrementdone
  inc zp_sd_currentsector+1
  bne @sectorincrementdone
  inc zp_sd_currentsector+2
  bne @sectorincrementdone
  inc zp_sd_currentsector+3
@sectorincrementdone:

  ; Success - clear carry and return
  clc
  rts

@endofchain:
  ; End of chain - set carry and return
  sec
  rts

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
fat32_openroot:
  ; Prepare to read the root directory

  lda fat32_rootcluster+0
  sta fat32_nextcluster+0
  lda fat32_rootcluster+1
  sta fat32_nextcluster+1
  lda fat32_rootcluster+2
  sta fat32_nextcluster+2
  lda fat32_rootcluster+3
  sta fat32_nextcluster+3

  jsr fat32_seekcluster

  ; Set the pointer to a large value so we always read a sector the first time through
  lda #$ff
  sta zp_sd_address+1

  rts

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
fat32_opendirent:
  ; Prepare to read from a file or directory based on a dirent
  ;
  ; Point zp_sd_address at the dirent

  ; Remember file size in bytes remaining
  ldy #28
  lda (zp_sd_address),y
  sta fat32_bytesremaining
  iny
  lda (zp_sd_address),y
  sta fat32_bytesremaining+1
  iny
  lda (zp_sd_address),y
  sta fat32_bytesremaining+2
  iny
  lda (zp_sd_address),y
  sta fat32_bytesremaining+3

  ; Seek to first cluster
  ldy #26
  lda (zp_sd_address),y
  sta fat32_nextcluster
  iny
  lda (zp_sd_address),y
  sta fat32_nextcluster+1
  ldy #20
  lda (zp_sd_address),y
  sta fat32_nextcluster+2
  iny
  lda (zp_sd_address),y
  sta fat32_nextcluster+3

  jsr fat32_seekcluster

  ; Set the pointer to a large value so we always read a sector the first time through
  lda #$ff
  sta zp_sd_address+1

  rts

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
fat32_readdirent:
  ; Read a directory entry from the open directory
  ;
  ; On exit the carry is set if there were no more directory entries.
  ;
  ; Otherwise, A is set to the files attribute byte and
  ; zp_sd_address points at the returned directory entry.
  ; LFNs and empty entries are ignored automatically.

  ; Increment pointer by 32 to point to next entry
  clc
  lda zp_sd_address+0
  adc #32
  sta zp_sd_address+0
  lda zp_sd_address+1
  adc #0
  sta zp_sd_address+1

  ; If its not at the end of the buffer, we have data already
  cmp #>(fat32_readbuffer+$200)
  bcc @gotdata

  ; Read another sector
  lda #<fat32_readbuffer
  sta fat32_address+0
  lda #>fat32_readbuffer
  sta fat32_address+1

  jsr fat32_readnextsector
  bcc @gotdata

@endofdirectory:
  sec
  rts

@gotdata:
  ; Check first character
  ldy #0
  lda (zp_sd_address),y

  ; End of directory => abort
  beq @endofdirectory

  ; Empty entry => start again
  cmp #$e5
  beq fat32_readdirent

  ; Check attributes
  ldy #11
  lda (zp_sd_address),y
  and #$3f
  cmp #$0f ; LFN => start again
  beq fat32_readdirent

  ; Yield this result
  clc
  rts

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
fat32_finddirent:
  ; Finds a particular directory entry.  X,Y point to the 11-character filename to seek.
  ; The directory should already be open for iteration.

  ; Form ZP pointer to users filename
  stx fat32_filenamepointer+0
  sty fat32_filenamepointer+1
  
  ; Iterate until name is found or end of directory
@direntloop:
  jsr fat32_readdirent
  ldy #10
  bcc @comparenameloop
  rts ; with carry set

@comparenameloop:
  lda (zp_sd_address),y
  cmp (fat32_filenamepointer),y
  bne @direntloop ; no match
  dey
  bpl @comparenameloop

  ; Found it
  clc
  rts

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
fat32_file_readbyte:
  ; Read a byte from an open file
  ;
  ; The byte is returned in A with C clear; or if end-of-file was reached, C is set instead

  sec

  ; Is there any data to read at all?
  lda fat32_bytesremaining+0
  ora fat32_bytesremaining+1
  ora fat32_bytesremaining+2
  ora fat32_bytesremaining+3
  beq @rts

  ; Decrement the remaining byte count
  lda fat32_bytesremaining+0
  sbc #1
  sta fat32_bytesremaining+0
  lda fat32_bytesremaining+1
  sbc #0
  sta fat32_bytesremaining+1
  lda fat32_bytesremaining+2
  sbc #0
  sta fat32_bytesremaining+2
  lda fat32_bytesremaining+3
  sbc #0
  sta fat32_bytesremaining+3
  
  ; Need to read a new sector?
  lda zp_sd_address+1
  cmp #>(fat32_readbuffer+$200)
  bcc @gotdata

  ; Read another sector
  lda #<fat32_readbuffer
  sta fat32_address+0
  lda #>fat32_readbuffer
  sta fat32_address+1

  jsr fat32_readnextsector
  bcs @rts                    ; this shouldnt happen

@gotdata:
  ldy #0
  lda (zp_sd_address),y

  inc zp_sd_address+0
  bne @rts
  inc zp_sd_address+1
  bne @rts
  inc zp_sd_address+2
  bne @rts
  inc zp_sd_address+3

@rts:
  rts

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------
fat32_file_read:
  ; Read a whole file into memory.  Its assumed the file has just been opened 
  ; and no data has been read yet.
  ;
  ; Also we read whole sectors, so data in the target region beyond the end of the 
  ; file may get overwritten, up to the next 512-byte boundary.
  ;
  ; And we dont properly support 64k+ files, as its unnecessary complication given
  ; the 6502s small address space

  ; Save filesize for use by user-layer
  lda fat32_bytesremaining+0
  sta fat32_file_size+0
  lda fat32_bytesremaining+1
  sta fat32_file_size+1
  lda fat32_bytesremaining+2
  sta fat32_file_size+2
  lda fat32_bytesremaining+3
  sta fat32_file_size+3

  ; Round the size up to the next whole sector
  lda fat32_bytesremaining+0
  cmp #1                      ; set carry if bottom 8 bits not zero
  lda fat32_bytesremaining+1
  adc #0                      ; add carry, if any
  lsr                         ; divide by 2
  adc #0                      ; round up

  ; No data?
  beq @done

  ; Store sector count - not a byte count any more
  sta fat32_bytesremaining

  ; Read entire sectors to the user-supplied buffer
@wholesectorreadloop:
  ; Read a sector to fat32_address
  jsr fat32_readnextsector

  ; Advance fat32_address by 512 bytes
  lda fat32_address+1
  adc #2                      ; carry already clear
  sta fat32_address+1

  ldx fat32_bytesremaining    ; note - actually loads sectors remaining
  dex
  stx fat32_bytesremaining    ; note - actually stores sectors remaining

  bne @wholesectorreadloop

@done:
  rts

;-----------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------
print_sector_addr:
    jsr CRLF
    lda #'L'
    jsr OUTCHR
    lda #'B'
    jsr OUTCHR    
    lda #'A'
    jsr OUTCHR    
    lda #':'
    jsr OUTCHR
.if 0   ; exclude upper 4 hex digits
    lda zp_sd_currentsector+3
    jsr OUTBYT
    lda zp_sd_currentsector+2
    jsr OUTBYT 
.endif
    lda zp_sd_currentsector+1
    jsr OUTBYT
    lda zp_sd_currentsector+0
    jsr OBCRLF
    rts

;-----------------------------------------------------------------------------
; Messages
;-----------------------------------------------------------------------------
.segment "RODATA"

.if 0
msg_mbr:
        .byte "MBR", 13, 10, 0
msg_fat:
        .byte "FAT", 13, 10, 0   
.endif

msg_sector:
        .byte 13, 10, "Sector - seekcluster", 13, 10, 0 
msg_sector2:
        .byte 13, 10, "Sector2 - readnextsector", 13, 10, 0         
