; For ATMega328P Only
; Tested on MicrochipStudio 
; Import on other ASM files with:
;	.include "delay.asm"


;   Considerando que o processador opera em 16MHz,
;   são executados 16 milhões de ciclos por segundo.
;   Assim, cada milissegundo exige 16000 ciclos.
;   
;   Com velocidade de 16MHz:
;        Ciclos:       Milissegundos:
;        16.000.000 -> 1000
;         1.600.000 -> 100
;          160.000  -> 10
;           16.000  -> 1
;
;   A rotina cria um atraso temporal variável, dependendo
;   do valor armazenado em R16 quando é chamada.
;   
;   O atraso temporal pode variar de 10 a 2550 milissegundos,
;   uma vez que o registrador R16 tem 8 bits de largura, e 
;   comporta de 0 a 255 apenas. 
;
;   A quantidade de tempo em milissegundos (T) do atraso é igual ao valor em R16 vezes 10
;       T = (R16) * 10
;
;   A quantidade de ciclos consumidos (C) é igual ao valor em R16 vezes 160.000
;       C = (R16) * 160000
;
;   A relação entre T e C segue:
;       T = C / 16000
;       C = T * 16000
;       C / T = 16000
;
;   +-------------+------------+-----------+-------------+
;   | Input (R16) | Tempo (ms) | Tempo (s) | Ciclos      |
;   +-------------+------------+-----------+-------------+
;   |           1 |         10 |      0.01 |    ~160.000 |
;   |           5 |         50 |      0.05 |    ~800.000 |
;   |          10 |        100 |      0.10 |  ~1.600.000 |
;   |          50 |        500 |      0.50 |  ~8.000.000 |
;   |         100 |       1000 |      1.00 | ~16.000.000 |
;   |         255 |       2550 |      2.55 | ~40.800.000 |
;   +-------------+------------+-----------+-------------+
;
;   Aviso:
;       O volume de ciclos consumidos não é um múltiplo exato de 160000.
;       Desvio temporal:    +0.00025ms por cada 10 ms (160000 ciclos)
;       Desvio em ciclos:   +4 por cada 10 ms (160000 ciclos)
;
variable_delay:
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
    dec r16
    brne delay10ms__init
    ret

