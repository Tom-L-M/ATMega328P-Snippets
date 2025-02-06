; eeprom_write:
;     ; Wait for completion of previous write
;     sbic EECR,EEPE
;     rjmp eeprom_write
;     ; Set up address (r18:r17) in address register
;     out EEARH, r18
;     out EEARL, r17
;     ; Write data (r16) to Data Register
;     out EEDR,r16
;     ; Write logical one to EEMPE
;     sbi EECR,EEMPE
;     ; Start eeprom write by setting EEPE
;     sbi EECR,EEPE
;     ret


