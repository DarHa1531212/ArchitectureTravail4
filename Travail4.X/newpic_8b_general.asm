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
Count	 	res 1 

;*******************************************************************************
; Reset Vector
;*******************************************************************************
Zone1	code 00000h		
    goto START

Zone2	code	00008h
	btfss INTCON,TMR0IF
	retfie
	goto TO_ISR
    
;************************************************************
;program code starts here

Zone3	code 00020h 

    START
	    bcf TRISC,1		; définit les bits 1 à 3 du port C en sortie
	    bcf TRISC,2		
	    bcf TRISC,3
	    
	    bsf PORTC,1	
    	    bcf PORTC,2	    
    	    bcf PORTC,3


	    ;clrf TRISD		; définit tous les bits du port D en sorties
	    bsf TRISB, 0	;Bit 0 du port B en entrée

	    movlw 0xa		
	    movwf Count		;count = 0x3f

	    movlw 0x07		
	    movwf T0CON		;   T0CON = 0x07
				; active le temporisateur 0 et opère ae 16 bits
				    ; Ces 8 bits (00000111) configure le micro-contrôleur de telle
				    ; sorte que le temporisateur 0 soit actif, qu'il opère avec 16 bits,
				    ; qu'il utilise un facteur d'échelle ainsi que l'horloge interne
				    ; => voir la page 149 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	    movlw 0xa1		
	    movwf TMR0H		; T0CON = 0xff
	    movlw 0x12		
	    movwf TMR0L		; TMR0L = 0xf2
				; (le temporisateur opérant sur 16 bits, la valeur de départ est dont 0xfff2)

	    bcf INTCON,TMR0IF	; Met à zéro le bit appelé TMR0IF (bit 2 de l'espace-mémoire associé à INTCON)
				    ; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				    ; Le drapeau ("flag") est donc réinitialisé à 0.

	    bsf T0CON,TMR0ON	; Met à 1 le bit appelé TMR0ON (bit 7 de l'espace-mémoire associé à T0CON)
				    ; => voir la page 149 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				    ; Le temporisateur 0 est donc démarré.

	    bsf INTCON,TMR0IE	; Met à 1 le bit appelé TMR0IE (bit 5 de l'espace-mémoire associé à INTCON)
				    ; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				    ; Cette action autorise le temporisateur à interrompre le micro-contrôleur lorsque le temporisateur viendra à échéance (00000000).

	    bsf INTCON,GIE		; Met à 1 le bit appelé GIE (bit 7 de l'espace-mémoire associé à INTCON)
				    ; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				    ; Cette action autorise toutes les sources possibles d'interruptions qui ont été validées.
	loop  
	movff	PORTB,PORTD	
	bra loop		; Saute à l'adresse "loop" (soit l'adresse de l'instruction "btg")

   Zone4	code 0x100	
	
	TO_ISR				; Cette étiquette précède l'instruction "movlw". Elle sert d'adresse destination à l'instruction "goto" apparaissant plus haut.
				; Les instructions qui suivent forment la sous-routine de gestion des interruptions.
				
				; Tout d'abord, on commence par réinitialiser la valeur initiale du temporisateur
	movlw 0xA1		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	movlw 0x12		; Charge la valeur 0xf2 dans le registre WREG
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0L
				; (le temporisateur opérant sur 16 bits, la valeur de départ est dont 0xfff2)
	
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
	    movlw 0x3		
	    movwf Count
	    retfie
	
	allumerRouge
	    bsf PORTC, 3    
	    BCF PORTC, 2		
	    movlw 0xa		
	    movwf Count
	    retfie
	    
	allumerVerte
	    bsf PORTC, 1    
	    BCF PORTC, 3	
	    movlw 0xa		
	    movwf Count
	    retfie

saut
	    retfie
    END