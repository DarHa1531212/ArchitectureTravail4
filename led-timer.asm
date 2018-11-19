    LIST	p=18F4680     ; d�finit le num�ro du PIC pour lequel ce programme sera assembl�

;****************************************************************************
; INCLUDES
;****************************************************************************
#include	 <p18f4680.inc>	

;****************************************************************************
; MCU DIRECTIVES   (d�finit l'�tat de certains bits de configuration qui seront charg�s lorsque le PIC d�butera l'ex�cution)
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
ZONE1_UDATA	udata 0x60 			
Count	 	res 1 		
	
;************************************************************
; reset vector
 
Zone1	code 00000h		
goto Start		
	
;************************************************************
; interrupt vector
 
Zone2	code	00008h		            
	
	btfss INTCON,TMR0IF	
	bz PORTC			
	retfie			; cette instruction force le retour � l'instruction qui a �t� interrompue lors de l'interruption.
	goto TO_ISR		; saute � l'adresse-m�moire associ�e � l'�tiquette "TO_ISR"

;************************************************************
;program code starts here

Zone3	code 00020h		

Start				
	bcf TRISC,1		
	bcf TRISC,2		
	clrf TRISD		
	setf TRISB		

	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	movwf Count		; copie le contenu du registre WREG dans l'espace-m�moire associ� � "Count" 

	movlw 0x07		; Charge la valeur 0x07 dans le registre WREG
	movwf T0CON		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � T0CON
				; Ces 8 bits (00000111) configure le micro-contr�leur de telle
				; sorte que le temporisateur 0 soit actif, qu'il op�re avec 16 bits,
				; qu'il utilise un facteur d'�chelle ainsi que l'horloge interne
				; => voir la page 149 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw 0xff		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0H
	movlw 0xf2		; Charge la valeur 0xf2 dans le registre WREG
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0L
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
	;led verte
	btg PORTC,2		; Inverse ("toggle") la valeur courante du bit 2 stock� dans l'espace-m�moire associ� au port C
	movff PORTB,PORTD	; Copie le contenu du port B dans le port D
 	bra loop		; Saute � l'adresse "loop" (soit l'adresse de l'instruction "btg")

Zone4	code 0x100		; Ici, la nouvelle directive "code" d�finit une nouvelle adresse (dans la m�moire-programme) pour 
				; la prochaine instruction. Cette derni�re sera ainsi localis�e � l'adresse 0x100
				; Cette nouvelle zone de code est nomm�e "Zone4".

TO_ISR				; Cette �tiquette pr�c�de l'instruction "movlw". Elle sert d'adresse destination � l'instruction "goto" apparaissant plus haut.
				; Les instructions qui suivent forment la sous-routine de gestion des interruptions.
;Interruption pour le rouge				
				; Tout d'abord, on commence par r�initialiser la valeur initiale du temporisateur
	movlw 0xf1		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0H
	;movlw 0xf2		; Charge la valeur 0xf2 dans le registre WREG
	movlw 0x12
	;modiffie la fr�quence des interrutions
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0L
				; (le temporisateur op�rant sur 16 bits, la valeur de d�part est dont 0xfff2)
	
	bcf INTCON,TMR0IF	; Met � z�ro le bit appel� TMR0IF (bit 2 de l'espace-m�moire associ� � INTCON)
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc r�initialis� � 0.

	;modification du timer de la led verte 
	;jouer sur le nombre d'interruptions plutot que la frequence d'interruptions
	decf Count		; d�cr�mente le contenu de l'espace-m�moire associ� � "Count"
	bnz saut		; saute � l'adresse associ�e � "saut" si le bit Z du registre de statut est � 0
				; Il y a donc un branchement si la valeur "Count" n'est pas nulle ("non zero").
				
	btg PORTC,1		; Inverse ("toggle") la valeur courante du bit 1 stock� dans l'espace-m�moire associ� au port C

	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	;
	movwf Count		; copie le contenu du registre WREG dans l'espace-m�moire associ� � "Count"
saut
	retfie			; Provoque le retour � l'instruction qui a �t� interrompue par le temporisateur 0

	END



	


	
