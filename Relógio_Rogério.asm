	PROCESSOR 16F877A
		RADIX 	  DEC
	#INCLUDE <p16f877a.inc>
	__config	0x3F32
	org 0x00
	goto inicio
	
	org 0X04
	goto inter

	org	20H
temp 		res 2
u_seg 		res 1 ; ====> Variavel da unidade de segundos no relogio
d_seg 		res 1 ; ====> Variavel da dezena de segundos no relogio
u_min 		res 1 ; ====> Variavel de unidades de minutos no relogio
d_min 		res 1 ; ====> Variavel de dezena de minutos no relogio
u_hor		res 1 ; ====> Variavel de unidade de hora no relogio
d_hor 		res 1 ; ====> Variavel de dezena de hora no relogio
displ		res 1 ; ====> Variavel do relógio : MM:SS e HH:MM
w_temp		res 1 ; ====> Variavel de restauração de contexto na interrupcao
s_temp 		res 1 ; ====> Variavel de restauração de contexto na interrupcao
;cont   		res 1 ; ====> Variavel dos segundos no relógio	
flags		res 1 ; ====> Variavel de pisca dos pontos no relogio
incre		res 1 ; ====> Variavel que faz a incrementacao entrar no modo ajuste
d_alarmeH	res 1 ; ====> Variavel de dezena de hora no relogio: =======================================================
u_alarmeH	res 1 ; ====> Variavel de unidade de hora no relogio : ============== Modo alarme ========================
d_alarmeM	res 1 ; ====> Variavel de dezena de minutos no relogio : ================================================
u_alarmeM	res	1 ; ====> Variavel de unidades de minutos no relogio : ============================================
rb4			res 1 ; ====> Variavel que silencia o alarme
toca		res 1 ; ====> Variavel para tocar o buzzer/ ativar som do alarme
aux			res 1 ; ====> Variavel que liga e desliga alarme


inicio    
	;========== Declaração do sistema ==============;
	banksel 	TRISD
	movlw 		00000000b
	movwf 		TRISD
	movlw		00000000b ;0 - saída 1- entrada
	movwf		TRISA
	movlw		00111111b ;0 - saída 1- entrada
	movwf		TRISB
	movlw		6
	movwf		ADCON1
	movlw		00000000b
	movwf 		TRISC

	banksel 	PORTD
	clrf		PORTD
	clrf		PORTA
	clrf		PORTB
; ==================== Limpeza de variáveis=========
	clrf		u_seg
	clrf		d_seg
	clrf 		u_min
	clrf 		d_min
	clrf 		w_temp
	clrf 		s_temp

	banksel 	T1CON
	movlw		00110001b
	movwf		T1CON

	banksel		PIE1
	bsf			PIE1,TMR1IE	

	banksel		INTCON
	bsf			INTCON,PEIE
	bsf			INTCON,GIE
	
	clrf		TMR1L
	clrf		TMR1H
	clrf		flags
	clrf		incre
	clrf		displ
	clrf		d_alarmeH
	clrf		u_alarmeH
	clrf		d_alarmeM
	clrf		u_alarmeM
	clrf		toca
	clrf		aux
	clrf		rb4

loop

	
	;===========Loop principal====================;
	
	call 		define	; =======> Funcao: Mostrar qual display sera exibido no momento: Ex; Ajuste,HH:MM,MM:SS.

	call 		seg		; =======> Funcao: Contar o tempo.

	pageselw	botao
	call 		botao	; =======> Funcao: Funcionamento dos botoes
	clrf		PCLATH



	pageselw	ajustar
	call 		ajustar	; =======>: Funcao: Ajustar Relógio
	clrf		PCLATH

	pageselw	ajustarAlarme
	call 		ajustarAlarme ; =======> Funcao: Incremento/Decremento Alarme	
	clrf		PCLATH


	call 		alarme	; =======> Funcao: Funcionamento do alarme

	
	
	goto 	loop
	;==========Fim do loop principal

