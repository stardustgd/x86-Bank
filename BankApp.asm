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
	goodbyeText BYTE "Thank you for banking with us.", endl

	depositString BYTE "Deposit", endl
	withdrawString BYTE "Withdraw", endl
	interestString BYTE "Interest", endl
	printLogString BYTE "Print log", endl

	databaseFile BYTE "database.txt",0
	fileHandle HANDLE ?

.code
main PROC
	call Clrscr
	call initializeDatabase

	call loginMenu
	
	mov edx, OFFSET welcomeText
	call WriteString

L1:
	call printMenu
	call ReadInt

	cmp eax, 1
	je L2

	cmp eax, 2
	je L3

	cmp eax, 3
	je L4

	cmp eax, 4
	je L5

	cmp eax, 5
	je Logout

L2:
	call Deposit
	jmp L1

L3:
	call Withdraw
	jmp L1

L4:
	call Interest
	jmp L1

L5:
	call PrintLog
	jmp L1

Logout:
	mov edx, OFFSET goodbyeText
	call WriteString

	exit
main ENDP

;----------------------------------------------------
loginMenu PROC USES edx
;
; Prints out a login screen for the user
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	usernameText db "Username: ", 0
	passwordText db "Password: ", 0

	userName db 21 DUP(?)

	userPass db 21 DUP(?)

	byteCount DWORD ?

.code
	mov edx, OFFSET usernameText
	call WriteString

	mov edx, OFFSET userName					; Prompt for username
	mov ecx, SIZEOF userName
	call ReadString

	; TODO: Need to get this to work
	; Go to where the null character is and insert a newline 
	mov byteCount, eax
	call WriteString

	INVOKE CreateFile, 							; Try to open database file
		ADDR databaseFile, GENERIC_WRITE, 
		DO_NOT_SHARE, NULL, OPEN_EXISTING, 
		FILE_ATTRIBUTE_NORMAL, 0

	mov fileHandle, eax

	INVOKE SetFilePointer,						; Move the fileHandle to the end of the file
		fileHandle, 0, 0, FILE_END

	INVOKE WriteFile,							; Write to the file
		fileHandle, ADDR userName, 
		byteCount, ADDR bytesWritten, 0

	mov eax, fileHandle
	call CloseFile

	ret

loginMenu ENDP


;----------------------------------------------------
printMenu PROC USES edx
;
; Print out a menu for the user to select options.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	menu BYTE "Please select an option:", newLine,
			  "1. Deposit Money", newLine,
			  "2. Withdraw Money", newLine,
			  "3. Calculate Interest", newLine,
			  "4. Print log of previous transactions", newLine,
			  "5. Log out", endl

.code
	mov edx, OFFSET menu
	call WriteString

	ret
printMenu ENDP

;----------------------------------------------------
initializeDatabase PROC USES eax
;
; Creates a database file if one doesn't exist.
; Recieves: nothing
; Returns: nothing 
;----------------------------------------------------
.data
	alreadyInitialized db "Database already initialized...", newLine
	bufferSize DWORD ($ - alreadyInitialized)
	bytesWritten DWORD ?

.code
	INVOKE CreateFile, 							; Try to open database file
		ADDR databaseFile, GENERIC_WRITE, 
		DO_NOT_SHARE, NULL, OPEN_EXISTING, 
		FILE_ATTRIBUTE_NORMAL, 0

	cmp eax, INVALID_HANDLE_VALUE				; Check if the file exists
	jne write_file								; If it does, write to the file

	mov edx, OFFSET databaseFile				; If it doesn't create one
	call CreateOutputFile
	jmp write_file

write_file:
	mov fileHandle, eax							; Save the file handle

	INVOKE SetFilePointer,						; Move the fileHandle to the end of the file
		fileHandle, 0, 0, FILE_END

	INVOKE WriteFile,							; Write to the file
		fileHandle, ADDR alreadyInitialized, 
		bufferSize, ADDR bytesWritten, 0

	mov eax, fileHandle
	call CloseFile

	ret
initializeDatabase ENDP

;----------------------------------------------------
Deposit PROC USES edx
;
; Allows the user to specify an amount of money
; that is added to their account balance.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
	mov edx, OFFSET depositString
	call WriteString

	ret
Deposit ENDP

;----------------------------------------------------
Withdraw PROC USES edx
;
; Allows the user to specify an amount of money
; that is subtracted from their account balance.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
	mov edx, OFFSET withdrawString
	call WriteString

	ret
Withdraw ENDP

;----------------------------------------------------
Interest PROC USES edx
;
; Calculates the user's accumulated interest
; using the formula: 
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
	mov edx, OFFSET interestString
	call WriteString

	ret
Interest ENDP

;----------------------------------------------------
PrintLog PROC USES edx
;
; Prints a log of the user's previous transactions.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
	mov edx, OFFSET printLogString
	call WriteString

	ret
PrintLog ENDP

END main