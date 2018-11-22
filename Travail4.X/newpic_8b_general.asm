;*******************************************************************************
;                                                                              *
;    Filename:  newpic_8b_general.asm                                          *
;    Date:   19-11-2018                                                        *
;    File Version:  1.0.0.0                                                    *
;    Author:  Hans Darmstadt-B�langer                                          *
;    Description: Syst�me de feux de circulation                               *
;                                                                              *
;*******************************************************************************
;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;    19-11-2018 premi�re version
;                                                                              *
;*******************************************************************************

; TODO INSERT INCLUDE CODE HERE
    LIST p=18F4680
    #include <p18f4680.inc>
      
; TODO INSERT CONFIG HERE
    
    CONFIG	OSC = ECIO           
    CONFIG	FCMEN = OFF        
    CONFIG	IESO = OFF       
    CONFIG	PWRT = ON           
    CONFIG	BOREN = OFF        
    CONFIG	BORV = 2          
    CONFIG	WDT = OFF          
    CONFIG	WDTPS = 256       
    CONFIG	MCLRE = ON          
    CONFIG	LPT1OSC = OFF      
    CONFIG	PBADEN = OFF        
    CONFIG	STVREN = ON     
    CONFIG	LVP = OFF         
    CONFIG	XINST = OFF       
    CONFIG	DEBUG = OFF   

; TODO PLACE VARIABLE DEFINITIONS GO HERE
    
ZONE1_UDATA	udata 0x60 			
    Count	res 1 
    TEMP	res 1
    TempsCourt	res 1
    TempsLong	res 1

;*******************************************************************************
; Reset Vector
;*******************************************************************************
Zone1	code 00000h		
    goto START

Zone2	code	00008h
	btfss INTCON,TMR0IF
	    goto TO_ISR
	btfsc	PIR1,ADIF
	    goto PotInterrupt
	retfie
	
;************************************************************
;program code starts here

Zone3	code 00020h 

				
	START

	call	InitializeAD 	
	    call	SetupDelay
	    bsf		ADCON0,GO    

	    bcf TRISC,1		; d�finit les bits 1 � 3 du port C en sortie
	    bcf TRISC,2		
	    bcf TRISC,3

	    bsf PORTC,1	
	    bcf PORTC,2	    
	    bcf PORTC,3

	    movlw 0x3
	    movwf TempsCourt
	    movlw 0xa
	    movwf TempsLong

	    ;clrf TRISD		; d�finit tous les bits du port D en sorties
	    bsf TRISB, 0	;Bit 0 du port B en entr�e

	    movlw 0xa		
	    movwf Count		;count = 0x3f

	    movlw 0x07		
	    movwf T0CON		;   T0CON = 0x07
				; active le temporisateur 0 et op�re ae 16 bits
				    ; Ces 8 bits (00000111) configure le micro-contr�leur de telle
				    ; sorte que le temporisateur 0 soit actif, qu'il op�re avec 16 bits,
				    ; qu'il utilise un facteur d'�chelle ainsi que l'horloge interne
				    ; => voir la page 149 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	    movlw 0xa1		
	    movwf TMR0H		; T0CON = 0xff
	    movlw 0x12		
	    movwf TMR0L		; TMR0L = 0xf2
				; (le temporisateur op�rant sur 16 bits, la valeur de d�part est dont 0xfff2)

	    bcf INTCON,TMR0IF	; Met � z�ro le bit appel� TMR0IF (bit 2 de l'espace-m�moire associ� � INTCON)
				    ; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				    ; Le drapeau ("flag") est donc r�initialis� � 0.

	    bsf T0CON,TMR0ON	; Met � 1 le bit appel� TMR0ON (bit 7 de l'espace-m�moire associ� � T0CON)
				    ; => voir la page 149 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				    ; Le temporisateur 0 est donc d�marr�.

	    bsf INTCON,TMR0IE	; Met � 1 le bit appel� TMR0IE (bit 5 de l'espace-m�moire associ� � INTCON)
				    ; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				    ; Cette action autorise le temporisateur � interrompre le micro-contr�leur lorsque le temporisateur viendra � �ch�ance (00000000).

	    bsf INTCON,GIE		; Met � 1 le bit appel� GIE (bit 7 de l'espace-m�moire associ� � INTCON)
				    ; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
					; Cette action autorise toutes les sources possibles d'interruptions qui ont �t� valid�es.
	loop  
	    movff	PORTB,PORTD	
	    bra loop		
	
	InitializeAD
	     movlw	B'00000100'	
	     movwf	ADCON1		
	     movlw	B'11000001'	
	     movwf	ADCON0		
	     bcf	PIR1,ADIF	
	     bsf	PIE1,ADIE	
	     bsf	INTCON,PEIE	
	     bsf	INTCON,GIE	
	     return
	     
	SetupDelay
	    movlw	.30		
	    movwf	TEMP		
	SD
	    decfsz	TEMP, F		
	    goto	SD		
	    return

   Zone4	code 0x100	
	
	PotInterrupt
	    ;movf	ADRESH,W
	    movlw b'11110000'
	    CPFSGT ADRESH
		call RalentirLumiere
	    CPFSLT ADRESH 
		call AccelerereLumiere
	    ;si plus grand
	    
	    movwf	LATC
	    bcf	PIR1,ADIF
	    call	SetupDelay
	    bsf	ADCON0,GO
	    goto saut
	AccelerereLumiere
	    movlw 0x1
	    movwf TempsCourt	
	    movlw 0x3
	    movwf TempsLong
	    goto saut
	RalentirLumiere
	    movlw 0x3
	    movwf TempsCourt	
	    movlw 0xa
	    movwf TempsLong
	    goto saut
	
	TO_ISR					
	    movlw 0xA1		
	    movwf TMR0H		
	    movlw 0x12		
	    movwf TMR0L		
	    bcf INTCON,TMR0IF	
	    decf Count		
	    bnz saut
	    goto DeterminerCouleurAChanger

	DeterminerCouleurAChanger
	    BTFSC PORTC,1
	    goto allumerJaune

	    BTFSC PORTC,2
	    goto allumerRouge

	    goto allumerVerte

	allumerJaune
	    bsf PORTC, 2    
	    BCF PORTC, 1	
	    movff TempsCourt, Count 		
	    retfie

	allumerRouge
	    bsf PORTC, 3    
	    BCF PORTC, 2		
	    movff TempsLong, Count 		
	    retfie

	allumerVerte
	    bsf PORTC, 1    
	    BCF PORTC, 3	
	    movff TempsLong, Count 		
	    retfie

	saut
	    retfie
    END