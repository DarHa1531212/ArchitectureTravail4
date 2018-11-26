;************************************************************
; This program demonstrates basic functionality of the USART.
;
; When the PIC18C452 receives a word of data from
; the USART, the value is retransmitted to the host computer.
;
; Set terminal program to 9600 baud, 1 stop bit, no parity

	list P=18F4680		; Définit le numéro du PIC pour lequel ce programme sera assemblé
	list n=0		; supress page breaks in list file
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
  

;************************************************************
; Reset and Interrupt Vectors

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
				
	goto	IntVector		; saute à l'adresse-mémoire associée à l'étiquette "IntVector"	

;************************************************************
; Program begins here

Zone3	code 0x00020		; Ici, la nouvelle directive "code" définit une nouvelle adresse (dans la mémoire-programme) pour 
				; la prochaine instruction. Cette dernière sera ainsi localisée à l'adresse 0x00020
				; Cette nouvelle zone de code est nommée "Zone3".
				
Start				; Cette étiquette précède l'instruction "clrf". Elle sert d'adresse destination à l'instruction "goto" apparaissant plus haut.
	clrf	LATB		; Force à zéro tous les bits de l'espace-mémoire associé à LATB. Tous les bits de sortie du port B seront mis à zéro.
	clrf	TRISB		; Force à zéro tous les bits de l'espace-mémoire associé à TRISB. Ceci configurera tous les bits du port B en sorties.
	bcf	TRISC,6		; Met à zéro le bit 6 de l'espace-mémoire associé à "TRISC". Ainsi, le bit 6 du port C sera configuré en sortie. 

	movlw	0xA2		; Charge la valeur 0xA2 dans le registre WREG
				
	movwf	SPBRG		; Copie le contenu du registre WREG dans l'espace-mémoire associé à "SPBRG".
				; Cette action configure le périphérique de communication sériel (EUSART) de telle
				; sorte qu'il opère à 9600 bits par seconde (lorsque le micro-contrôleur est cadencé par une horloge à 25 MHz).
				; => voir page 233 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	bsf	TXSTA,TXEN	; Met à 1 le bit "TXEN" (bit 5) de l'espace-mémoire associé à "TXSTA". 
				; Cette action active le module de transmission du périphérique de communication sérielle EUSART.
				; => voir page 230 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				
	bsf	TXSTA,BRGH	; Met à 1 le bit "BRGH" (bit 2) de l'espace-mémoire associé à "TXSTA".
				; Cette action permet au module de transmission du périphérique de fonctionner à haut débit binaire.
				; => voir page 230 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
	
	bsf	RCSTA,SPEN	; Met à 1 le bit "SPEN" (bit 7) de l'espace-mémoire associé à "RCSTA".
				; Cette action active le port du périphérique de communication sérielle EUSART.
				; => voir page 231 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				
	bsf	RCSTA,CREN	; Met à 1 le bit "CREN" (bit 4) de l'espace-mémoire associé à "RCSTA".
				; Cette action active le module de réception du périphérique de communication sérielle EUSART.
				; => voir page 231 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	bcf	PIR1,RCIF	; Met à 0 le bit "RCIF" (bit 5) de l'espace-mémoire associé à "PIR1".
				; Cette action met à zéro le drapeau ("flag") du module de communication.
				; => voir page 120 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
 

	bsf	PIE1,RCIE	; Met à 1 le bit "RCIE" (bit 5) de l'espace-mémoire associé à "PIE1".
				; Cette action autorise le module de communication à interrompre le micro-contrôleur.
				; => voir page 123 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	bsf	INTCON,PEIE	; On met à 1 le bit portant le nom "PEIE" (bit 6) dans l'espace-mémoire associé à INTCON.
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci autorise les périphériques secondaires (comme le convertisseur) à interrompre le micro-contrôleur.

	bsf	INTCON,GIE	; On met à 1 le bit portant le nom "GIE" (bit 7) dans l'espace-mémoire associé à INTCON.
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise toutes les sources possibles d'interruptions qui ont été validées à interrompre 
				; le micro-contrôleur selon leur mode de fonctionnement.

;************************************************************
; Main loop

Main
	goto	Main	; Force le micro-contrôleur à exécuter indéfiniment la même instruction.

;************************************************************
; Interrupt Service Routine

IntVector
	; save context (WREG and STATUS registers) if needed.

	btfss	PIR1,RCIF	; Teste si le bit nommé "RCIF" de l'espace-mémoire "PIR1" est à 1. Si oui, le micro-contrôleur saute l'instruction suivante.
				; Ce bit est en fait le drapeau ("flag") qui indique si le module de communication a interrompu le micro-contrôleur.
				
	goto	OtherInt	; Saute à l'adresse associée à "OtherInt" (si le module de communication n'est pas la cause de l'interruption).

	movlw	06h		; Charge la valeur 0x06 dans le registre WREG
				
	andwf	RCSTA,W		; Effectue un "ET logique" du contenu de l'espace-mémoire associé à RCSTA et le registre WREG.
				; Puisque WREG contien 0x06, les bits 1 et 2 seront conservés tel quel (alors que les autres seront mis à zéro).
				; (voir les bits 1 et 2 de RCSTA http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf)
				
	btfss	STATUS,Z	; Teste la valeur du bit Z du registre de statut. Si ce dernier est à 1 (c'est-à-dire si l'opération précédente a donné zéro),
				; le micro-contrôleur saute l'instruction suivante.
				; Il y a eu une erreur de communication si le bit 1 et/ou le bit 2 de RCSTA est à 1.
				; (voir http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf)
				
	goto	RcvError	; Le micro-contrôleur saute à l'adresse associée à "RcvError" (seulement si une erreur a été détectée)

	movf	RCREG,W		; Charge le contenu de l'espace-mémoire associé à "RCREG" dans le registre WREG.
				; On lit alors l'octet reçu par le périphérique de communication.
				
	movwf	LATB		; Le contenu du registre WREG est copié dans le port B.
	
	movwf	TXREG		; Le contenu du registre WREG est copié dans l'espace-mémoire associé à "TXREG".
				; Cette action force le périphérique de communication à transmettre l'octet.
				
	goto	ISREnd		; Le micro-contrôleur saut à l'adresse associée à "ISREnd" (qui marque la fin de la sous-routine d'interruption).
	
RcvError
	bcf	RCSTA,CREN	; Met à zéro le bit "CREN" (bit 5) de l'espace-mémoire associé à RCSTA.
				; => voir la page 231 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
			    
	bsf	RCSTA,CREN	; Met à 1 le bit "CREN" (bit 4) de l'espace-mémoire associé à "RCSTA".
				; Cette action active le module de réception du périphérique de communication sérielle EUSART.
				; => voir page 231 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw	0FFh		; Charge la valeur 0xff dans le registre WREG
	movwf	PORTB		; Copie le contenu du registre WREG dans le port B (dont tous les bits sont en sortie).
				; Ceci aura pour effet d'allumer tous les DELs qui y sont connectés.
				
	goto	ISREnd		; Le micro-contrôleur saute à l'adresse associée à "ISREnd". 

OtherInt
	goto  OtherInt	; Find cause of interrupt and service it before returning from
			; interrupt. If not, the same interrupt will re-occur as soon
			; as execution returns to interrupted program.

ISREnd
	; Restore context if needed.
	retfie			; Retour à l'instruction ayant été interrompue.

	end

