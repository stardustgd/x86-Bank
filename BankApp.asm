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

    databaseFile BYTE "database.txt"
    fileHandle DWORD ?

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

initializeDatabase PROC
    mov edx, OFFSET databaseFile
    call CreateOutputFile
    mov fileHandle, eax

    mov edx, OFFSET databaseFile
    mov ecx, LENGTHOF databaseFile
    call WriteToFile

    call CloseFile

    ret
END main