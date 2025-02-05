; For ATMega328P Only
; Tested on MicrochipStudio 
; Import on other ASM files with:
;	.include "macros.asm"



; Macro for moving a value from memory to register
 ;
 ;   LD_MR RN,$ADDR     ; RN <- MEM[$ADDR]      ; Moves value from memory at $ADDR to register RN
 ;
.MACRO LD_MR
    push R26            ; stack <- (R26)        ; Push R26 (low(X)) to stack (to preserve old value)
    push R27            ; stack <- (R27)        ; Push R27 (high(X)) to stack (to preserve old value)
    ldi  R27, high(@1)  ; R27 <- high($ADDR)    ; Load target address high byte in high(X)
    ldi  R26, low(@1)   ; R26 <- low($ADDR)     ; Load target address low byte in low(X)
    ld   @0, X          ; R25 <- mem[X]         ; Copy from memory at $ADDR to R25
    pop  R27            ; R27 <- stack          ; Restore old high(X) value from stack
    pop  R26            ; R26 <- stack          ; Restore old low(X) value from stack
.ENDMACRO



; Macro for moving a value from register to memory 
 ;
 ;   ST_RM $ADDR,RN     ; MEM[$ADDR] <- (RN)    ; Moves value from register RN to memory at $ADDR
 ;
.MACRO ST_RM
    push R26            ; stack <- (R26)        ; Push R26 (low(X)) to stack (to preserve old value)
    push R27            ; stack <- (R27)        ; Push R27 (high(X)) to stack (to preserve old value)
    ldi  R27, high(@0)  ; R27 <- high($ADDR)    ; Load target address high byte in high(X)
    ldi  R26, low(@0)   ; R26 <- low($ADDR)     ; Load target address low byte in low(X)
    st   X, @1          ; mem[X] <- (R25)       ; Copy from R25 to memory at $ADDR
    pop  R27            ; R27 <- (stack)        ; Restore old high(X) value from stack
    pop  R26            ; R26 <- (stack)        ; Restore old low(X) value from stack
.ENDMACRO



; Macro for moving an immediate value to memory
 ;
 ;   ST_IM $ADDR,$IMM   ; MEM[$ADDR] <- $IMM    ; Moves immediate value $IMM to memory at $ADDR
 ;
.MACRO ST_IM
    push R25            ; stack <- (R25)        ; Push R25 (temporary register) to stack (to preserve old value)
    push R26            ; stack <- (R26)        ; Push R26 (low(X)) to stack (to preserve old value)
    push R27            ; stack <- (R27)        ; Push R27 (high(X)) to stack (to preserve old value)
    ldi  R27, high(@0)  ; R27 <- high($ADDR)    ; Load target address high byte in high(X)
    ldi  R26, low(@0)   ; R26 <- low($ADDR)     ; Load target address low byte in low(X)
    ldi  R25, @1        ; R25 <- $IMM           ; Move $IMM to R25 to place in memory
    st   X, R25         ; mem[X] <- (R25)       ; Copy from R25 to memory at $ADDR
    pop  R27            ; R27 <- (stack)        ; Restore old high(X) value from stack
    pop  R26            ; R26 <- (stack)        ; Restore old low(X) value from stack
    pop  R25            ; R25 <- (stack)        ; Restore old R25 value from stack
.ENDMACRO



; Macro for swapping two registers
 ;
 ;   SWAP_RR RN,RM      ; (RM) <-> (RN)         ; Swaps values from registers RN and RM.
 ;
.MACRO SWAP_RR
    push @0             ; stack <- (RN)         ; Moves value from RN to stack
    mov  @0, @1         ; RN <- (RM)            ; Moves value from RM to RN
    pop  @1             ; RM <- (stack)         ; Moves value from stack to RM
.ENDMACRO



; Macro for loading an immediate address into X
 ;
 ;   LD_IX $ADDR      ; X <- $ADDR            ; Loads $ADDR into X (R26 and R27)
 ;
.MACRO LD_IX
    ldi R27, high(@0)   ; R27 <- high($ADDR)    ; Load target address high byte in high(X)
    ldi R26, low(@0)    ; R26 <- low($ADDR)     ; Load target address low byte in low(X)
