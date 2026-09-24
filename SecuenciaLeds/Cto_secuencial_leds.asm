
; Programa que muestra el uso del TIMER0; 
; Autor: CHTobar
; Institución: Universidad del Cauca
; Fecha: 13-03-2026
    
;LIST	P=16f887
;#include "p16f887.inc"

; CONFIG1
; __config 0x3FC5
; __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0x3FFF
; __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

; Declaración de variables
;cont1   equ 20h
;cont2   equ 21h
;cont3   equ 22h

;RES_VECT  CODE    0x0000  ; vector de reset del procesador
 ;   GOTO    START         ; va al inicio del programa
;MAIN_PROG CODE            ; permite que el linker ubique el programa principal
;START

; ======= **** Configuración del microcontrolador **** =======
; Configuración de puertos
 ;   BANKSEL	PORTA ;
 ;   CLRF	PORTA	    ; Inicialización de PORTA (en ceros)
 ;   CLRF	PORTB	    ; Inicialización de PORTB (en ceros)
    
 ;   BANKSEL	ANSEL        
 ;   CLRF	ANSEL	    ; I/O digital
 ;   
 ;   BANKSEL	TRISA
 ;   MOVLW	0xFF	    
 ;   MOVWF	TRISA	    ; PORTA como entrada (1 en cada bit) 
 ;   CLRF	TRISB	    ; PORTB como salida (0 en cada bit)    

; Configuración del TIMER0
 ;   BANKSEL	TMR0 ;
 ;   CLRF	TMR0	    ; Clarea el TIMER0 y el prescaler
 ;   BANKSEL	OPTION_REG  
 ;   MOVLW	b'11010000' ; Máscara para el para selección del TIMER0, reloj interno y bits del prescaler
 ;   ANDWF	OPTION_REG,W 
 ;   IORLW	b'00000111' ; Fija el prescaler a 1:256
 ;   MOVWF	OPTION_REG ;
    
; Inicialización de variables
 ;   BANKSEL	PORTA ;    
    ; Inicializamos las variables utilizadas como contadores en cero
 ;   CLRF	cont1
 ;   CLRF	cont2
 ;   CLRF	cont3
    
; ======= **** Bucle principal **** =======
;LOOP    
 ;   NOP
 ;   GOTO	CONMUTAR
    
;CONTINUAR   
    ;MOVLW	D'128' 
    ;MOVWF	TMR0
  ;  CALL	DELAY       
 ;   NOP
 ;   GOTO	LOOP

;CONMUTAR	
  ;,  BTFSS	PORTB,0
 ;   GOTO	ENCENDER
 ;   GOTO	APAGAR

;ENCENDER
  ;  BSF		PORTB,0	; Clarea el bit 0 de PORTB
 ;   GOTO	CONTINUAR
    
;APAGAR
 ;   BCF		PORTB,0	; Clarea el bit 0 de PORTB
 ;   GOTO	CONTINUAR
    
;DELAY
;   NOP
;   BTFSS	INTCON,T0IF
   ; GOTO	DELAY
  ;  BCF		INTCON,T0IF
 ;   RETURN    
    
  ;  END
 
  
;=====================================================================
; SECUENCIAL_LEDS - PIC16F887
;
; VERSION NO BLOQUEANTE
;
; La cascada pedida se implementa asi:
;
;       TIMER0 (CONTADOR 1: 0..255)
;                    |
;                overflow
;                    v
;              cont2: 0..255
;                    |
;                overflow
;                    v
;              cont3: 0..255
;                    |
;                overflow
;                    v
;              CAMBIO DE PASO
;
; TIMER0 trabaja como el primer contador de 8 bits.
; Cuando TIMER0 pasa de FF a 00, genera una interrupcion y cont2
; recibe el incremento. Cuando cont2 pasa de FF a 00, cont3 recibe
; el incremento. Cuando cont3 pasa de FF a 00, se activa la bandera
; "cambio".
;
; El programa principal NO espera dentro de un delay. Por eso RA0-RA2
; se leen continuamente y el DIP puede cambiarse mientras la secuencia
; esta funcionando.
;
; Seleccion DIP:
;   000 P1   001 P2   010 P3   011 P4
;   100 P5   101 P6   110 P7   111 P8
;
; IMPORTANTE:
; El circuito de Proteus recibido tiene Frequency="5 MHz" y Ext_Osc=true,
; mientras el codigo original configura el oscilador interno.
; Para este codigo use frecuencia 4 MHz y reloj interno en Proteus.
; Si se quiere trabajar a 5 MHz, el tiempo cambia ligeramente, pero
; la logica de la secuencia no cambia.
;=====================================================================

        LIST    P=16F887
        #include "p16f887.inc"

        __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
        __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;=====================================================================
