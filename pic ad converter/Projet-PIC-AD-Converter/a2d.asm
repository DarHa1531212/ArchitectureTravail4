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

	LIST P=18F4680		; Définit le numéro du PIC pour lequel ce programme sera assemblé
	#include <P18F4680.INC>	; La directive "include" permet d'insérer la librairie "p18f4680.inc" dans le présent programme.
				; Cette librairie contient l'adresse de chacun des SFR ainsi que l'identité (nombre) de chaque bit 
				; de configuration portant un nom prédéfini.

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
ZONE1_UDATA	udata 0x60 	; La directive "udata" (unsigned data) permet de définir l'adresse du début d'une zone-mémoire
				; de la mémoire-donnée (ici 0x60).
				; Les directives "res" qui suivront, définiront des espaces-mémoire à partir de cette adresse.
				; La zone doit porter un nom unique (ici "ZONE1_UDATA") car on peut en définir plusieurs.
				
TEMP	 	res 1 		; La directive "res" réserve un seul octet qui pourra être référencé à l'aide du mot "TEMP".
				; L'octet sera localisé à l'adresse 0x60 (dans la banque 0).
 
;************************************************************
; reset and interrupt vectors

Zone1	code 0x00000		; La directive "code" définit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionnées à la suite.
				; Elles formeront une zone dont le nom sera "Zone1".
				; Ici, l'instruction "goto" sera donc stockée à l'adresse 00000h dans la mémoire-programme. 
				
	goto Start		; Le micro-contrôleur saute à l'adresse-programme définie par l'étiquette "Start".

Zone2	code	0x00008		; La directive "code" définit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionnées à la suite.
				; Elles formeront une zone dont le nom sera "Zone2".
				; Ici, l'instruction "goto" sera donc stockée à l'adresse 0x00008 dans la mémoire-programme.
				;
				; NOTE IMPORTANTE: Lorsque le micro-contrôleur subit une interruption, il interrompt le programme
				;                  en cours et saute à l'adresse 0x00008 pour exécuter l'instruction qui s'y trouve.
				;
				
	goto	ISR		; saute à l'adresse-mémoire associée à l'étiquette "ISR"	

;************************************************************
; program code starts here

Zone3	code 0x00020		; Ici, la nouvelle directive "code" définit une nouvelle adresse (dans la mémoire-programme) pour 
				; la prochaine instruction. Cette dernière sera ainsi localisée à l'adresse 0x00020
				; Cette nouvelle zone de code est nommée "Zone3".

Start				; Cette étiquette précède l'instruction "clrf". Elle sert d'adresse destination à l'instruction "goto" apparaissant plus haut.
	clrf	TRISC		; Force à zéro tous les bits de l'espace-mémoire associé à TRISC. Ceci configurera tous les bits du port C en sorties. 
	clrf	PORTC		; Force à zéro tous les bits de l'espace-mémoire associé à PORTC. 

	call	InitializeAD 	; Exécute la sous-routine débutant à l'adresse associés à "InitializeAD". Durant l'initialisation, le bit 0 du
				; port A est sélectionné comme entrée du convertisseur.
	
	call	SetupDelay	; Exécute la sous-routine débutant à l'adresse associés à "SetupDelay". 
				; Cela laisse le temps au convertisseur de se réinitialiser (obligatoire).
				
	bsf	ADCON0,GO	; Met à 1 le bit portant le nom "GO" (bit 1) dans l'espace-mémoire associé à "ADCON0". 
				; => voir la page 249 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci lance une opération de conversion analogique à digitale.

Main
	goto	Main		; Force le micro-contrôleur à exécuter indéfiniment la même instruction.

;************************************************************
; Service A/D interrupt
; Get value and display on LEDs

	; Ici débute la sous-routine gérant les interruptions.
	; On débute en vérificant si la source de l'interruption est le convertisseur analogique/digital
