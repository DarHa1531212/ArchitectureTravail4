    LIST	p=18F4680     ; définit le numéro du PIC pour lequel ce programme sera assemblé

;****************************************************************************
; INCLUDES
;****************************************************************************
#include	 <p18f4680.inc>	

;****************************************************************************
; MCU DIRECTIVES   (définit l'état de certains bits de configuration qui seront chargés lorsque le PIC débutera l'exécution)
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
	retfie			; cette instruction force le retour à l'instruction qui a été interrompue lors de l'interruption.
	goto TO_ISR		; saute à l'adresse-mémoire associée à l'étiquette "TO_ISR"

;************************************************************
;program code starts here

Zone3	code 00020h		

Start				
	bcf TRISC,1		
	bcf TRISC,2		
	clrf TRISD		
	setf TRISB		

	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	movwf Count		; copie le contenu du registre WREG dans l'espace-mémoire associé à "Count" 

	movlw 0x07		; Charge la valeur 0x07 dans le registre WREG
	movwf T0CON		; Copie le contenu du registre WREG dans l'espace-mémoire associé à T0CON
				; Ces 8 bits (00000111) configure le micro-contrôleur de telle
				; sorte que le temporisateur 0 soit actif, qu'il opère avec 16 bits,
				; qu'il utilise un facteur d'échelle ainsi que l'horloge interne
				; => voir la page 149 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw 0xff		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	movlw 0xf2		; Charge la valeur 0xf2 dans le registre WREG
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0L
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
	;led verte
	btg PORTC,2		; Inverse ("toggle") la valeur courante du bit 2 stocké dans l'espace-mémoire associé au port C
	movff PORTB,PORTD	; Copie le contenu du port B dans le port D
 	bra loop		; Saute à l'adresse "loop" (soit l'adresse de l'instruction "btg")

Zone4	code 0x100		; Ici, la nouvelle directive "code" définit une nouvelle adresse (dans la mémoire-programme) pour 
				; la prochaine instruction. Cette dernière sera ainsi localisée à l'adresse 0x100
				; Cette nouvelle zone de code est nommée "Zone4".

TO_ISR				; Cette étiquette précède l'instruction "movlw". Elle sert d'adresse destination à l'instruction "goto" apparaissant plus haut.
				; Les instructions qui suivent forment la sous-routine de gestion des interruptions.
;Interruption pour le rouge				
				; Tout d'abord, on commence par réinitialiser la valeur initiale du temporisateur
	movlw 0xf1		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	;movlw 0xf2		; Charge la valeur 0xf2 dans le registre WREG
	movlw 0x12
	;modiffie la fréquence des interrutions
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0L
				; (le temporisateur opérant sur 16 bits, la valeur de départ est dont 0xfff2)
	
	bcf INTCON,TMR0IF	; Met à zéro le bit appelé TMR0IF (bit 2 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc réinitialisé à 0.

	;modification du timer de la led verte 
	;jouer sur le nombre d'interruptions plutot que la frequence d'interruptions
	decf Count		; décrémente le contenu de l'espace-mémoire associé à "Count"
	bnz saut		; saute à l'adresse associée à "saut" si le bit Z du registre de statut est à 0
				; Il y a donc un branchement si la valeur "Count" n'est pas nulle ("non zero").
				
	btg PORTC,1		; Inverse ("toggle") la valeur courante du bit 1 stocké dans l'espace-mémoire associé au port C

	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	;
	movwf Count		; copie le contenu du registre WREG dans l'espace-mémoire associé à "Count"
saut
	retfie			; Provoque le retour à l'instruction qui a été interrompue par le temporisateur 0

	END



	


	