; VARIABLES - BANK 0
;=====================================================================
cont2           EQU     20h
cont3           EQU     21h
seleccion       EQU     22h
paso            EQU     23h
secuencia_ant   EQU     24h
aux             EQU     25h
limite          EQU     26h
patron          EQU     27h
cambio          EQU     28h

w_temp          EQU     70h
status_temp     EQU     71h
pclath_temp     EQU     72h

; TMR0 se precarga con 240:
; 240..255 = 16 cuentas.
; Con Fosc=4 MHz, overflow aproximadamente cada 16 us.
; Un ciclo completo cont2+cont3 = 256*256*16 us = 1.048576 s.
TMR0_PRELOAD   EQU     D'240'

;=====================================================================
; VECTOR DE RESET
;=====================================================================
RES_VECT CODE    0x0000
        GOTO    START

;=====================================================================
; VECTOR DE INTERRUPCION
;=====================================================================
INT_VECT CODE    0x0004
        GOTO    ISR

;=====================================================================
; PROGRAMA PRINCIPAL
;=====================================================================
MAIN_PROG CODE

START
        ; Oscilador interno = 4 MHz
        BANKSEL OSCCON
        MOVLW   b'01100001'
        MOVWF   OSCCON

        ; PORTA = entradas, PORTB = salidas
        BANKSEL PORTA
        CLRF    PORTA
        CLRF    PORTB

        BANKSEL ANSEL
        CLRF    ANSEL

        BANKSEL ANSELH
        CLRF    ANSELH

        BANKSEL TRISA
        MOVLW   b'11111111'
        MOVWF   TRISA
        CLRF    TRISB

        ; TIMER0:
        ; T0CS=0 -> reloj interno Fosc/4
        ; PSA=1  -> sin prescaler
        ; PS=000 -> 1:1
        BANKSEL OPTION_REG
        MOVLW   b'11001000'
        MOVWF   OPTION_REG

        ; Primera carga de TIMER0
        BANKSEL TMR0
        MOVLW   TMR0_PRELOAD
        MOVWF   TMR0

        BANKSEL INTCON
        BCF     INTCON,T0IF
        BSF     INTCON,T0IE
        BSF     INTCON,GIE

        ; Variables en BANK 0
        BANKSEL PORTA
        CLRF    cont2
        CLRF    cont3
        CLRF    seleccion
        CLRF    paso
        CLRF    secuencia_ant
        CLRF    aux
        CLRF    limite
        CLRF    patron
        CLRF    cambio

        ; Primer patron seleccionado por DIP
        CALL    LEER_DIP
        MOVF    seleccion,W
        MOVWF   secuencia_ant

LOOP
        ; Se lee el DIP en cada vuelta: se puede cambiar en caliente.
        CALL    LEER_DIP
        CALL    DETECTAR_CAMBIO

        ; La ISR solo coloca cambio=1.
        ; Aqui se avanza el estado sin bloquear el programa.
        MOVF    cambio,F
        BTFSC   STATUS,Z
        GOTO    MOSTRAR

        CLRF    cambio
        CALL    AVANZAR_PASO

MOSTRAR
        CALL    EJECUTAR_PATRON
        GOTO    LOOP

;=====================================================================
; LEER_DIP
; RA2:RA0 = seleccion del patron
;=====================================================================
LEER_DIP
        MOVF    PORTA,W
        ANDLW   b'00000111'
        MOVWF   seleccion
        RETURN

;=====================================================================
; DETECTAR_CAMBIO
; Al cambiar el DIP:
;   - reinicia paso
;   - reinicia cont2 y cont3
;   - reinicia TIMER0
;   - apaga LEDs momentaneamente
;=====================================================================
DETECTAR_CAMBIO
        MOVF    seleccion,W
        XORWF   secuencia_ant,W
        BTFSC   STATUS,Z
        RETURN

        MOVF    seleccion,W
        MOVWF   secuencia_ant

        CLRF    paso
        CLRF    cont2
        CLRF    cont3
        CLRF    cambio
        CLRF    PORTB

        BANKSEL TMR0
        MOVLW   TMR0_PRELOAD
        MOVWF   TMR0
        BANKSEL PORTA

        RETURN

;=====================================================================
; AVANZAR_PASO
;=====================================================================
AVANZAR_PASO
        INCF    paso,F

        MOVF    limite,W
        SUBWF   paso,W
        BTFSS   STATUS,Z
        RETURN

        CLRF    paso
        RETURN