bcd_7seg	

	;============> Definição do display
	addwf PCL,f
	retlw	00111111b;0
	retlw	00000110b;1
	retlw	01011011b;2
	retlw	01001111b;3
	retlw	01100110b;4
	retlw	01101101b;5
	retlw	01111101b;6
	retlw	00000111b;7
	retlw	01111111b;8
	retlw	01100111b;9
	retlw	00000000b;

	return

seg
	; ========> Essa parte funciona toda a estrutura do contador de contagem, tanto de segundo, minutos, horas..
	clrc

	rrf		u_seg,w
	xorlw	10
	btfss	STATUS,Z
	goto	$+3
	clrf	u_seg
	incf 	d_seg,f
	
	movf 	d_seg,w
	xorlw	6		; Teste se os segundos chegaram em 60, caso verdade, limpa a variavel d_seg e +1 no u_min
	btfss	STATUS,Z
	goto	$+3
	clrf	d_seg
	incf	u_min,f
	

	movf 	u_min,w
	xorlw	10		; Teste se a unidade de minutos chegaram em 10, caso verdade, limpa a variavel u_min e +1, d_min
	btfss	STATUS,Z
	goto 	$ + 3
	clrf	u_min
	incf	d_min,f

	movf	d_min,w
	xorlw	6		; Testa se a dezena de minutos chegou em 6, caso verdade, limpa a variavel d_min, +1 u_hor
	btfss	STATUS,Z
	goto 	$ + 3
	clrf	d_min
	incf	u_hor,f

	movf	d_hor,w 	;Teste se D_HOR é igual 2
	xorlw	2
	btfss	STATUS,Z	; Se dezena nao for 2, não skip e vai pro goto
	goto	$ + 7

	movf	u_hor,w
	xorlw	4			; Testa de a U_HOR é igual a 4
	btfss	STATUS,Z	; Vai pra incremento da unidade
	goto	$+3
	clrf	u_hor
	clrf	d_hor


	movf	u_hor,w
	xorlw	10		; Se unidade de hora chegar em 10, caso verdadem limpa a variavel u_hor e +1 d_hor
	btfss	STATUS,Z
	goto	$+3
	clrf	u_hor
	incf	d_hor,f

	

	
	return

inter

	movwf	w_temp
	swapf	STATUS,w
	movwf	s_temp 	
	
	bcf		PIR1,TMR1IF
	movf	incre,w ;============ Caso a variavel incre (modo ajuste) for diferente de zero, o contador para.
	xorlw	0
	btfss	STATUS,Z
	goto	$+2
	incf	u_seg,f

	nop
	nop
	nop	

	
	movlw	3038/256
	movwf	TMR1H
	movlw	3038%256
	movwf 	TMR1L


	movlw	00000001b ;========= Flags que pisca no display
	xorwf	flags,f
	
	
	;========Restaurando o contexto========:	
	swapf	s_temp,w
	movwf	STATUS	
	swapf	w_temp,f
	swapf	w_temp,w

	retfie
	
rell
	; ===========> Relógio de Minutos e Segundos MM:SS;
	clrc
					;Obs: O delay2 chamado a cada instante e para fazer a ilusao de todos os display's piscarem ao mesmo instante.
	bcf 	PORTA,5
	movf 	d_min,w
	call 	bcd_7seg
	movwf 	PORTD
	bsf 	PORTA,2  ;=====>Mostra a dezena de minutos no d1
	
	call 	delay2

	bcf		PORTA,2
	movf 	u_min,w
	call 	bcd_7seg
	movwf	PORTD
	bsf		PORTA,3  ;======>Mostra a unidade de minutos no d2
	
	btfss	flags,0
	bcf		PORTD,7	;=====> Flag's centrais
	btfsc	flags,0
	bsf		PORTD,7
	
	call 	delay2

	bcf 	PORTA,3
	movf 	d_seg,w
	call	bcd_7seg
	movwf	PORTD
	bsf		PORTA,4  ;======>Mostra a dezena de seg no d3

	call 	delay2

	clrc
	bcf		PORTA,4
	rrf		u_seg,w
	call	bcd_7seg
	movwf	PORTD
	bsf		PORTA,5  ;======>Mostra a uniddade de seg no d4

	btfss	flags,1
	bcf		PORTD,7;=======Flag's do modo alarme setado
	btfsc	flags,1
	bsf		PORTD,7
	
	call 	delay2
	
	return
	org	100h
