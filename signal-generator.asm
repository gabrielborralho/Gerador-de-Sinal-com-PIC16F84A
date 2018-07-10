; Universidade Federal do Maranhão - UFMA
; Centro de Ciências Exatas e Tecnologia - CCET
; Departamento de Engenharia de Eletricidade - DEE
; Introdução à Arquitetura de Computadores - IACOM
; Prof. Dr. Denivaldo Lopes
; Alunos: GABRIEL BORRALHO
;   
; Microcontrolador: PIC16F84A		Clock: 4MHz
;
;   QUESTAO 7:
;   Um sistema hardware/software é baseado no PIC16F84A e deve verificar um sensor A continuamente (utilize Porta A,
;   bit RA1), caso o sensor retorne 1, então deve enviar o valor 0x0C pela porta B, caso contrário 0xC0 pela porta B. O
;   mesmo sistema deve enviar pela porta A, bit RA2, um sinal quadrado com frequência de 24Hz. O clock do PIC16F84A
;   deve ser de 4 MHz.
;
;   * PORTA A (pino RA1) como entrada (push buttom)
;   * PORTA A (pino RA2) como saída (LED)
;   * Configura o timer0 para fazer piscal um LED (PORTA, pino RA2)
;     a cada 41,6ms, ou seja, com uma frequência de 24Hz
;   * Ler o dado de entrada na PORTA (RA1),
;     se (RA!==1), então faz RB1=0x0C senão faz RB1=0xC0.

;--- ARQUIVOS INCLUÍDOS NO PROJETO ---
    #include <p16f84a.inc>

; --- FUSE Bits ---
; Cristal oscilador externo 4MHz, sem watchdog timer, sem power up timer, sem proteção de código
;   __config 0x3FF9
    __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _CP_OFF
 
; --- PAGINAÇÃO DE MEMÓRIA ---
    #define	BANK0	    BCF STATUS, RP0	    ;cria um mnemônico para o banco 0 de memória
    #define	BANK1	    BSF STATUS, RP0	    ;cria um mnemônico para o banco 1 de memória

;LABEL      INSTRUÇÃO   PARAMÊTRO   COMENTÁRIO
            ORG         0x000       ; INÍCIO DO PROGRAMA EM 0x000
            GOTO        START_PROG  ; VAI PARA START_PROG
                                 
; --- SUBROTINA ---
; --- SALVA CONTEXTO DO PIC (W e STATUS) ---	
SUB_INT     ORG         0x004       ; ENDEREÇO DO PROGRAMA EM 0x004
				    ;
				    ;
            MOVWF       H'0C'	    ; 0x0C <- W
            SWAPF       STATUS,W    ; W <- STATUS
            MOVWF       H'0D'	    ; 0x0D <- W
                                    ; FIM SALVA CONTEXTO DO PIC
            BANK0
IF1S        BTFSS       INTCON,T0IF ; TESTA TOIF (Interrupção por Timer0) E SALTA SE "1"
            GOTO        ELSE_IF1S   ;
THEN_IF1S   NOP
IF2S        BTFSS       PORTA,RA2   ; TESTA RA2 E SALTA SE "1"
            GOTO        ELSE_IF2S   ; VAI PARA ELSE_IF2S
THEN_IF2S   BCF         PORTA,RA2   ; RA2 <- 0
            GOTO        END_IF2S
ELSE_IF2S   BSF         PORTA,RA2   ; RA2 <- 1
END_IF2S    NOP
            GOTO        END_IF1S
ELSE_IF1S   NOP
END_IF1S    NOP
                                    ; COLOCAR 0xAF EM TIMER0
            MOVLW       H'AF'       ; W <- 0xAF => H'AF' = D'174' => O led  irá oscilar em 24Hz
            MOVWF       TMR0        ; TMR0 <- W
                                    ;
; --- RESTAURA CONTEXTO DO PIC (W e STATUS) ---
            SWAPF       H'0D',W ;
            MOVWF       STATUS      ; STATUS <- W
            SWAPF       H'0C',F
            SWAPF       H'0C',W
                                    ; FIM RESTAURA CONTEXTO DO PIC
                                    ;
    
            BCF         INTCON,T0IF ; REARMA Timer0
            RETFIE                  ; RETORNA DA SUBROTINA
                                    ;
;--- CONFIGURAÇÃO DAS PORTAS DE ENTRADAS E SAÍDAS ---
                                    ; DA PORTA A (pino RA1) como ENTRADA
				    ; DA PORTA A (pino RA2) como SAÍDA
				    ; DA PORTA B como SAÍDA
START_PROG  BANK0		    ; Chavea para banco 0 de memória
            CLRF        PORTA       ; LIMPA PORTA A
            BANK1		    ; Chavea para banco 1 de memória
            MOVLW       H'02'       ; W <- 0x02 => B'0000 0010' => apenas RA1 como INPUT
            MOVWF       TRISA       ; TRISB <- W	    
                                    ; FIM DA CONFIGURAÇÃO DA PORTA A
                                    ;
                                    ; INÍCIO DA CONFIGURAÇÃO DA PORTA B
            BANK0		    ; Chavea para banco 0 de memória
            CLRF        PORTB       ; LIMPA PORTA B
            BANK1		    ; Chavea para banco 1 de memória
            MOVLW       H'00'       ; W <- 0x00 => B'0000 0000' => todos os pinos como OUTPUT
            MOVWF       TRISB       ; TRISB <- W
            BANK0		    ; Chavea para banco 0 de memória
                                    ; FIM DA CONFIGURAÇÃO PORTA B
                                    ;
; --- CONFIGURAÇÃO DO TIMER0 ---
            BANK1			; Chavea para banco 1 de memória
            BCF         OPTION_REG,T0CS ; SELECIONA "TIMER MODE"
            BCF         OPTION_REG,PSA  ; SELECIONA PRE-ESCALAR PARA TIMER0
            BSF         OPTION_REG,PS2
            BSF         OPTION_REG,PS1
            BSF         OPTION_REG,PS0
	    
            BANK0			; Chavea para banco 0 de memória
            MOVLW       H'AF'		; W <- 0xAF => H'AF' = D'174' => O led  irá oscilar em 24Hz
            MOVWF       TMR0		; TMR0 <- W
            BSF         INTCON,GIE	; HABILITA INTERRUPÇÕES
            BSF         INTCON,T0IE	; HABILITA INTERRUPÇÃO timer 0
					; FIM DA CONFIGURAÇÃO DO TIMER0
; --- LOOP ---
; while(1){
;   if (RA1 == 1){
;	PORTB = 0x0C;
;   }else{
;       PORTB = 0xC0;
;   }
; }				    
LOOP        NOP
                                    ;	INÍCIO IF1
IF1         BTFSS       PORTA,RA1   ;   TESTA BIT RA1 SE "1" SALTA PRÓXIMA INST.	   
            GOTO        ELSE_IF1    ;   SALTA PARA ELSE
THEN_IF1    MOVLW       H'0C'       ;	W <- 0x0C -> B'0000 1100'
            MOVWF       PORTB       ;	PORTB <- W
            GOTO        END_IF1     ;   VAI PARA FINAL DO IF1
ELSE_IF1    MOVLW       H'C0'       ;	W <- 0xC0 -> B'1100 0000'
            MOVWF       PORTB       ;	PORTB <- W
END_IF1     NOP                     ;	FIM IF1
            GOTO        LOOP        ;	VOLTA PARA O LOOP
            END