;=====================================================================
; EJECUTAR_PATRON
;=====================================================================
EJECUTAR_PATRON
        MOVF    seleccion,W
        XORLW   D'0'
        BTFSC   STATUS,Z
        GOTO    PATRON_1

        MOVF    seleccion,W
        XORLW   D'1'
        BTFSC   STATUS,Z
        GOTO    PATRON_2

        MOVF    seleccion,W
        XORLW   D'2'
        BTFSC   STATUS,Z
        GOTO    PATRON_3

        MOVF    seleccion,W
        XORLW   D'3'
        BTFSC   STATUS,Z
        GOTO    PATRON_4

        MOVF    seleccion,W
        XORLW   D'4'
        BTFSC   STATUS,Z
        GOTO    PATRON_5

        MOVF    seleccion,W
        XORLW   D'5'
        BTFSC   STATUS,Z
        GOTO    PATRON_6

        MOVF    seleccion,W
        XORLW   D'6'
        BTFSC   STATUS,Z
        GOTO    PATRON_7

        GOTO    PATRON_8

;=====================================================================
; ISR - TIMER0
;
; TIMER0 = contador 1 de 8 bits.
; Cada overflow:
;   cont2++
; Si cont2 hace FF->00:
;   cont3++
; Si cont3 hace FF->00:
;   cambio=1
;
; La ISR es corta y NO modifica PORTB ni lee el DIP.
;=====================================================================
ISR
        MOVWF   w_temp
        SWAPF   STATUS,W
        MOVWF   status_temp
        MOVF    PCLATH,W
        MOVWF   pclath_temp

        BTFSS   INTCON,T0IF
        GOTO    ISR_SALIR

        BCF     INTCON,T0IF

        ; Recargar TIMER0 para el siguiente intervalo
        MOVLW   TMR0_PRELOAD
        MOVWF   TMR0

        ; Segundo contador
        INCF    cont2,F
        BTFSS   STATUS,Z
        GOTO    ISR_SALIR

        ; Tercer contador
        INCF    cont3,F
        BTFSS   STATUS,Z
        GOTO    ISR_SALIR

        ; Los tres niveles completaron su ciclo
        BSF     cambio,0

ISR_SALIR
        MOVF    pclath_temp,W
        MOVWF   PCLATH
        SWAPF   status_temp,W
        MOVWF   STATUS
        SWAPF   w_temp,F
        SWAPF   w_temp,W
        RETFIE

;=====================================================================
; PATRON 1
; B0 -> B1 -> B2 -> ... -> B7
;=====================================================================
PATRON_1

        MOVLW   D'8'
        MOVWF   limite

        MOVLW   b'00000001'
        MOVWF   patron

        MOVF    paso,W
        MOVWF   aux

        BCF     STATUS,C

P1_DESPLAZAR
        MOVF    aux,F
        BTFSC   STATUS,Z
        GOTO    P1_SALIDA

        RLF     patron,F
        DECF    aux,F
        GOTO    P1_DESPLAZAR

P1_SALIDA
        MOVF    patron,W
        MOVWF   PORTB
        RETURN

;=====================================================================
; PATRON 2
; B7 -> B6 -> B5 -> ... -> B0
;=====================================================================
PATRON_2

        MOVLW   D'8'
        MOVWF   limite

        MOVLW   b'10000000'
        MOVWF   patron

        MOVF    paso,W
        MOVWF   aux

        BCF     STATUS,C

P2_DESPLAZAR
        MOVF    aux,F
        BTFSC   STATUS,Z
        GOTO    P2_SALIDA

        RRF     patron,F
        DECF    aux,F
        GOTO    P2_DESPLAZAR

P2_SALIDA
        MOVF    patron,W
        MOVWF   PORTB
        RETURN

;=====================================================================
; PATRON 3
; Todos ON -> todos OFF -> repetir
;=====================================================================
PATRON_3

        MOVLW   D'2'
        MOVWF   limite

        MOVF    paso,F
        BTFSC   STATUS,Z
        GOTO    P3_ENCENDER

        CLRF    PORTB
        RETURN

P3_ENCENDER
        MOVLW   b'11111111'
        MOVWF   PORTB
        RETURN

;=====================================================================
; PATRON 4
; B0 -> B1 -> ... -> B7 -> B6 -> ... -> B0
;
; paso 0..7  : desplaza hacia la izquierda
; paso 8..14 : regresa hacia la derecha
;=====================================================================
PATRON_4

        MOVLW   D'15'
        MOVWF   limite

        ; Si bit 3 de paso = 0, estamos en 0..7.
        BTFSS   paso,3
        GOTO    P4_IZQUIERDA

        ; Para 8..14:
        ; desplazamientos = paso - 7
        MOVLW   D'7'
        SUBWF   paso,W
        MOVWF   aux

        MOVLW   b'10000000'
        MOVWF   patron

        BCF     STATUS,C