rell2
	;========> Relógio de Horas e minutos;
	clrc

	bcf 	PORTA,5
	movf 	d_hor,w
	call 	bcd_7seg
	movwf 	PORTD
	bsf 	PORTA,2 ;=========Mostra a dezena de hr no d1
	
	call 	delay2

	bcf		PORTA,2
	movf 	u_hor,w
	call 	bcd_7seg
	movwf	PORTD
	bsf		PORTA,3 ;======Mostra a unidade de hr no d2

	btfss	flags,0
	bcf		PORTD,7	;=====> Flag's centrais
	btfsc	flags,0
	bsf		PORTD,7
	
	call 	delay2

	bcf 	PORTA,3
	movf 	d_min,w
	call	bcd_7seg
	movwf	PORTD
	bsf		PORTA,4 ;========Mostra a dezena de seg no d3

	call 	delay2

	bcf		PORTA,4
	movf	u_min,w
	call	bcd_7seg
	movwf	PORTD
	bsf		PORTA,5 ;=======Mostra a uniddade de seg no d4
	
	btfss	flags,1
	bcf		PORTD,7;=======Flag's do modo alarme setado
	btfsc	flags,1
	bsf		PORTD,7
	
	call 	delay2

	return
	
	
	
	
delay2 	;================DELAY 0.5s==========

	#define X 500

	movlw 	X%256
	movwf 	temp+1
	movlw 	X/256+1
	movwf 	temp

	nop
	nop
	nop
	nop
	nop

	decf 	temp+1,f
	btfsc 	STATUS,Z
	decfsz 	temp,f
	goto	$ - 8

	return
define ; ========= Essa função define o que vai ser mostrado no  display ====;

	movf 	incre,w
	xorlw	0			;=====> Se a variável de modo ajuste for diferente de zero vai para o "call goto"
	btfsc	STATUS,Z
	goto	$+2
	goto 	ajuste
	
;=========================================================================;
	movf 	displ,w
	xorlw	00000000b
	btfss	STATUS,Z
	goto	$+2
	goto 	rell2  ;========= Relogio no modeo HH:MM

	movf 	displ,w
	xorlw	00000001b
	btfss	STATUS,Z
	goto	$+2
	goto 	rell ;========== Relogio no modo MM:SS

	return


botao
; ======== Ajuste da função do display

	btfsc 	PORTB,0
	goto	$ + 8
	btfss	PORTB,0
	goto	$-1
	incf	incre,f
	movf	incre,w
	xorlw	9		;======= Quando a variavel incre for 9 vai limpar a variável incre
	btfsc	STATUS,Z
	clrf	incre

; ========= Ajuste de HH:MM para MM:SS


	movlw	00000001b
	btfsc	PORTB,3
	goto	$+4
	btfss	PORTB,3
	goto	$-1
	xorwf	displ,f

;========	Liga/Desliga alarme
	movlw	00000001b
	btfsc	PORTB,5
	goto	$+6
	btfss	PORTB,5
	goto	$-1
	xorwf	aux,f
	movlw	00000010b;========== Ativação do ponto no display
	xorwf	flags,f
	
	
;=======	Silencia alarme
	btfsc	PORTB,4
	goto	$+4
	btfss	PORTB,4
	goto	$-1
	bcf		rb4,0

	
	return
	
