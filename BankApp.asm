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
	fileHandle DWORD ?

.code
main PROC
	call initializeDatabase
	mov edx, OFFSET welcomeText
	call WriteString

; L1:
; 	call printMenu
; 	call ReadInt

; 	cmp eax, 1
; 	je L2

; 	cmp eax, 2
; 	je L3

; 	cmp eax, 3
; 	je L4

; 	cmp eax, 4
; 	je L5

; 	cmp eax, 5
; 	je Logout

; L2:
; 	call Deposit
; 	jmp L1

; L3:
; 	call Withdraw
; 	jmp L1

; L4:
; 	call Interest
; 	jmp L1

; L5:
; 	call PrintLog
; 	jmp L1

; Logout:
; 	mov edx, OFFSET goodbyeText
; 	call WriteString

	exit
main ENDP

;----------------------------------------------------
printMenu PROC
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
	push edx

	mov edx, OFFSET menu
	call WriteString

	pop edx
	ret
printMenu ENDP

;----------------------------------------------------
initializeDatabase PROC
;
; Creates a database file if one doesn't exist.
; Recieves: nothing
; Returns: nothing 
;----------------------------------------------------
.data
	initializingMessage BYTE "Initializing database....", newLine

.code
	mov edx, OFFSET databaseFile
	call OpenInputFile
	mov fileHandle, eax

	; Check if database already exists
	cmp eax, INVALID_HANDLE_VALUE
	je create_database
	
	mov fileHandle, eax
	jmp write_file

create_database:
	mov edx, OFFSET initializingMessage
	call WriteString

	mov edx, OFFSET databaseFile
	call CreateOutputFile

write_file:
	; Write to file
	mov edx, OFFSET initializingMessage
	mov ecx, LENGTHOF initializingMessage
	call WriteToFile
	call CloseFile

	ret
initializeDatabase ENDP

;----------------------------------------------------
Deposit PROC
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
Withdraw PROC
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
Interest PROC
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
PrintLog PROC
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