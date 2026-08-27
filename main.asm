LIST P=16f887
#include <p16f887.inc>
    
    ;Bits de Configuración
    ; CONFIG1
    ; __config 0x3FC5
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
    ; CONFIG2
    ; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
operandoA  equ 20h
operandoB  equ 21h
resultado  equ 22h
contador   equ 23h
temporal   equ 24h
cociente   equ 25h
RES_VECT CODE 0x0000
    GOTO START
MAIN_PROG CODE
START
    BANKSEL PORTA
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH
    BANKSEL TRISA
    MOVLW 0xFF
    MOVWF TRISA
    CLRF TRISB
    MOVLW 0x07
    MOVWF TRISC
LOOP
    BANKSEL PORTA
    MOVF PORTA,0
    ANDLW 0x0F
    BANKSEL operandoA
    MOVWF operandoA
    BANKSEL PORTA
    MOVF PORTA,0
    ANDLW 0xF0
    BANKSEL operandoB
    MOVWF operandoB
    SWAPF operandoB,1
    BANKSEL PORTC
    MOVF PORTC,0
    ANDLW 0x07
    BANKSEL temporal
    MOVWF temporal
    MOVF temporal,0
    XORLW 0x00
    BTFSC STATUS,Z
    GOTO SUMA
    MOVF temporal,0
    XORLW 0x01
    BTFSC STATUS,Z
    GOTO RESTA
    MOVF temporal,0
    XORLW 0x02
    BTFSC STATUS,Z
    GOTO MULTIPLICACION
    MOVF temporal,0
    XORLW 0x03
    BTFSC STATUS,Z
    GOTO DIVISION
    MOVF temporal,0
    XORLW 0x04
    BTFSC STATUS,Z
    GOTO OPERACION_AND
    MOVF temporal,0
    XORLW 0x05
    BTFSC STATUS,Z
    GOTO OPERACION_OR
    MOVF temporal,0
    XORLW 0x06
    BTFSC STATUS,Z
    GOTO OPERACION_XOR
    MOVF temporal,0
    XORLW 0x07
    BTFSC STATUS,Z
    GOTO OPERACION_NOT
    GOTO LOOP
SUMA
    BANKSEL operandoA
    MOVF operandoA,0

    ADDWF operandoB,0

    BANKSEL resultado
    MOVWF resultado

    GOTO MOSTRAR
RESTA
    BANKSEL operandoB
    MOVF operandoB,0

    BANKSEL operandoA
    SUBWF operandoA,0

    BANKSEL resultado
    MOVWF resultado

    GOTO MOSTRAR
MULTIPLICACION
    BANKSEL operandoA
    MOVF operandoA,0
    MOVWF temporal

    CLRF resultado

    MOVF operandoB,0
    MOVWF contador
MULT_LOOP

    MOVF contador,0
    BTFSC STATUS,Z
    GOTO MULT_FIN

    MOVF temporal,0
    ADDWF resultado,1

    DECFSZ contador,1
    GOTO MULT_LOOP
MULT_FIN

    GOTO MOSTRAR
DIVISION
    BANKSEL operandoB
    MOVF operandoB,0

    BTFSC STATUS,Z
    GOTO DIVISION_CERO

    BANKSEL operandoA
    MOVF operandoA,0
    MOVWF temporal

    CLRF cociente
DIV_LOOP

    BANKSEL operandoB
    MOVF operandoB,0

    BANKSEL temporal
    SUBWF temporal,0

    BTFSS STATUS,C
    GOTO DIV_FIN

    MOVWF temporal

    INCF cociente,1

    GOTO DIV_LOOP
DIV_FIN

    BANKSEL cociente
    MOVF cociente,0
    MOVWF resultado

    GOTO MOSTRAR
DIVISION_CERO
    BANKSEL resultado
    MOVLW 0xFF
    MOVWF resultado

    GOTO MOSTRAR
OPERACION_AND

    BANKSEL operandoA
    MOVF operandoA,0

    ANDWF operandoB,0

    BANKSEL resultado
    MOVWF resultado

    GOTO MOSTRAR
OPERACION_OR
    BANKSEL operandoA
    MOVF operandoA,0

    IORWF operandoB,0

    BANKSEL resultado
    MOVWF resultado

    GOTO MOSTRAR
OPERACION_XOR

    BANKSEL operandoA
    MOVF operandoA,0

    XORWF operandoB,0

    BANKSEL resultado
    MOVWF resultado

    GOTO MOSTRAR
OPERACION_NOT

    BANKSEL operandoA
    MOVF operandoA,0

    XORLW 0x0F

    BANKSEL resultado
    MOVWF resultado

    GOTO MOSTRAR
MOSTRAR
    BANKSEL resultado
    MOVF resultado,0

    BANKSEL PORTB
    MOVWF PORTB

    GOTO LOOP
END