ajuste
	
;======= Nessa parte temos a configuração das horas e minutos do relogio modo ajuste======;
	bcf			PORTA,5
	bcf			PORTA,4
	bcf			PORTA,3
	bcf			PORTA,2
	clrc	
	movf		incre,w	
	xorlw		1		;========== Quando a variavel incre for 1
	btfss		STATUS,Z
	goto		$+8
	bcf			PORTA,5
	bcf			PORTA,4
	bcf			PORTA,3
	bsf			PORTA,2	;========== Apaga todos os display e acende apenas o primeiro para mostrar a dezena de horas que vai ser alterada
	movf		d_hor,w
	call		bcd_7seg
	movwf		PORTD
	

	movf		incre,w
	xorlw		2		;========== Quando a variavel incre for 2
	btfss		STATUS,Z
	goto		$+8
	bcf			PORTA,5
	bcf			PORTA,4
	bcf			PORTA,2	;========== Apaga todos os display e acende apenas o segundo para mostrar a unidade de horas que vai ser alterada
	movf		u_hor,w
	call		bcd_7seg
	movwf		PORTD
	bsf			PORTA,3

	movf		incre,w
	xorlw		3		;========== Quando a variavel incre for 3
	btfss		STATUS,Z
	goto		$+8
	bcf			PORTA,5
	bcf			PORTA,2
	bcf			PORTA,3	;========== Apaga todos os display e acende apenas o terceiro para mostrar a dezena de minutos que vai ser alterada
	movf		d_min,w
	call		bcd_7seg
	movwf		PORTD
	bsf			PORTA,4

	movf		incre,w
	xorlw		4		;========== Quando a variavel incre for 4
	btfss		STATUS,Z
	goto		$+8
	bcf			PORTA,2
	bcf			PORTA,3
	bcf			PORTA,4	;========== Apaga todos os display e acende apenas o quarto para mostrar a unidade de minutos que vai ser alterada
	movf		u_min,w
	call		bcd_7seg
	movwf		PORTD
	bsf			PORTA,5
;====== Nessa parte é o ajuste do alarme a ser configurado. =====
	movf		incre,w
	xorlw		5		;========== Quando a variavel incre for 5
	btfss		STATUS,Z
	goto		$+9
	bcf			PORTA,2
	bcf			PORTA,5
	bcf			PORTA,4
	bcf			PORTA,3
	bsf			PORTA,2	;========== Apaga todos os display e acende apenas o primeiro para mostrar a dezena de horas que vai ser alterada
	movf		d_alarmeH,w
	call		bcd_7seg
	movwf		PORTD


	movf		incre,w
	xorlw		6		;========== Quando a variavel incre for 6
	btfss		STATUS,Z
	goto		$+8
	bcf			PORTA,5
	bcf			PORTA,4
	bcf			PORTA,2	;========== Apaga todos os display e acende apenas o segundo para mostrar a unidade de horas que vai ser alterada
	movf		u_alarmeH,w
	call		bcd_7seg
	movwf		PORTD
	bsf			PORTA,3
	
	movf		incre,w
	xorlw		7		;========== Quando a variavel incre for 7
	btfss		STATUS,Z
	goto		$+8
	bcf			PORTA,5
	bcf			PORTA,2
	bcf			PORTA,3	;========== Apaga todos os display e acende apenas o terceiro para mostrar a dezena de minutos que vai ser alterada
	movf		d_alarmeM,w
	call		bcd_7seg
	movwf		PORTD
	bsf			PORTA,4

	movf		incre,w
	xorlw		8		;========== Quando a variavel incre for 8
	btfss		STATUS,Z
	goto		$+8
	bcf			PORTA,2
	bcf			PORTA,3
	bcf			PORTA,4	;========== Apaga todos os display e acende apenas o quarto para mostrar a unidade de minutos que vai ser alterada
	movf		u_alarmeM,w
	call		bcd_7seg
	movwf		PORTD
	bsf			PORTA,5


	return
	
	org 200h
