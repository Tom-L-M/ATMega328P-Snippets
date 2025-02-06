;
; Projeto_1_EA869.asm
;
; Elabore um programa em linguagem Assembly para o ATmega328P que compute o ou-exclusivo
; (XOR) entre todos os pares de bits adjacentes no registrador r16. Para que possamos gerar um byte
; completo, considere que o bit mais significativo do resultado seja obtido pelo XOR entre a flag de
; carry e o bit mais significativo do registrador r16 (r7).
; O programa deve, então, permitir a visualização do resultado de duas maneiras:
; > Cada bit produzido por um XOR – do mais significativo para o menos significativo – é
; gravado em um byte da memória SRAM a partir do endereço 0x0100.
; > Cada bit 𝑒𝑖 do registrador r19 será equivalente ao resultado do ou-exclusivo entre os bits 𝑖 e
; 𝑖 + 1 do registrador r16



;; ---------------- INFO ----------------

;  +--------------------------------------------------------------------------+
;  |                                  TESTES                                  |
;  +---------------+-----------------------+-----------------------+----------+
;  |  Descri��o    |  Input em R16         |  Output em R19        |  Status  |
;  +---------------+-----------------------+-----------------------+----------+
;  |  M�nimo (0)   |  0x00 (0b_0000_0000)  |  0x00 (0b_0000_0000)  |  OK      |
;  |  M�nimo (1)   |  0x01 (0b_0000_0001)  |  0x01 (0b_0000_0001)  |  OK      |
;  |  M�ximo       |  0xFF (0b_1111_1111)  |  0x80 (0b_1000_0000)  |  OK      |
;  |  High Nibble  |  0xF0 (0b_1111_0000)  |  0x88 (0b_1000_1000)  |  OK      |
;  |  Low Nibble   |  0x0F (0b_0000_1111)  |  0x08 (0b_0000_1000)  |  OK      |
;  |  Random 1     |  0xF1 (0b_1111_0001)  |  0x89 (0b_1000_1001)  |  OK      |
;  |  Random 2     |  0xAA (0b_1010_1010)  |  0xFF (0b_1111_1111)  |  OK      |
;  |  Random 3     |  0xB2 (0b_1011_0010)  |  0xEB (0b_1110_1011)  |  OK      |
;  |  Random 4     |  0x07 (0b_0000_0111)  |  0x04 (0b_0000_0100)  |  OK      |
;  +---------------+-----------------------+-----------------------+----------+



;; --------------- CONFIG ---------------

; Defina aqui o n�mero inicial a usar
.SET NUMBER = 0xF1



;; --------------- C�DIGO ---------------
.CSEG


; Rotina para encerrar o programa
stop: break


; Rotina principal
start:
	
	; Inicializa R16 -> Numero a ser analizado
	;   R16 = $NUMBER
	ldi r16,NUMBER

	; Inicializa R17 -> Placeholder 1 para o XOR
	;   R17 = 0
	ldi r17,0

	; Inicializa R18 -> Placeholder 2 para o XOR
	;   R18 = 0
	ldi r18,0

	; Inicializa R19 -> Armazenamento do resultado
	;   R19 = 0
	ldi r19,0
	
	; Inicializa R21 -> Contador do loop (8..0)
	;   R21 = 8
	ldi r21,8

	; Inicializa R22 -> �rea de swap
	;   R22 = 0
	ldi r22,0

	; Para escrever na mem�ria, precisamos gravar o endere�o em r26 (low) e r27 (high)
	; Como vamos escrever entre 0x0100 e 0x0107, r27 permanece igual sempre e s� r26 muda
	;
	; Registrador especial X (para escrita de IO e mem�ria):
	;  +-----+-----+
	;  | R27 | R26 |
	;  +-----+-----+
	;
	; Inicializa R27 (high(X)) -> Primeira parte do endere�o de armazenamento
	;   R27 = 1
	ldi r27,0b_0000_0001 ; high(0x0100)
	;
	; Inicializa R26 (low(X)) -> Segunda parte do endere�o de armazenamento
	;   R26 = 0
	ldi r26,0b_0000_0000 ; low(0x0100)


; Rotina do loop principal do programa
; A cada vez que � executada, um par de bits � movido
; e utilizado para o XOR, e o resultado � armazenado
loop:
	; Executa LSL em R16 para e7 ir para o Carry
	;   R16 << 0 (left shift)
	lsl r16

	; Se Carry for 1, move 1 para R17
	;   If (Flags.Carry == 1) -> R17 = 1
	brcs _enable_r17

	; Se Carry for 0, move 0 para R17
	;   If (Flags.Carry == 0) -> R17 = 0
	brcc _disable_r17

	; Micro-Fun��o 1: Define R17 como 1
	;   R17 = 1
	_enable_r17:
	  ldi r17,0x1
	
	; Pula para a fun��o _run_xor, para n�o executar a fun��o 
	; _disable_r17, caso _enable_r17 j� tenha sido executada
	;   goto _run_xor
	jmp _run_xor

	; Micro-Fun��o 2: Define R17 como 0 
	;   R17 = 0
	_disable_r17:
	  ldi r17,0x0

	; Micro-Fun��o 3: Copia os valores, e executa o XOR
	_run_xor:
	  ; Move R17 para R22 (�rea de Swap), para salvar o resultado anterior
	  ;   R22 = (R17)
	  mov r22,r17
	  ; Executa XOR entre R17 e R18 -> Grava o resultado em R22
	  ;   R22 = XOR(R22, R18)
	  eor r22,r18
	
	; Incrementa R19 de acordo com R22
	; Dessa forma, se R22 for 1, R19 � incrementado  
	; da forma correta, caso contr�rio nada acontece.
	;   R19 = (R19) + (R22)
	add r19,r22

	; Grava R22 em SRAM[0x0100 + N] (e incrementa N a cada execu��o)
	;   SRAM[0x0100+N] = (R22);
	;   N += 1
	st X+,r22

	; Decrementa o contador
	;   R21 -= 1
	dec r21
	
	; Se o contador tiver zerado, termina o programa
	;   If (R21 == 0) -> break
	  cpi r21,0x0
	  breq stop
	; Se o contador ainda for maior que zero, reinicia o loop
	;   If (R21 > 0) -> goto loop
	  ; Move R17 para R18
	  ;   R18 = (R17)
	  mov r18,r17
	  ; Limpa R17
	  ;   R17 = 0
	  ldi r17,0x00
	  ; Executa LSL em R19, para mover para a direita para a pr�xima grava��o
	  ;   R19 << 0
	  lsl r19
	  ; Reinicia o loop
	  ;   goto loop
	  jmp loop