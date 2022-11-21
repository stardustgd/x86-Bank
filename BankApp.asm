; Authors: Sebastian Ala Torre,
;		   Conan Nguyen,
;		   Samuel Segovia,
;		   Austen Bernal,
;		   Bernardo Flores
; Class: CIS123 Assembly Language
; File Name: BankApp.asm
; Creation Date: 10/16/22
; Program Description: TODO

INCLUDE BankApp.inc

.data
	welcomeText db "Welcome to the x86 Bank!", endl
	goodbyeText db "Thank you for banking with us.", endl
  
	currentUser User <>

.code
main PROC
	call InitializeDatabase

login_loop:										; Repeat login prompt if login fails
	call Clrscr
	call LoginMenu
	call VerifyLogin

	cmp eax, 0									; Leave loop if a valid login is entered
	je exit_loop

	cmp eax, -1									; Exit program if user doesn't want to register
	je exit_program 

	call WaitMsg
	jmp login_loop
	
exit_loop:
	INVOKE InitializeStruct, 
		ADDR currentUser.userUsername,
		ADDR currentUser.userPassword, 
		ADDR currentUser.userBalance,
		ADDR currentUser.bytePosition

	call Clrscr
	mov edx, OFFSET welcomeText
	call WriteString

L1:												; Main program loop
	INVOKE PrintMenu, ADDR currentUser

	cmp eax, -1
	je exit_program

	call Clrscr
	jmp L1

exit_program:
	call Clrscr
	mov edx, OFFSET goodbyeText
	call WriteString

	INVOKE Sleep, 1000							; Wait 2s before terminating

	exit
main ENDP
END main