ajustar   ;	Essa função que realmente altera os valores:
	clrc
	; Incrementa na dezena de horas
	movf		incre,w
	xorlw		1
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		@3		
	btfsc		PORTB,2		
	goto		@3
	btfss		PORTB,2
	goto		$-1

	movf		d_hor,w		
	xorlw		2			; Faz o teste para não exceder o valor 2 em horas
	btfss		STATUS,Z	; Z=1 o código pula
	goto		$+2
	goto		@3
	movf		u_hor,w		; Nessa parte é a configuracao para nao deixar colocar o valor diferente de 23 no display.
	xorlw		3			; Faz um teste em cada variavel para caso a dezena de horas for 2, a unidade de hora nao pode ter nenhum valor 
	btfsc		STATUS,Z	; acima de 3, caso tenha, zera a varivel de unidade de hora e incrementa, caso apertado, na variavel de dezena
	goto 		@H
	movf		u_hor,w
	xorlw		2
	btfsc		STATUS,Z
	goto 		@H
	movf		u_hor,w
	xorlw		1
	btfsc		STATUS,Z
	goto 		@H
	movf		u_hor,w
	xorlw		0
	btfsc		STATUS,Z
	goto 		@H
	clrf		u_hor
@H	incf		d_hor,f

	; Incrementa na unidade de horas
@3	movf		incre,w
	xorlw		2
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+17			
	btfsc		PORTB,2		
	goto		$+15
	btfss		PORTB,2
	goto		$-1
	movf		d_hor,w		
	xorlw		2			; Faz o teste para não exceder o valor 2 em horas
	btfss		STATUS,Z	; Z=1 o código pula
	goto		$ + 5
	movf		u_hor,w
	xorlw		3			; Se a unidade de hora for 3 ele vai pro goto e nao incrementa
	btfsc		STATUS,Z
	goto		$ + 5
	movf		u_hor,w
	xorlw		9			; Não deixa passar de 9
	btfss		STATUS,Z
	incf		u_hor,f
	
	; Incrementa na dezena de minutos
	movf		incre,w
	xorlw		3
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,2		
	goto		$+7
	btfss		PORTB,2
	goto		$-1
	movf		d_min,w		
	xorlw		5			; Faz o teste para não exceder o valor 9 em dezenas de minutos
	btfss		STATUS,Z	; Z=1 o código pula
	incf		d_min,f

	; Incrementa na unidade de minutos
	movf		incre,w
	xorlw		4
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,2		
	goto		$+7
	btfss		PORTB,2
	goto		$-1
	movf		u_min,w		
	xorlw		9			; Faz o teste para não exceder o valor 9 unidade dm minutos
	btfss		STATUS,Z	; Z=1 o código pula
	incf		u_min,f
	; Decremento na dezena de horas
	movf		incre,w
	xorlw		1
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,1		
	goto		$+7
	btfss		PORTB,1
	goto		$-1
	movf		d_hor,w		
	xorlw		0			; Faz o teste para não exceder o valor 0 de unidade de hora
	btfss		STATUS,Z	; Z=1 o código pula
	decf		d_hor,f
	; Decremento na unidade de horas
	movf		incre,w
	xorlw		2
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+17			
	btfsc		PORTB,1		
	goto		$+15
	btfss		PORTB,1
	goto		$-1
	movf		d_hor,w		
	xorlw		2			; Faz o teste para não exceder o valor 2 em horas
	btfss		STATUS,Z	; Z=1 o código pula
	goto		$ + 5
	movf		u_hor,w
	xorlw		0			; Se a unidade de hora for diferente 0 ele vai pro goto
	btfsc		STATUS,Z
	goto		$ + 5
	movf		u_hor,w
	xorlw		0			; Não deixa passar de 9
	btfss		STATUS,Z
	decf		u_hor,f
	; Decremento na dezena de minutos
	movf		incre,w
	xorlw		3
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,1		
	goto		$+7
	btfss		PORTB,1
	goto		$-1
	movf		d_min,w		
	xorlw		0			; Faz o teste para não exceder o valor 0 em dezenas de minutos ( Caso acontecesse o display apagava)
	btfss		STATUS,Z	; Z=1 o código pula
	decf		d_min,f
	; Decremento na unidade de minutos
	movf		incre,w
	xorlw		4
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,1		
	goto		$+7
	btfss		PORTB,1
	goto		$-1
	movf		u_min,w		
	xorlw		0			; Faz o teste para não exceder o valor 9 unidade dm minutos
	btfss		STATUS,Z	; Z=1 o código pula
	decf		u_min,f
	

	return
	org 300h
