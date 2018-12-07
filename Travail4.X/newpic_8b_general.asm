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
    EtatActuelFeux  res 1
    Count	    res 1 
    TEMP	    res 1
    TempsCourt	    res 1
    TempsLong	    res 1

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
	btfsc	PIR1,RCIF

	goto LettresInterruption
	retfie
	
;************************************************************

Zone3	code 00090h 

				
START
	    movlw 0x3
	    movwf TempsCourt
	    movlw 0x8
	    movwf TempsLong 
	    
	    movlw 0x6e
	    movwf EtatActuelFeux
	
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

	    clrf	LATB
	    clrf	TRISB		
	    bcf		TRISC,6
	    movlw	0xA2
	    movwf	SPBRG
	    bsf	TXSTA,TXEN		
	    bsf	TXSTA,BRGH
	    bsf	RCSTA,SPEN
	    bsf	RCSTA,CREN
	    bcf	PIR1,RCIF
	    bsf PIE1,RCIE
	    bsf	INTCON,PEIE
	    bsf	INTCON,GIE

	    bcf TRISC,1		; définit les bits 1 à 3 du port C en sortie
	    bcf TRISC,2		
	    bcf TRISC,3

	    bsf PORTC,1	
	    bcf PORTC,2	    
	    bcf PORTC,3



	    bsf TRISB, 0	;Bit 0 du port B en entrée

	loop  
	    bsf		ADCON0,GO    
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
	    movlw	.50		
	    movwf	TEMP				
	SD
	    decfsz TEMP,F
	    goto SD
	    return

   Zone4	code 0x1000	
	
LettresInterruption
	movlw	06h
	andwf	RCSTA,W
	btfsc	STATUS,Z
	call SetEtatActuel
	movwf	LATB		
	movwf	TXREG					
	goto	saut	
	
	SetEtatActuel
	    movlw 0x6e;n
	    CPFSEQ RCREG
		goto TesterCEtA
	    movff WREG,EtatActuelFeux ;n
	    goto START
	    goto saut
	
	TesterCEtA
	    movlw 0x63 ;c
	    	CPFSEQ RCREG
		goto TesterA
		movff WREG,EtatActuelFeux ;c
		goto saut
		
	TesterA
	    movlw 0x61 ;a
	    CPFSEQ RCREG
	    goto saut
		movff WREG,EtatActuelFeux ;a
	    goto saut


RcvError
	bcf	RCSTA,CREN	
	bsf	RCSTA,CREN	
	movlw	0FFh
	movwf	PORTB
	goto saut
	
PotInterrupt

	    bcf	PIR1,ADIF
	    call SetupDelay
	    movlw b'00010000'
	    CPFSGT ADRESH
		call RalentirLumiere
	    CPFSLT ADRESH 
		call AccelerereLumiere
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
    arret
	BCF PORTC, 1
        BCF PORTC, 2
	BCF PORTC, 3
	goto saut
    ;arret here

    TesterClignotant	    
    	    movlw 0x63;c
	    CPFSEQ EtatActuelFeux
	    goto ArretFeux   
	    goto ActiverClignotant


    ActiverClignotant
	movlw 0x1
	movwf Count
	BCF PORTC, 1
        BCF PORTC, 2
	BTG PORTC, 3
	goto saut
	
    ArretFeux
        BCF PORTC, 1
        BCF PORTC, 2
	BCF PORTC, 3
	movlw 0x1
	movwf Count
	goto saut
    DeterminerCouleurAChanger
	movlw 0x6e;n
	CPFSEQ EtatActuelFeux
	    goto TesterClignotant

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