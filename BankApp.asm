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

	fileHandle HANDLE ?
	bytesWritten dd ?
	bytePosition dd ?

	currentUser User <>

.code
main PROC
	call initializeDatabase

login_loop:										; Repeat login prompt if login fails
	call Clrscr
	call loginMenu
	call verifyLogin

	cmp eax, 0
	je exit_loop 

	call WaitMsg
	jmp login_loop
	
exit_loop:
	call Clrscr
	mov edx, OFFSET welcomeText
	call WriteString

L1:												; Main program loop
	call printMenu

	cmp eax, -1
	je exit_program

	call DumpRegs

	call Clrscr
	jmp L1

exit_program::
	call Clrscr
	mov edx, OFFSET goodbyeText
	call WriteString

	exit
main ENDP
END main