ajustarAlarme
	clrc
	bcf			PORTB,2
	bcf			PORTB,1
		; Incrementa na dezena de horas
	movf		incre,w
	xorlw		5
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		@4			
	btfsc		PORTB,2		
	goto		@4
	btfss		PORTB,2
	goto		$-1
	movf		d_alarmeH,w		
	xorlw		2			; Faz o teste para não exceder o valor 2 em horas
	btfss		STATUS,Z	; Z=1 o código pula
	goto		$+2
	goto		@4
	movf		u_alarmeH,w
	xorlw		3
	btfsc		STATUS,Z
	goto 		@H2
	movf		u_alarmeH,w
	xorlw		2
	btfsc		STATUS,Z
	goto 		@H2
	movf		u_alarmeH,w
	xorlw		1
	btfsc		STATUS,Z
	goto 		@H2
	movf		u_alarmeH,w
	xorlw		0
	btfsc		STATUS,Z
	goto 		@H2
	clrf		u_alarmeH
@H2	incf		d_alarmeH,f

	; Incrementa na unidade de horas
@4	movf		incre,w
	xorlw		6
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+17			
	btfsc		PORTB,2		
	goto		$+15
	btfss		PORTB,2
	goto		$-1
	movf		d_alarmeH,w		
	xorlw		2			; Faz o teste para não exceder o valor 2 em horas
	btfss		STATUS,Z	; Z=1 o código pula
	goto		$ + 5
	movf		u_alarmeH,w
	xorlw		3			; Se a unidade de hora for 3 ele vai pro goto que zera
	btfsc		STATUS,Z
	goto		$ + 5
	movf		u_alarmeH,w
	xorlw		9			; Não deixa passar de 9
	btfss		STATUS,Z
	incf		u_alarmeH,f
	
	; Incrementa na dezena de minutos
	movf		incre,w
	xorlw		7
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,2		
	goto		$+7
	btfss		PORTB,2
	goto		$-1
	movf		d_alarmeM,w		
	xorlw		5			; Faz o teste para não exceder o valor 9 em dezenas de minutos
	btfss		STATUS,Z	; Z=1 o código pula
	incf		d_alarmeM,f

	; Incrementa na unidade de minutos
	movf		incre,w
	xorlw		8
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,2		
	goto		$+7
	btfss		PORTB,2
	goto		$-1
	movf		u_alarmeM,w		
	xorlw		9			; Faz o teste para não exceder o valor 9 unidade dm minutos
	btfss		STATUS,Z	; Z=1 o código pula
	incf		u_alarmeM,f
	; Decremento na dezena de horas
	movf		incre,w
	xorlw		5
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,1		
	goto		$+7
	btfss		PORTB,1
	goto		$-1
	movf		d_alarmeH,w		
	xorlw		0			; Faz o teste para não exceder o valor 0 unidade de hora
	btfss		STATUS,Z	; Z=1 o código pula
	decf		d_alarmeH,f
	; Decremento na unidade de horas
	movf		incre,w
	xorlw		6
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+17			
	btfsc		PORTB,1		
	goto		$+15
	btfss		PORTB,1
	goto		$-1
	movf		d_alarmeH,w		
	xorlw		2			; Faz o teste para não exceder o valor 2 em horas
	btfss		STATUS,Z	; Z=1 o código pula
	goto		$ + 5
	movf		u_alarmeH,w
	xorlw		0			; Se a unidade de hora for diferente 0 ele vai pro goto que zera
	btfsc		STATUS,Z
	goto		$ + 5
	movf		u_alarmeH,w
	xorlw		0			; Não deixa passar de 0
	btfss		STATUS,Z
	decf		u_alarmeH,f
	; Decremento na dezena de minutos
	movf		incre,w
	xorlw		7
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,1		
	goto		$+7
	btfss		PORTB,1
	goto		$-1
	movf		d_alarmeM,w		
	xorlw		0			; Faz o teste para não exceder o valor 0 em dezenas de minutos ( Caso acontecesse o display apagava)
	btfss		STATUS,Z	; Z=1 o código pula
	decf		d_alarmeM,f
	; Decremento na unidade de minutos
	movf		incre,w
	xorlw		8
	btfss		STATUS,Z	; Se for Z=0, pula e vai para o próximo teste
	goto		$+9			
	btfsc		PORTB,1		
	goto		$+7
	btfss		PORTB,1
	goto		$-1
	movf		u_alarmeM,w		
	xorlw		0			; Faz o teste para não exceder o valor 9 unidade dm minutos
	btfss		STATUS,Z	; Z=1 o código pula
	decf		u_alarmeM,f
	

	return
	
