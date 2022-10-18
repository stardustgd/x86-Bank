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
			  "4. Print log of previous transactions", newLine,
			  "5. Log out", endl
	goodbyeText BYTE "Thank you for banking with us.", endl

	depositString BYTE "Deposit", endl
	withdrawString BYTE "Withdraw", endl
	interestString BYTE "Interest", endl
	printLogString BYTE "Print log", endl

	databaseFile BYTE "database.txt"
	fileHandle DWORD ?

.code
main PROC
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

printMenu PROC
	mov edx, OFFSET menu
	call WriteString

	ret
printMenu ENDP

initializeDatabase PROC
	; mov edx, OFFSET databaseFile
	; call CreateOutputFile
	; mov fileHandle, eax

	; mov edx, OFFSET databaseFile
	; mov ecx, LENGTHOF databaseFile
	; call WriteToFile

	; call CloseFile

	ret
initializeDatabase ENDP

Deposit PROC
	mov edx, OFFSET depositString
	call WriteString

	ret
Deposit ENDP

Withdraw PROC
	mov edx, OFFSET withdrawString
	call WriteString

	ret
Withdraw ENDP

Interest PROC
	mov edx, OFFSET interestString
	call WriteString

	ret
Interest ENDP

PrintLog PROC
	mov edx, OFFSET printLogString
	call WriteString

	ret
PrintLog ENDP

END main