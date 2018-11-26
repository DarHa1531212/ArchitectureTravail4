;************************************************************
; This program demonstrates basic functionality of the USART.
;
; When the PIC18C452 receives a word of data from
; the USART, the value is retransmitted to the host computer.
;
; Set terminal program to 9600 baud, 1 stop bit, no parity

	list P=18F4680		; D�finit le num�ro du PIC pour lequel ce programme sera assembl�
	list n=0		; supress page breaks in list file
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
  

;************************************************************
; Reset and Interrupt Vectors

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
				
	goto	IntVector		; saute � l'adresse-m�moire associ�e � l'�tiquette "IntVector"	

;************************************************************
; Program begins here

Zone3	code 0x00020		; Ici, la nouvelle directive "code" d�finit une nouvelle adresse (dans la m�moire-programme) pour 
				; la prochaine instruction. Cette derni�re sera ainsi localis�e � l'adresse 0x00020
				; Cette nouvelle zone de code est nomm�e "Zone3".
				
Start				; Cette �tiquette pr�c�de l'instruction "clrf". Elle sert d'adresse destination � l'instruction "goto" apparaissant plus haut.
	clrf	LATB		; Force � z�ro tous les bits de l'espace-m�moire associ� � LATB. Tous les bits de sortie du port B seront mis � z�ro.
	clrf	TRISB		; Force � z�ro tous les bits de l'espace-m�moire associ� � TRISB. Ceci configurera tous les bits du port B en sorties.
	bcf	TRISC,6		; Met � z�ro le bit 6 de l'espace-m�moire associ� � "TRISC". Ainsi, le bit 6 du port C sera configur� en sortie. 

	movlw	0xA2		; Charge la valeur 0xA2 dans le registre WREG
				
	movwf	SPBRG		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � "SPBRG".
				; Cette action configure le p�riph�rique de communication s�riel (EUSART) de telle
				; sorte qu'il op�re � 9600 bits par seconde (lorsque le micro-contr�leur est cadenc� par une horloge � 25 MHz).
				; => voir page 233 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	bsf	TXSTA,TXEN	; Met � 1 le bit "TXEN" (bit 5) de l'espace-m�moire associ� � "TXSTA". 
				; Cette action active le module de transmission du p�riph�rique de communication s�rielle EUSART.
				; => voir page 230 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				
	bsf	TXSTA,BRGH	; Met � 1 le bit "BRGH" (bit 2) de l'espace-m�moire associ� � "TXSTA".
				; Cette action permet au module de transmission du p�riph�rique de fonctionner � haut d�bit binaire.
				; => voir page 230 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
	
	bsf	RCSTA,SPEN	; Met � 1 le bit "SPEN" (bit 7) de l'espace-m�moire associ� � "RCSTA".
				; Cette action active le port du p�riph�rique de communication s�rielle EUSART.
				; => voir page 231 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				
	bsf	RCSTA,CREN	; Met � 1 le bit "CREN" (bit 4) de l'espace-m�moire associ� � "RCSTA".
				; Cette action active le module de r�ception du p�riph�rique de communication s�rielle EUSART.
				; => voir page 231 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	bcf	PIR1,RCIF	; Met � 0 le bit "RCIF" (bit 5) de l'espace-m�moire associ� � "PIR1".
				; Cette action met � z�ro le drapeau ("flag") du module de communication.
				; => voir page 120 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
 

	bsf	PIE1,RCIE	; Met � 1 le bit "RCIE" (bit 5) de l'espace-m�moire associ� � "PIE1".
				; Cette action autorise le module de communication � interrompre le micro-contr�leur.
				; => voir page 123 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	bsf	INTCON,PEIE	; On met � 1 le bit portant le nom "PEIE" (bit 6) dans l'espace-m�moire associ� � INTCON.
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Ceci autorise les p�riph�riques secondaires (comme le convertisseur) � interrompre le micro-contr�leur.

	bsf	INTCON,GIE	; On met � 1 le bit portant le nom "GIE" (bit 7) dans l'espace-m�moire associ� � INTCON.
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise toutes les sources possibles d'interruptions qui ont �t� valid�es � interrompre 
				; le micro-contr�leur selon leur mode de fonctionnement.

;************************************************************
; Main loop

Main
	goto	Main	; Force le micro-contr�leur � ex�cuter ind�finiment la m�me instruction.

;************************************************************
; Interrupt Service Routine

IntVector
	; save context (WREG and STATUS registers) if needed.

	btfss	PIR1,RCIF	; Teste si le bit nomm� "RCIF" de l'espace-m�moire "PIR1" est � 1. Si oui, le micro-contr�leur saute l'instruction suivante.
				; Ce bit est en fait le drapeau ("flag") qui indique si le module de communication a interrompu le micro-contr�leur.
				
	goto	OtherInt	; Saute � l'adresse associ�e � "OtherInt" (si le module de communication n'est pas la cause de l'interruption).

	movlw	06h		; Charge la valeur 0x06 dans le registre WREG
				
	andwf	RCSTA,W		; Effectue un "ET logique" du contenu de l'espace-m�moire associ� � RCSTA et le registre WREG.
				; Puisque WREG contien 0x06, les bits 1 et 2 seront conserv�s tel quel (alors que les autres seront mis � z�ro).
				; (voir les bits 1 et 2 de RCSTA http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf)
				
	btfss	STATUS,Z	; Teste la valeur du bit Z du registre de statut. Si ce dernier est � 1 (c'est-�-dire si l'op�ration pr�c�dente a donn� z�ro),
				; le micro-contr�leur saute l'instruction suivante.
				; Il y a eu une erreur de communication si le bit 1 et/ou le bit 2 de RCSTA est � 1.
				; (voir http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf)
				
	goto	RcvError	; Le micro-contr�leur saute � l'adresse associ�e � "RcvError" (seulement si une erreur a �t� d�tect�e)

	movf	RCREG,W		; Charge le contenu de l'espace-m�moire associ� � "RCREG" dans le registre WREG.
				; On lit alors l'octet re�u par le p�riph�rique de communication.
				
	movwf	LATB		; Le contenu du registre WREG est copi� dans le port B.
	
	movwf	TXREG		; Le contenu du registre WREG est copi� dans l'espace-m�moire associ� � "TXREG".
				; Cette action force le p�riph�rique de communication � transmettre l'octet.
				
	goto	ISREnd		; Le micro-contr�leur saut � l'adresse associ�e � "ISREnd" (qui marque la fin de la sous-routine d'interruption).
	
RcvError
	bcf	RCSTA,CREN	; Met � z�ro le bit "CREN" (bit 5) de l'espace-m�moire associ� � RCSTA.
				; => voir la page 231 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
			    
	bsf	RCSTA,CREN	; Met � 1 le bit "CREN" (bit 4) de l'espace-m�moire associ� � "RCSTA".
				; Cette action active le module de r�ception du p�riph�rique de communication s�rielle EUSART.
				; => voir page 231 de http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw	0FFh		; Charge la valeur 0xff dans le registre WREG
	movwf	PORTB		; Copie le contenu du registre WREG dans le port B (dont tous les bits sont en sortie).
				; Ceci aura pour effet d'allumer tous les DELs qui y sont connect�s.
				
	goto	ISREnd		; Le micro-contr�leur saute � l'adresse associ�e � "ISREnd". 

OtherInt
	goto  OtherInt	; Find cause of interrupt and service it before returning from
			; interrupt. If not, the same interrupt will re-occur as soon
			; as execution returns to interrupted program.

ISREnd
	; Restore context if needed.
	retfie			; Retour � l'instruction ayant �t� interrompue.

	end

