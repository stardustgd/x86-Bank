; Authors: Sebastian Ala Torre,
;		   Conan Nguyen,
;		   Samuel Segovia,
;		   Austen Bernal,
;		   Bernardo Flores
; Class: CIS123 Assembly Language
; File Name: BankApp.asm
; Creation Date: 10/16/22
; Program Description: TODO

INCLUDE Irvine32.inc

.const
	endl EQU <0dh, 0ah, 0>
	newLine EQU <0dh, 0ah>

.data
	welcomeText BYTE "Welcome to Bank of the Universe!", endl
	menu BYTE "Please select an option:", newLine,
			  "1. Deposit Money", newLine,
			  "2. Withdraw Money", newLine,
			  "3. Calculate Interest", newLine,
			  "4. Print log of previous transactions", endl

.code
main PROC
	mov edx, OFFSET welcomeText
	call WriteString

L1:
	call printMenu
	call ReadInt

	cmp eax, -1
	jne L1

	exit
main ENDP

printMenu PROC
	mov edx, OFFSET menu
	call WriteString

	ret
printMenu ENDP
END main