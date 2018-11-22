;*******************************************************************************
;                                                                              *
;    Filename:  newpic_8b_general.asm                                          *
;    Date:   19-11-2018                                                        *
;    File Version:  1.0.0.0                                                    *
;    Author:  Hans Darmstadt-Bélanger                                          *
;    Description: Système de feux de circulation                               *
;                                                                              *
;*******************************************************************************
;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;    19-11-2018 première version
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
	btfsc INTCON,TMR0IF
	    goto TO_ISR
	btfsc	PIR1,ADIF
	    goto PotInterrupt
	retfie
	
;************************************************************

Zone3	code 00020h 

				
	START
	    movlw 0xa		
	    movwf Count		;count = 0x3f
	    movlw 0x07		
	    movwf T0CON		;   T0CON = 0x07				
	    movlw 0xa1		
	    movwf TMR0H		; T0CON = 0xff
	    movlw 0x12		
	    movwf TMR0L		; TMR0L = 0xf2
			
	    
	    bcf INTCON,TMR0IF
	    bsf T0CON,TMR0ON
	    bsf INTCON,TMR0IE
	    bsf INTCON,GIE
	    
	    call	InitializeAD 	
	    call	SetupDelay
	    bsf		ADCON0,GO    

	    bcf TRISC,1		; définit les bits 1 à 3 du port C en sortie
	    bcf TRISC,2		
	    bcf TRISC,3

	    bsf PORTC,1	
	    bcf PORTC,2	    
	    bcf PORTC,3

	    movlw 0x3
	    movwf TempsCourt
	    movlw 0x8
	    movwf TempsLong

	    bsf TRISB, 0	;Bit 0 du port B en entrée

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
	    return

   Zone4	code 0x100	
	
	PotInterrupt
	    bcf	PIR1,ADIF
	    ;movf	ADRESH,W
	    movlw b'11110000'
	    CPFSGT ADRESH
		call RalentirLumiere
	    CPFSLT ADRESH 
		call AccelerereLumiere
	    ;si plus grand
	    goto saut
	AccelerereLumiere
	    movlw d'1'
	    movwf TempsCourt	
	    movlw d'3'
	    movwf TempsLong
	    goto saut
	RalentirLumiere
	    movlw 0x3
	    movwf TempsCourt	
	    movlw 0xa
	    movwf TempsLong
	    goto saut
	
	TO_ISR					
	    bcf INTCON,TMR0IF	
	    movlw 0xA1		
	    movwf TMR0H		
	    movlw 0x12		
	    movwf TMR0L		
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