.ENDMACRO



; Macro for loading an immediate address into Y
 ;
 ;   LD_IY $ADDR      ; Y <- $ADDR            ; Loads $ADDR into Y (R28 and R29)
 ;
.MACRO LD_IY
    ldi R29, high(@0)   ; R29 <- high($ADDR)    ; Load target address high byte in high(Y)
    ldi R28, low(@0)    ; R28 <- low($ADDR)     ; Load target address low byte in low(Y)
.ENDMACRO



; Macro for loading an immediate address into Z
 ;
 ;   LD_IZ $ADDR      ; Z <- $ADDR            ; Loads $ADDR into Y (R30 and R31)
 ;
.MACRO LD_IZ
    ldi R31, high(@0)  ; R31 <- high($ADDR)     ; Load target address high byte in high(Z)
    ldi R30, low(@0)   ; R30 <- low($ADDR)      ; Load target address low byte in low(Z)
.ENDMACRO



; UNTESTED!!!
;
; Macro for loading an immediate address into either X, Y or Z
 ;
 ;   LD_IA RCd, $ADDR     ; RCd <- $ADDR             ; Loads $ADDR into RCd
 ;                                                     ; (RCd may be either X, Y, or Z)
 ;
.MACRO LD_IA
    .IF @0 == X
        ldi R27, high(@0)   ; R27 <- high($ADDR)     ; Load target address high byte in high(X)
        ldi R26, low(@0)    ; R26 <- low($ADDR)      ; Load target address low byte in low(X)
    .ELIF @0 == Y
        ldi R29, high(@0)   ; R29 <- high($ADDR)     ; Load target address high byte in high(Y)
        ldi R28, low(@0)    ; R28 <- low($ADDR)      ; Load target address low byte in low(Y)
    .ELIF @0 == Z
        ldi R31, high(@0)   ; R31 <- high($ADDR)     ; Load target address high byte in high(Z)
        ldi R30, low(@0)    ; R30 <- low($ADDR)      ; Load target address low byte in low(Z)
    .ELSE
    .ENDIF
.ENDMACRO



; UNTESTED!!!
;
; Macro to divide two 8-bit integers
 ;
 ;  DIV Rd, Rr          ; Rd <- (Rd) / (Rr)     ; Divides Rd for Rr (Rd/Rr) and places quocient
 ;                                              ; Remainder is ignored. To get remainder, use the MOD macro
 ;
 ; Remember: division of A from B (A/B) can be implemented with addition
 ; and subtraction, by counting how many times we can subtract B from A.
 ;
.MACRO DIV
    push R25            ; stack <- (R25)        ; Saves R25's value with stack
    ldi R25, 0          ; R25 <- 0              ; Load zero in R25 to use it as counter
    DIV__LOOP:
        inc R25         ; R25++                 ; Increment counter
        sub @0, @1      ; Rd -= (Rr)            ; Subract Rr from Rd
        brsh DIV__LOOP  ; If Rd >= Rr goto LOOP ; Go back to loop start to subtract once more if possible
    mov R25, @0         ; Rd = (R25)            ; Move result from R25 to the desired Rd register
    pop R25             ; R25 <- stack          ; Restore R25's value from stack
.ENDMACRO



; UNTESTED!!!
;
; Macro to divide two 8-bit integers
 ;
 ;  MOD Rd, Rr          ; Rd <- (Rd) % (Rr)     ; Divides Rd for Rr (Rd/Rr) and places remainder in Rd
 ;                                              ; Quotient is ignored. To get quotient, use the DIV macro
 ;
 ; Remember: division of A from B (A/B) can be implemented with addition
 ; and subtraction, by counting how many times we can subtract B from A.
 ;
.MACRO MOD
    MOD__LOOP:
        sub @0, @1      ; Rd -= (Rr)            ; Subract Rr from Rd
        brsh MOD__LOOP  ; If Rd >= Rr goto LOOP ; Go back to loop start to subtract once more if possible
.ENDMACRO