P4_DERECHA
        MOVF    aux,F
        BTFSC   STATUS,Z
        GOTO    P4_SALIDA

        RRF     patron,F
        DECF    aux,F
        GOTO    P4_DERECHA

P4_SALIDA
        MOVF    patron,W
        MOVWF   PORTB
        RETURN

P4_IZQUIERDA
        MOVF    paso,W
        MOVWF   aux

        MOVLW   b'00000001'
        MOVWF   patron

        BCF     STATUS,C

P4_IZQ_LOOP
        MOVF    aux,F
        BTFSC   STATUS,Z
        GOTO    P4_IZQ_SALIDA

        RLF     patron,F
        DECF    aux,F
        GOTO    P4_IZQ_LOOP

P4_IZQ_SALIDA
        MOVF    patron,W
        MOVWF   PORTB
        RETURN

;=====================================================================
; PATRON 5
; Extremos hacia centro:
; 81 -> 42 -> 24 -> 18
;=====================================================================
PATRON_5

        MOVLW   D'4'
        MOVWF   limite

        MOVF    paso,W
        XORLW   D'0'
        BTFSC   STATUS,Z
        GOTO    P5_81

        MOVF    paso,W
        XORLW   D'1'
        BTFSC   STATUS,Z
        GOTO    P5_42

        MOVF    paso,W
        XORLW   D'2'
        BTFSC   STATUS,Z
        GOTO    P5_24

        GOTO    P5_18

P5_81
        MOVLW   b'10000001'
        MOVWF   PORTB
        RETURN

P5_42
        MOVLW   b'01000010'
        MOVWF   PORTB
        RETURN

P5_24
        MOVLW   b'00100100'
        MOVWF   PORTB
        RETURN

P5_18
        MOVLW   b'00011000'
        MOVWF   PORTB
        RETURN

;=====================================================================
; PATRON 6
; LEDs de indice par:
; B0 -> B2 -> B4 -> B6
;=====================================================================
PATRON_6

        MOVLW   D'4'
        MOVWF   limite

        MOVLW   b'00000001'
        MOVWF   patron

        MOVF    paso,W
        MOVWF   aux

        BCF     STATUS,C

P6_DESPLAZAR
        MOVF    aux,F
        BTFSC   STATUS,Z
        GOTO    P6_SALIDA

        RLF     patron,F
        RLF     patron,F
        DECF    aux,F
        GOTO    P6_DESPLAZAR

P6_SALIDA
        MOVF    patron,W
        MOVWF   PORTB
        RETURN

;=====================================================================
; PATRON 7
; Centro hacia extremos:
; 18 -> 24 -> 42 -> 81
;=====================================================================
PATRON_7

        MOVLW   D'4'
        MOVWF   limite

        MOVF    paso,W
        XORLW   D'0'
        BTFSC   STATUS,Z
        GOTO    P7_18

        MOVF    paso,W
        XORLW   D'1'
        BTFSC   STATUS,Z
        GOTO    P7_24

        MOVF    paso,W
        XORLW   D'2'
        BTFSC   STATUS,Z
        GOTO    P7_42

        GOTO    P7_81

P7_18
        MOVLW   b'00011000'
        MOVWF   PORTB
        RETURN

P7_24
        MOVLW   b'00100100'
        MOVWF   PORTB
        RETURN

P7_42
        MOVLW   b'01000010'
        MOVWF   PORTB
        RETURN

P7_81
        MOVLW   b'10000001'
        MOVWF   PORTB
        RETURN

;=====================================================================
; PATRON 8
; Extremos hacia centro acumulando LEDs:
; 81 -> C3 -> E7 -> FF
;=====================================================================
PATRON_8

        MOVLW   D'4'
        MOVWF   limite

        MOVF    paso,W
        XORLW   D'0'
        BTFSC   STATUS,Z
        GOTO    P8_81

        MOVF    paso,W
        XORLW   D'1'
        BTFSC   STATUS,Z
        GOTO    P8_C3

        MOVF    paso,W
        XORLW   D'2'
        BTFSC   STATUS,Z
        GOTO    P8_E7

        GOTO    P8_FF

P8_81
        MOVLW   b'10000001'
        MOVWF   PORTB
        RETURN

P8_C3
        MOVLW   b'11000011'
        MOVWF   PORTB
        RETURN

P8_E7
        MOVLW   b'11100111'
        MOVWF   PORTB
        RETURN

P8_FF
        MOVLW   b'11111111'
        MOVWF   PORTB
        RETURN


        END
