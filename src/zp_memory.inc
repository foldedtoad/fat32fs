;
; memory.inc - Zeropage Memory Layout for the SYM-1
;

zp_sd_address       = $40   ; 2 bytes
zp_sd_currentsector = $42   ; 4 bytes
zp_fat32_variables  = $46   ; 24 bytes

fat32_fatstart          = zp_fat32_variables + $00  ; 4 bytes
fat32_datastart         = zp_fat32_variables + $04  ; 4 bytes
fat32_rootcluster       = zp_fat32_variables + $08  ; 4 bytes
fat32_sectorspercluster = zp_fat32_variables + $0C  ; 1 byte
fat32_pendingsectors    = zp_fat32_variables + $0D  ; 1 byte
fat32_address           = zp_fat32_variables + $0E  ; 2 bytes
fat32_nextcluster       = zp_fat32_variables + $10  ; 4 bytes
fat32_bytesremaining    = zp_fat32_variables + $14  ; 4 bytes

zp_prt_msg_lo      = $A0
zp_prt_msg_hi      = $A1

zp_errorcode       = $A2