alarme
;================ Funcionamento da estrutura do alarme =========;

	
	movf	aux,w
	xorlw	00000000b	;Caso a variavel do alarme estiver zerada
	btfss	STATUS,Z	; pula pro fim do código
	goto	$+5
	bcf		PORTB,6
	clrf	toca
	bcf		PORTC,1
	goto	@r

	movf	aux,w		; Caso a variavel do alarme o ultimo bit for 1
	xorlw	00000001b	; Entra na parte do codigo de comparacao para tocar alarme
	btfss	STATUS,Z
	goto	@1
	clrf	toca
	bsf		PORTB,6
	
	movf	d_hor,w
	xorwf	d_alarmeH,w	; Verifica se d_hor e igual d_alarmeH
	btfss	STATUS,Z
	goto	$+17
	incf	toca,f
	
	movf	u_hor,w
	xorwf	u_alarmeH,w	; Verifica se u_hor e igual u_alarmeH
	btfss	STATUS,Z
	goto	$+12
	incf	toca,f
	
	movf	d_min,w
	xorwf	d_alarmeM,w	; Verifica se d_min e igual d_alarmeM
	btfss	STATUS,Z
	goto	$+7
	incf	toca,f
	
	movf	u_min,w
	xorwf	u_alarmeM,w	; Verifica de u_min e igual u_alarmeH
	btfss	STATUS,Z
	goto	$+2
	incf	toca,f

	movf	d_seg,w
	xorwf	0,w		; Verifica se a d_seg esta em zero para atualizar o buzzer
	btfss	STATUS,Z
	goto	$+2
	incf	toca,f

	movf	u_seg,w
	xorwf	0,w		; Verifica se a d_seg esta em zero para atualizar o buzzer
	btfss	STATUS,Z
	goto	$+2
	incf	toca,f
	
@1	movf	toca,w
	xorlw	6
	btfss	STATUS,Z	; Se a variavel toca for 6, o bit da porta rb4 e setado e com isso ativa o buzzer
	goto	$+2
	bsf		rb4,0
	

	btfss	rb4,0
	bcf		PORTC,1		; Funcao que faz rb4, ou seja, ativa ou desativa som
	btfsc	rb4,0
	bsf		PORTC,1
	


@r	return
	
	end	
 