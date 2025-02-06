;  Atividade 3 - Unicamp EA869
; 
; Elabore um programa em linguagem Assembly para o ATmega328P que faça a escrita na memória
; EEPROM de bytes extraídos da memória de programa.
; Para pré-alocar alguns bytes na memória de programa, podemos utilizar a seguinte pseudoinstrução 
; (os valores escolhidos são meramente ilustrativos):
;   dados: .db 5, 0xA6,0x83,0xB6,0xDE,0x19
;
; Nesta atividade, vamos explorar o mecanismo de interrupção associado à EEPROM. Assim, em
; vez de permanecer em um laço de espera ocupada, o programa principal será automaticamente
; interrompido quando a memória EEPROM sinalizar que está pronta para uma nova operação.
; Para que tudo funcione adequadamente, será necessário:
; • Fazer a configuração da interrupção relacionada à EEPROM.
; • Seguir o protocolo de acesso para uma operação de escrita na EEPROM (quanto tal
;   operação puder ser realizada);
;
; Quando todos os bytes já tiverem sido armazenados na memória, podemos desligar a interrupção
; referente à EEPROM.
;

.def data = r17        ; Register to hold the data byte to be written to EEPROM
.def addr_l = r18      ; Register to hold the EEPROM address
.def addr_h = r19      ; Register to hold the EEPROM address
.def counter = r20     ; Counter for EEPROM write operations tracker
.equ ee_addr = 0x0000  ; First address to write into in EEPROM

; Interrupt Vector Table
.org 0x0000 ; RESET interrupt vector
    rjmp RESET_Handler
.org 0x002C ; EEPROM_READY interrupt vector
    rjmp EEPROM_READY_Handler

.org 0x0034
    RESET_Handler: ; RESET interrupt handler
        sei                             ; Enable global interrupts
        sbi EECR, EERIE                 ; Enable EEPROM_READY interrupt
        jmp main

    EEPROM_READY_Handler: ; EEPROM_READY interrupt handler
        cpi counter, 0                  ; Check if counter is zero
        ; If counter is zero:
            breq eeprom_ready_end_chain ; End writing and return
        ; If counter is higher than zero:
			dec counter                 ; Decrease counter
            inc addr_l                  ; Point to next address to write
            lpm data, Z+                ; Load next byte to be written in EEPROM
            call eeprom_write_async     ; Call the EEPROM write routine
			reti
        ; End writing chain
        eeprom_ready_end_chain:
			cli							; Disable interrupts
            reti

.org 0x0200
    main:
        ; Preload the "dados" PROGMEM reading address (progmem[dados[0]])
        ldi ZH, high(2*dados)           ; R31 <- high($ADDR)    ; Load target address high byte in HIGH(Z)
        ldi ZL, low(2*dados)            ; R30 <- low($ADDR)     ; Load target address low byte in LOW(Z)
        lpm counter, Z+                 ; Load EEPROM writer counter
        lpm data, Z+                    ; Load first byte to be written in EEPROM
        ldi addr_l, low(ee_addr)        ; Load first EEPROM address low byte
        ldi addr_h, high(ee_addr)       ; Load first EEPROM address high byte

		dec counter						; Adjust counter to be 0-based instead of 1-based

        ; Call the EEPROM writing routine for the first time
        ; (so the next calls will be triggered)
        call eeprom_write_async
        
        ; Main program loop
        loop: jmp loop

.org 0x0300 ; Data storage
    dados: .db 5, 0xA1, 0xB2, 0xC3, 0xD4, 0xE5

.org 0x0310 ; EEPROM (ASYNC) writing function
    ;  R17 (data): data to write
    ;  R18 (addr_l): low part of IO address to write into
    ;  R19 (addr_h): high part of IO address to write into
	eeprom_write_async:
		; Set up address (r18:r17) in address register
        out EEARH, addr_h
        out EEARL, addr_l
		out EEDR, data          ; Write data to Data Register
		sbi EECR, EEMPE         ; Write logical one to EEMPE
		sbi EECR, EEPE          ; Start eeprom write
		ret