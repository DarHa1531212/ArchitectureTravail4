;************************************************************
; This program is a simple implementation of the
; PIC18F4680's A/D. 
;
; One Channel is selected (AN0).
; The hardware for this program is the UQAC PIC board. The program 
; converts the potentiometer value on RA0 and displays it as
; an 8 bit binary value on Port C.
;
; The A/D is configured as follows:
; Vref = +3V internal
; A/D Osc. = internal RC
; A/D Channel = AN0 (RA0)

	LIST P=18F4680		; D�finit le num�ro du PIC pour lequel ce programme sera assembl�
	#include <P18F4680.INC>	; La directive "include" permet d'ins�rer la librairie "p18f4680.inc" dans le pr�sent programme.
				; Cette librairie contient l'adresse de chacun des SFR ainsi que l'identit� (nombre) de chaque bit 
				; de configuration portant un nom pr�d�fini.

;****************************************************************************
; MCU DIRECTIVES
;****************************************************************************
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
;
ZONE1_UDATA	udata 0x60 	; La directive "udata" (unsigned data) permet de d�finir l'adresse du d�but d'une zone-m�moire
				; de la m�moire-donn�e (ici 0x60).
				; Les directives "res" qui suivront, d�finiront des espaces-m�moire � partir de cette adresse.
				; La zone doit porter un nom unique (ici "ZONE1_UDATA") car on peut en d�finir plusieurs.
				
TEMP	 	res 1 		; La directive "res" r�serve un seul octet qui pourra �tre r�f�renc� �l'aide du mot "TEMP".
				; L'octet sera localis� � l'adresse 0x60 (dans la banque 0).
 
;************************************************************
; reset and interrupt vectors

Zone1	code 0x00000		; La directive "code" d�finit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionn�es �la suite.
				; Elles formeront une zone dont le nom sera "Zone1".
				; Ici, l'instruction "goto" sera donc stock�e � l'adresse 00000h dans la m�moire-programme. 
				
	goto Start		; Le micro-contr�leur saute � l'adresse-programme d�finie par l'�tiquette "Start".

Zone2	code	0x00008		; La directive "code" d�finit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionn�es �la suite.
				; Elles formeront une zone dont le nom sera "Zone2".
				; Ici, l'instruction "goto" sera donc stock�e � l'adresse 0x00008 dans la m�moire-programme.
				;
				; NOTE IMPORTANTE: Lorsque le micro-contr�leur subit une interruption, il interrompt le programme
				;                  en cours et saute � l'adresse 0x00008 pour ex�cuter l'instruction qui s'y trouve.
				;
				
	goto	ISR		; saute � l'adresse-m�moire associ�e � l'�tiquette "ISR"	

;************************************************************
; program code starts here

Zone3	code 0x00020		; Ici, la nouvelle directive "code" d�finit une nouvelle adresse (dans la m�moire-programme) pour 
				; la prochaine instruction. Cette derni�re sera ainsi localis�e � l'adresse 0x00020
				; Cette nouvelle zone de code est nomm�e "Zone3".

Start				; Cette �tiquette pr�c�de l'instruction "clrf". Elle sert d'adresse destination � l'instruction "goto" apparaissant plus haut.
	clrf	TRISC		; Force � z�ro tous les bits de l'espace-m�moire associ� � TRISC. Ceci configurera tous les bits du port C en sorties. 
	clrf	PORTC		; Force � z�ro tous les bits de l'espace-m�moire associ� � PORTC. 

	call	InitializeAD 	; Ex�cute la sous-routine d�butant � l'adresse associ�s � "InitializeAD". Durant l'initialisation, le bit 0 du
				; port A est s�lectionn� comme entr�e du convertisseur.
	
	call	SetupDelay	; Ex�cute la sous-routine d�butant � l'adresse associ�s � "SetupDelay". 
				; Cela laisse le temps au convertisseur de se r�initialiser (obligatoire).
				
	bsf	ADCON0,GO	; Met � 1 le bit portant le nom "GO" (bit 1) dans l'espace-m�moire associ� � "ADCON0". 
				; => voir la page 249 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci lance une op�ration de conversion analogique � digitale.

Main
	goto	Main		; Force le micro-contr�leur � ex�cuter ind�finiment la m�me instruction.

;************************************************************
; Service A/D interrupt
; Get value and display on LEDs

	; Ici d�bute la sous-routine g�rant les interruptions.
	; On d�bute en v�rificant si la source de l'interruption est le convertisseur analogique/digital
