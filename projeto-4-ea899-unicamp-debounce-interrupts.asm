;
; Objetivo do projeto:
; 
; Elaborar um programa em linguagem Assembly para o ATmega328P que controle a frequência
; com que um LED pisca, de acordo com o pressionamento de um botão externo.
;
; Comportamento do sistema:
;
; O sistema deve manter o LED piscando continuamente, sendo que o intervalo de tempo em que o
; LED permanece aceso/apagado pode ser alterado por meio de um botão.
; Inicialmente, o LED permanece aceso durante 1 segundo e, em seguida, fica apagado por mais 1
; segundo. Cada vez que o botão é pressionado, este tempo é reduzido pela metade, de modo que o
; LED passa a piscar mais rapidamente. A figura abaixo resume o comportamento desejado na
; forma de uma máquina de estados finitos.
;
; LED:
; Por simplicidade, vamos utilizar neste projeto o LED que já vem incorporado à própria placa
; Arduino UNO. É possível realizar o acionamento deste LED através do bit 5 da PORTA B (PB5). 
;
; Botão:
;
; O tratamento do botão será feito através da interrupção externa INT0. Assim, quando o botão for
; pressionado, deve ser gerada uma solicitação de interrupção no pino 2 da PORTA D (por borda de
; subida).
;
; Montagem:
;
; É necessário utilizar um circuito de debounce para eliminar as oscilações no sinal gerado pelo
; botão. Uma possível solução envolve um Schmitt trigger inversor, junto a um circuito RC. 
;
;

.cseg

; Interrupt Vector Table
.org 0x0000 ; RESET interrupt vector
    rjmp RESET
.org 0x0002 ; INT0 external interrupt vector
    rjmp INT0_Handler
;

; Interrupt Handlers
.org 0x0034
RESET: 
    ; Configure stack pointer
        ldi r16, high(RAMEND)
        out SPH, r16
        ldi r16, low(RAMEND)
        out SPL, r16
    ; Configure I/O pins
        sbi DDRB, PB5	; (PB5 = 0x05) ; PB5 set as OUTPUT Pin (LED)
		cbi DDRD, PD2   ; (PD2 = 0x02) ; PD2 from DDRD set as INPUT Pin (button)
    ; Configure interrupts
        ; Configura a interrupção externa INT0
        ; Seta os dois bits menos significativos - a INT0 será ativada na borda de subida do pino 2 da porta D
        ;; A variável pré-definida EICRA está relacionada a um endereço de I/O mapeada em memória
        ;; Por isso, devemos usar as instruções lds/sts (load/store) para lidar com este endereço
        lds r16, EICRA
        ori r16, 0x03
        sts EICRA, r16
        ; Habilita a interrupção INT0
        ;; A variável pré-definida EIMSK está relacionada a um endereço de I/O isolado (não mapeado em memória)
        ;; Por isso, devemos usar as instruções in/out para lidar com este endereço
        in r16, EIMSK
        ori r16, 0x01
        out EIMSK, r16

    ; End configuration and enable interrupts globally
        sei
    ; Jump to program setup section
        jmp setup


; INT0 external interrupt handler
INT0_Handler: 
    cli ; # NEW
    cpi r16, 25               ; If interval is 0.25s:
    breq set_prescale_100     ;  toggle to 1s
    cpi r16, 100              ; If interval is 1s:
    breq set_prescale_050     ;  toggle to 0.5s
    cpi r16, 50               ; If interval is 0.5s:
    breq set_prescale_025     ;  toggle to 0.25s
    INT0_Handler_end:
        sei ; # NEW
        reti
    set_prescale_100:
        ldi r16, 100
        rjmp INT0_Handler_end
    set_prescale_050:
        ldi r16, 50
        rjmp INT0_Handler_end
    set_prescale_025:
        ldi r16, 25
        rjmp INT0_Handler_end


; Main program and Setup section
.org 0x0200
    setup:
        ; R16 holds the prescale interval of the led (always either 100, 50, or 25)
        ldi r16, 100
        ; R17 is a temporary register, to copy R16 into, and avoid LED frequency mutations during a delay
        ; instead, if pressed during the delay, the changes will only be applied in the next LED ON/OFF tick
        ldi r17, 0
    main:
        call LED_OFF
        call AWAIT
        call LED_ON
        call AWAIT
        nop
        rjmp main
;

; General Functions
.org 0x0300
    ; Turn LED ON
    LED_ON:
        sbi PORTB, 5 ; TURN LED ON
        ret
    
    ; Turn LED OFF
    LED_OFF:
        cbi PORTB, 5 ; TURN LED OFF
        ret

    ; Creates a variable delay (R16 * 10ms)
    AWAIT:
        mov r17, r16
        delay10ms__init:
            push r24 
            push r25
            ldi r25, 0x3E ; 62
            ldi r24, 0x9C ; 156
            delay10ms__loop:
                subi r25, 0x01
                sbci r24, 0x00
                brne delay10ms__loop
            pop r25
            pop r24
        dec r17
        brne delay10ms__init
        ret
;