ISR

	; store context (WREG and STATUS) if required
	
	btfss	PIR1,ADIF	; Teste la valeur du bit portant le nom "ADIF" (bit 6) dans l'espace-mémoire associé à PIR1.
				; => voir la page 120 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ainsi, si ce bit est à 1, le convertisseur analogique/digital est bien la source de l'interruption. 
				; Le micro-contrôleur saute alors la prochaine instruction.
	
	goto	OtherInt	; Le micro-contrôleur saute à l'adresse associée à "OtherInt" s'il s'agit d'une autre source d'interruption.
	
	movf	ADRESH,W	; Charge le contenu de l'espace-mémoire associé à "ADRESH" dans le registre WREG
				; On place ainsi le résultat de la conversion dans le registre WREG.
				
	movwf	LATC		; On copie le contenu du registre WREG dans l'espace-mémoire associé à "LATC".
				; Si des DELS sont branchés sur les bits du port C, ceux-ci vont ainsi s'allumer s'ils sont à 1. 
				
	bcf	PIR1,ADIF	; On met à zéro le bit portant le nom "ADIF" (bit 6) dans l'espace-mémoire associé à PIR1.
				; => voir la page 120 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est ainsi remis à zéro avant de relancer une nouvelle conversion.

	call	SetupDelay	; On appelle la sous-routine débutant à l'adresse associée à "SetupDelay".
				; Cela laisse le temps au convertisseur de se réinitialiser (obligatoire).

	bsf	ADCON0,GO	; Met à 1 le bit portant le nom "GO" (bit 1) dans l'espace-mémoire associé à "ADCON0". 
				; => voir la page 249 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci lance une nouvelle opération de conversion analogique à digitale.

	goto	EndISR		; Le micro-contrôleur saute à l'adresse associée à "EndISR".

OtherInt
	; This would be replaced by code to check and service other interrupt sources
	goto	$	; Cette instruction boucle sur elle-même (boucle infinie).

EndISR
	; Restore context if saved.

	retfie		; Retour à l'instruction ayant été interrompue.

;************************************************************
; InitializeAD - initializes and sets up the A/D hardware.
; Select AN0 to AN3 as analog inputs, RC clock, and read AN0.

InitializeAD
	movlw	B'00000100'	; charge le nombre binaire 00000100 dans le registre WREG
				
	movwf	ADCON1		; copie le contenu du registre WREG dans l'espace-mémoire associé à "ADCON1".
				; Ceci configure le convertisseur analogique/digital de telle sorte que
				; tous les bits du port A soient des entrées. 
				; => voir la page 250 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw	B'11000001'	; charge le nombre binaire 11000001 dans le registre WREG

	movwf	ADCON0		; copie le contenu du registre WREG dans l'espace-mémoire associé à "ADCON0".
				; Ceci active le convertisseur et sélectionne le bit 0 du port A comme entrée du convertisseur

	bcf	PIR1,ADIF	; On met à zéro le bit portant le nom "ADIF" (bit 6) dans l'espace-mémoire associé à PIR1.
				; => voir la page 120 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est ainsi remis à zéro avant de relancer une nouvelle conversion.
 
	bsf	PIE1,ADIE	; On met à 1 le bit portant le nom "ADIE" (bit 6) dans l'espace-mémoire associé à PIE1.
				; => voir la page 123 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci autorise le convertisseur à interrompre le micro-contrôleur.
	
	bsf	INTCON,PEIE	; On met à 1 le bit portant le nom "PEIE" (bit 6) dans l'espace-mémoire associé à INTCON.
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci autorise les périphériques secondaires (comme le convertisseur) à interrompre le micro-contrôleur.

	bsf	INTCON,GIE	; On met à 1 le bit portant le nom "GIE" (bit 7) dans l'espace-mémoire associé à INTCON.
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise toutes les sources possibles d'interruptions qui ont été validées à interrompre 
				; le micro-contrôleur selon leur mode de fonctionnement.


	return			; Marque la fin de la sous-routine. Le micro-contrôleur retournera exécuter l'instruction qui suit le "call" qui a lancé la sous-routine.

;************************************************************
; This is used to allow the A/D time to sample the input
; (acquisition time).
;

SetupDelay
	movlw	.30		; Charge la valeur 30 (en base 10) dans le registre WREG. 
				; Évidemment, lors de l'assemblage du présent programme (génération du code machine), le logiciel MPLAB convertit ce nombre en binaire.
				; Ainsi, la valeur 0x1D (soit 00011110 en binaire) est stockée dans le registre WREG

	movwf	TEMP		; Copie le registre WREG dans l'espace-mémoire associé à "TEMP" 
SD
	decfsz	TEMP, F		; Décrémente la valeur contenue dans l'espace-mémoire associé à "TEMP", stocke ensuite le résultat dans le 
				; même espace, puis saute l'instruction suivante si ce résultat est nul (zéro).
				
	goto	SD		; Le micro-contrôleur saute à l'instruction dont l'adresse est associée à "SD".
	return

	END

