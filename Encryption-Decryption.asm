.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern printf: proc
extern scanf:proc
extern fopen:proc
extern fread:proc
extern fclose:proc
extern fwrite:proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
cheie dq 5 
chr db "a",0
text db 1000 dup (?)
format_s db "%s",0
format_c db " %c",0
format_d db "%d",0
msg_sf db "Operatiile cerute au fost efectuate",0
msg1 db "Dati calea catre fisier: ",0
msg2 db "Alegeti algoritmul (1/2): ",0
msg3 db "Alegeti operatia (1=criptare /2=decriptare): ",0
msg4 db "Dati cheie de criptare: ",0
mod_c db "r",0
mod_s db "w",0
alg db 1 ;1=>algoritm1 2=>algoritm2 
opt db 1 ;1=criptare 2=decriptare
l dd ?
f dd ? ;f=pointer spre fisier
caleFisier db ?
.code

criptare1 proc
	not al
	inc al
	add al,byte ptr cheie
	ret
criptare1 endp

decriptare1 proc
	sub al,byte ptr cheie
	dec al
	not al
	ret
decriptare1 endp

criptare2 proc
	not edx
	inc edx
	not eax
	inc eax
	jno sf_complementare
    inc edx
	sf_complementare:
	lea ecx,cheie
	xor edx,[ecx]
	add ecx,4
	xor eax,[ecx]
	ret
criptare2 endp

decriptare2 proc
	lea ecx,cheie
	xor edx,[ecx]
	add ecx,4
	xor eax,[ecx]
	cmp eax,0 ;verificare underflow
	jne sf_xor
	dec edx
	sf_xor:
	dec edx
	not edx
	dec eax
	not eax
	ret
decriptare2 endp

start:

	push offset msg1
	push offset format_s
	call printf
	add esp,8;s-a printat msj 1
	
	push offset caleFisier
	push offset format_s
	call scanf
	add esp,8; s-a citit nume fisier
		
	push offset msg2
	push offset format_s
	call printf
	add esp,8;s-a printat msj 2
	
	push offset alg
	push offset format_c
	call scanf
	add esp,8; s-a citit nr alg

	push offset msg3
	push offset format_s
	call printf
	add esp,8;s-a printat msj 3
	
	push offset opt
	push offset format_c
	call scanf
	add esp,8; s-a citit optiunea criptare/decriptare 
	
	push offset msg4
	push offset format_s
	call printf
	add esp,8;s-a printat msj 4
				
	push offset cheie
	push offset format_d
	call scanf
	add esp,8; s-a citit cheia de criptare 		
	
    push offset mod_c
	push offset caleFisier
	call fopen
	add esp,8 ;s-a deshis fisierul pt citire
	mov f,eax ;f=pointerul spre fisier
		
	mov edi,0
	push f ;stream 
	push 1 ;count
	push 1 ;size
	push offset chr
citire:; citire 
	call fread 
	test eax, eax
	jz inchidere_fisier
	mov al, chr
	mov text[edi],al
	inc edi
	;verificare citire
	;push offset chr
	;push offset format_s
	;call printf
	;add esp,8	
	jmp citire	
	
	inchidere_fisier: ;inchidere fisier dupa citire
	add esp, 16 ;curatam stiva de la fread
	mov l,edi ; salvam lungime fisier in l
	push f ;stream
	call fclose 
	add esp, 4	
		
	cmp alg,"1"
	jz et_alg1				
	cmp opt,"1"    ;alg=2
	jz et_alg2_c 
	
	;;decriptare2
	;;intializare indecsi
	mov esi,0
	mov edi,0
	sub l,8
	bucla_decriptare2:
	;;pregatire registrii pentru apel decriptare2
	mov edx,dword ptr text[esi]
	add esi,4
	mov eax,dword ptr text[esi]
	add esi,4
	;;apel criptare(edx,eax)
	call decriptare2
	;;salvare date decriptate in string
	mov dword ptr text[edi],edx
	add edi,4
	mov dword ptr text[edi],eax
	add edi,4
	cmp l,edi
	jae bucla_decriptare2 ;daca nr de caractere nu se imparte exact la 8,ultimele caractere (max 7) nu sunt decriptate(nici nu au fost criptate)
    ;verificare decriptare2
	;push offset text
	;push offset format_s
	;call printf
	;add esp,8
	add l,8 ;refacem l pt scriere
	jmp scriere
	
	et_alg2_c:	
  	;;criptare2 
	;;intializare indecsi
	mov esi,0
	mov edi,0
	sub l,8
	bucla_criptare2:
	;;pregatire registrii pentru apel criptare2
	mov edx,dword ptr text[esi]
	add esi,4
	mov eax,dword ptr text[esi]
	add esi,4
	;;apel criptare(edx,eax)
	call criptare2
	;;salvare date criptate in string
	mov dword ptr text[edi],edx
	add edi,4
	mov dword ptr text[edi],eax
	add edi,4
	cmp l,edi
	jae bucla_criptare2 ;daca nr de caractere nu se imparte exact la 8,ultimele caractere (max 7) nu sunt criptate
    ;verificare criptare2
	;push offset text
	;push offset format_s
	;call printf
	;add esp,8
	add l,8 ;refacem l pt scriere
	jmp scriere
	
	et_alg1:  
	CMP opt,"1" ;
	jz et_alg1_c	
	;;alg=1  opt=2 =>decriptare1
	;;se ia chr din text si decripteaza unul cate unul
	mov edi,0
	bucla_decriptare1:
	mov al,text[edi]
	call decriptare1
	mov text[edi],al
	inc edi
	;verificare decriptare corecta
	;mov chr,al
	;push offset chr
	;push offset format_s
	;call printf
	;add esp,8	
	cmp edi,l
	jnz bucla_decriptare1
	jmp scriere
	
	et_alg1_c:
	;;se ia chr din text si criptate unul cate unul
	mov edi,0	
	bucla_criptare1:
	mov al,text[edi]
	call criptare1
	mov text[edi],al
	inc edi
	;verificare criptare corecta
	;mov chr,al
	;push offset chr
	;push offset format_s
	;call printf
	;add esp,8	
	cmp edi,l
	jnz bucla_criptare1
	
	scriere:
	;;scriere in fisier date criptate
	;;deschidere fisier in mod pt scriere
	push offset mod_s
	push offset caleFisier
	call fopen
	add esp,8 ;curatare stiva dupa fopen
	mov f,eax ;f=pointerul spre fisier
		
	mov edi,0
	mov al,text[edi]
	mov chr,al	
	push f ;stream 
	push 1 ;count
	push 1 ;size
	push offset chr
bucla_scriere:
	call fwrite
	inc edi
	mov al,text[edi]
	mov chr,al
	cmp edi,l
	jnz bucla_scriere
	
	inchidere_fisier2:  ;;inchidere fisier dupa scriere 
	add esp, 16 ;curatam stiva de la fwrite
	mov l,edi ; salvam lungime fisier in l
	push f ;stream
	call fclose 
	add esp, 4
		
	sf:
	;;;;;;;;; verificare ca a ajuns aici
	push offset msg_sf
	push offset format_s
	call printf
	add esp,8;s-a printat msj
	;;;;;;;;;;;;;;
	
	;terminarea programului
	push 0
	call exit
end start
