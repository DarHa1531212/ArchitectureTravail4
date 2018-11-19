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
	    bcf TRISC,1		; d�finit les bits 1 � 3 du port C en sortie
	    bcf TRISC,2		
	    bcf TRISC,3
	    ;clrf TRISD		; d�finit tous les bits du port D en sorties
	    bsf TRISB, 0	;Bit 0 du port B en entr�e

	    movlw 0x3f		
	    movwf Count		;count = 0x3f

	    movlw 0x07		
	    movwf T0CON		;   T0CON = 0x07
				; active le temporisateur 0 et op�re ae 16 bits
				    ; Ces 8 bits (00000111) configure le micro-contr�leur de telle
				    ; sorte que le temporisateur 0 soit actif, qu'il op�re avec 16 bits,
				    ; qu'il utilise un facteur d'�chelle ainsi que l'horloge interne
				    ; => voir la page 149 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	    movlw 0xf1		
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
    bigloop
	btg PORTC,2		; Inverse ("toggle") la valeur courante du bit 2 stock� dans l'espace-m�moire associ� au port C			    
	loop  
	movff	PORTB,PORTD	
	bra loop		; Saute � l'adresse "loop" (soit l'adresse de l'instruction "btg")

   Zone4	code 0x100	
	
	TO_ISR				; Cette �tiquette pr�c�de l'instruction "movlw". Elle sert d'adresse destination � l'instruction "goto" apparaissant plus haut.
				; Les instructions qui suivent forment la sous-routine de gestion des interruptions.
				
				; Tout d'abord, on commence par r�initialiser la valeur initiale du temporisateur
	movlw 0xf1		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0H
	movlw 0x12		; Charge la valeur 0xf2 dans le registre WREG
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0L
				; (le temporisateur op�rant sur 16 bits, la valeur de d�part est dont 0xfff2)
	
	bcf INTCON,TMR0IF	; Met � z�ro le bit appel� TMR0IF (bit 2 de l'espace-m�moire associ� � INTCON)
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc r�initialis� � 0.

	decf Count		; d�cr�mente le contenu de l'espace-m�moire associ� � "Count"
	bnz saut		; saute � l'adresse associ�e � "saut" si le bit Z du registre de statut est � 0
				; Il y a donc un branchement si la valeur "Count" n'est pas nulle ("non zero").
				
	btg PORTC,1		; Inverse ("toggle") la valeur courante du bit 1 stock� dans l'espace-m�moire associ� au port C

	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	movwf Count		; copie le contenu du registre WREG dans l'espace-m�moire associ� � "Count"
saut
	
	goto bigloop
	retfie			; Provoque le retour � l'instruction qui a �t� interrompue par le temporisateur 0

	END


    END