ISR

	; store context (WREG and STATUS) if required
	
	btfss	PIR1,ADIF	; Teste la valeur du bit portant le nom "ADIF" (bit 6) dans l'espace-m�moire associ� � PIR1.
				; => voir la page 120 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ainsi, si ce bit est � 1, le convertisseur analogique/digital est bien la source de l'interruption. 
				; Le micro-contr�leur saute alors la prochaine instruction.
	
	goto	OtherInt	; Le micro-contr�leur saute � l'adresse associ�e � "OtherInt" s'il s'agit d'une autre source d'interruption.
	
	movf	ADRESH,W	; Charge le contenu de l'espace-m�moire associ� � "ADRESH" dans le registre WREG
				; On place ainsi le r�sultat de la conversion dans le registre WREG.
				
	movwf	LATC		; On copie le contenu du registre WREG dans l'espace-m�moire associ� � "LATC".
				; Si des DELS sont branch�s sur les bits du port C, ceux-ci vont ainsi s'allumer s'ils sont � 1. 
				
	bcf	PIR1,ADIF	; On met � z�ro le bit portant le nom "ADIF" (bit 6) dans l'espace-m�moire associ� � PIR1.
				; => voir la page 120 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est ainsi remis � z�ro avant de relancer une nouvelle conversion.

	call	SetupDelay	; On appelle la sous-routine d�butant � l'adresse associ�e � "SetupDelay".
				; Cela laisse le temps au convertisseur de se r�initialiser (obligatoire).

	bsf	ADCON0,GO	; Met � 1 le bit portant le nom "GO" (bit 1) dans l'espace-m�moire associ� � "ADCON0". 
				; => voir la page 249 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci lance une nouvelle op�ration de conversion analogique � digitale.

	goto	EndISR		; Le micro-contr�leur saute � l'adresse associ�e � "EndISR".

OtherInt
	; This would be replaced by code to check and service other interrupt sources
	goto	$	; Cette instruction boucle sur elle-m�me (boucle infinie).

EndISR
	; Restore context if saved.

	retfie		; Retour � l'instruction ayant �t� interrompue.

;************************************************************
; InitializeAD - initializes and sets up the A/D hardware.
; Select AN0 to AN3 as analog inputs, RC clock, and read AN0.

InitializeAD
	movlw	B'00000100'	; charge le nombre binaire 00000100 dans le registre WREG
				
	movwf	ADCON1		; copie le contenu du registre WREG dans l'espace-m�moire associ� � "ADCON1".
				; Ceci configure le convertisseur analogique/digital de telle sorte que
				; tous les bits du port A soient des entr�es. 
				; => voir la page 250 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw	B'11000001'	; charge le nombre binaire 11000001 dans le registre WREG

	movwf	ADCON0		; copie le contenu du registre WREG dans l'espace-m�moire associ� � "ADCON0".
				; Ceci active le convertisseur et s�lectionne le bit 0 du port A comme entr�e du convertisseur

	bcf	PIR1,ADIF	; On met � z�ro le bit portant le nom "ADIF" (bit 6) dans l'espace-m�moire associ� � PIR1.
				; => voir la page 120 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est ainsi remis � z�ro avant de relancer une nouvelle conversion.
 
	bsf	PIE1,ADIE	; On met � 1 le bit portant le nom "ADIE" (bit 6) dans l'espace-m�moire associ� � PIE1.
				; => voir la page 123 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci autorise le convertisseur � interrompre le micro-contr�leur.
	
	bsf	INTCON,PEIE	; On met � 1 le bit portant le nom "PEIE" (bit 6) dans l'espace-m�moire associ� � INTCON.
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci autorise les p�riph�riques secondaires (comme le convertisseur) � interrompre le micro-contr�leur.

	bsf	INTCON,GIE	; On met � 1 le bit portant le nom "GIE" (bit 7) dans l'espace-m�moire associ� � INTCON.
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise toutes les sources possibles d'interruptions qui ont �t� valid�es � interrompre 
				; le micro-contr�leur selon leur mode de fonctionnement.


	return			; Marque la fin de la sous-routine. Le micro-contr�leur retournera ex�cuter l'instruction qui suit le "call" qui a lanc� la sous-routine.

;************************************************************
; This is used to allow the A/D time to sample the input
; (acquisition time).
;

SetupDelay
	movlw	.30		; Charge la valeur 30 (en base 10) dans le registre WREG. 
				; �videmment, lors de l'assemblage du pr�sent programme (g�n�ration du code machine), le logiciel MPLAB convertit ce nombre en binaire.
				; Ainsi, la valeur 0x1D (soit 00011110 en binaire) est stock�e dans le registre WREG

	movwf	TEMP		; Copie le registre WREG dans l'espace-m�moire associ� � "TEMP" 
SD
	decfsz	TEMP, F		; D�cr�mente la valeur contenue dans l'espace-m�moire associ� � "TEMP", stocke ensuite le r�sultat dans le 
				; m�me espace, puis saute l'instruction suivante si ce r�sultat est nul (z�ro).
				
	goto	SD		; Le micro-contr�leur saute � l'instruction dont l'adresse est associ�e � "SD".
	return

	END

