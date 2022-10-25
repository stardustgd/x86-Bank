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
	carriageReturn db 0ah
	endl EQU <0dh, 0ah, 0>
	newLine EQU <0dh, 0ah>

.data
	welcomeText db "Welcome to the x86 Bank!", endl
	goodbyeText db "Thank you for banking with us.", endl

	depositString db "Deposit", endl
	withdrawString db "Withdraw", endl
	interestString db "Interest", endl
	printLogString db "Print log", endl

	databaseFile db "database.txt",0
	fileHandle HANDLE ?
	bytesWritten dd ?

.code
main PROC
	call Clrscr
	call initializeDatabase

	call loginMenu
	
	mov edx, OFFSET welcomeText
	call WriteString

L1:												; Main program loop
	call Clrscr
	call printMenu
	jmp L1

exit_program::
	mov edx, OFFSET goodbyeText
	call WriteString

	exit
main ENDP

;----------------------------------------------------
loginMenu PROC USES edx
;
; User login screen that takes in a username and 
; password, then verifies that it matches with the
; database. 
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	usernamePrompt db "Username: ", 0
	passwordPrompt db "Password: ", 0

	userName db 21 DUP(?)
	userPass db 21 DUP(?)

	nameByteCount DWORD ?
	passByteCount DWORD ?

.code
	mov edx, OFFSET usernamePrompt				; Print username prompt
	call WriteString

	mov edx, OFFSET userName					; Prompt for username
	mov ecx, SIZEOF userName
	call ReadString

	mov nameByteCount, eax						; Store the amount of bytes read

	mov edx, OFFSET passwordPrompt				; Print passowrd prompt
	call WriteString

	mov edx, OFFSET userPass					; Prompt for password
	mov ecx, SIZEOF userPass
	call ReadString

	mov passByteCount, eax

	call verifyLogin
	ret

loginMenu ENDP

;----------------------------------------------------
verifyLogin PROC
;
; Opens the database file and checks if the 
; supplied username and password exists in the 
; database. If it doesn't, the username and password
; will be registered to the database.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data 
	errorMessage db "Couldn't open the file.", endl
	readError db "Couldn't read file.", endl

	BUFFER_SIZE = 5000
	buffer db BUFFER_SIZE DUP(?)
	bytesRead dd ?
	handleFile dd ?

	fileLine db 100 DUP(?)
	nameToken db 21 DUP(?)

	endFile db "EOF", endl

.code
	mov edx, OFFSET databaseFile				; Try to open the database file
	call OpenInputFile
	mov fileHandle, eax

	cmp eax, INVALID_HANDLE_VALUE				; Check if the file was opened
	jne read_success							; If it was, proceed

	mov edx, OFFSET errorMessage				; If it wasn't, print out the error message and quit
	call WriteString
	jmp quit

read_success:
	mov ecx, BUFFER_SIZE						; Prepare to read file
	mov edx, OFFSET buffer 

	call ReadFromFile							; Read the file
	jc show_read_error							; Print out error message if read failed.

	mov bytesRead, eax							; Store the amount of bytes read
	
	mov eax, fileHandle							; Close the file
	call CloseFile 

	mov ecx, bytesRead							; Prepare loop
	mov esi, OFFSET buffer
	mov edi, OFFSET fileLine

L1:
	mov al, [esi]								; Move char into al
	mov [edi], al								; Move char into the array

	inc esi										; Go to next char
	inc edi										; Go to next element in array
	
	cmp al, 0									; Check if 0x0 (end of file)
	je eof										; If it is, do something

	cmp al, 0ah									; Check if 0x0A (end of line)
	jne L1										; If not, continue
	
	mov edi, OFFSET fileLine					; If it is, get the name in the line
	mov edx, OFFSET nameToken

L2:
	mov al, [edi]								; Move char into al
	cmp al, 2Ch									; Check if 0x2C (comma character)
	je compare_names							; If yes, compare names
	
	mov [edx], al								; Move char into nameToken

	inc edi										; If it's not, continue
	inc edx
	loop L2

compare_names:
	INVOKE Str_compare,							; Compare the userName with name in file
		ADDR userName,
		ADDR nameToken

	je valid_name								; If it exists, exit			
	ja restart_search							; If it doesn't, search again
	jb restart_search

valid_name:
	mov eax, 0									; Success, do something
	mov edx, OFFSET nameToken
	call WriteString
	call Crlf

	jmp quit

restart_search:
	mov ecx, SIZEOF fileLine					; Prepare to restart search
	mov edi, OFFSET fileLine
	mov al, 0

reset_line:
	mov [edi], al								; Reset the fileLine array
	inc edi
	loop reset_line

	mov ecx, SIZEOF nameToken
	mov edi, OFFSET nameToken

reset_token:
	mov [edi], al								; Reset the nameToken array
	inc edi
	loop reset_token

	mov edi, OFFSET fileLine					; Restart the search
	jmp L1

eof:
	mov ecx, passByteCount						; If the end of the file has been reached,
	call EncryptPassword						; and no match has been found, then register
	call RegisterUser							; the user to the database.

	jmp quit

show_read_error:
	mov edx, OFFSET readError
	call WriteString

quit:
	ret

verifyLogin ENDP

;----------------------------------------------------
RegisterUser PROC USES eax edx
;
; Registers a user to the database.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	registerPrompt db "You are not registered with x86 Bank. Would you like to register? (Y/N)", endl
	commaSeparator db ","
	initializeMoney db ",500", newLine			; Initilaize account with $500

.code
L1:
	mov edx, OFFSET registerPrompt
	call WriteString

	call ReadChar

	cmp al, 79h									; Check if char is y
	je register_user

	cmp al, 59h									; Check if char is Y
	je register_user

	cmp al, 6eh									; Check if char n
	je terminate_program

	cmp al, 4eh									; Check if char N
	je terminate_program

	jmp L1										; Repeat until valid input

register_user:
	INVOKE CreateFile,							; Open a new file handle
		ADDR databaseFile, GENERIC_WRITE,
		DO_NOT_SHARE, NULL, OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL, 0

	mov fileHandle, eax					

	INVOKE SetFilePointer,						; Move the fileHandle to the end of the file
		fileHandle, 0, 0, FILE_END

	INVOKE WriteFile,							; Write the username
		fileHandle, ADDR userName,
		nameByteCount, ADDR bytesWritten, 0

	INVOKE WriteFile,							; Write a comma
		fileHandle, ADDR commaSeparator,
		SIZEOF commaSeparator, 
		ADDR bytesWritten, 0

	INVOKE WriteFile,							; Write encrypted password
		fileHandle, ADDR userPass,
		passByteCount, ADDR bytesWritten, 0

	INVOKE WriteFile,							; Initialize the money
		fileHandle, ADDR initializeMoney,
		SIZEOF initializeMoney, 
		ADDR bytesWritten, 0

	jmp quit

terminate_program:
	call Logout

quit:
	ret
RegisterUser ENDP

;----------------------------------------------------
EncryptPassword PROC
;
; Simple encryption/decryption from the Irvine
; x86 textbook.
; Recieves: ecx = size of buffer
; Returns: nothing
;----------------------------------------------------
.data
	KEY = 239
	BUFMAX = 128

.code
	mov esi, 0
	
L1:
	xor userPass[esi], key
	inc esi
	loop L1

	ret
EncryptPassword ENDP

;----------------------------------------------------
printMenu PROC USES eax ebx ecx edx
;
; Print out a menu for the user to select options.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	CaseTable db '1'
		dd Deposit
		EntrySize = ($ - CaseTable)
		db '2'
		dd Withdraw 
		db '3'
		dd Interest
		db '4'
		dd PrintLog
		db '5'
		dd Logout
		NumberOfEntries = ($ - CaseTable) / EntrySize

	menu db "Please select an option:", newLine,
			"1. Deposit Money", newLine,
			"2. Withdraw Money", newLine,
			"3. Calculate Interest", newLine,
			"4. Print log of previous transactions", newLine,
			"5. Log out", endl

.code
	mov edx, OFFSET menu						; Print out menu
	call WriteString

	call ReadChar

	mov ebx, OFFSET CaseTable
	mov ecx, NumberOfEntries

L1:	
	cmp al, [ebx]								; Match found?
	jne L2										; No, continue
	call NEAR PTR [ebx + 1]						; Yes, call procedure
	jmp L3										; Exit loop
L2:	
	add ebx, EntrySize							; Point to next entry, repeat until ecx = 0
	loop L1
L3:
	ret
printMenu ENDP

;----------------------------------------------------
initializeDatabase PROC USES eax
;
; Creates a database file if one doesn't exist.
; Recieves: nothing
; Returns: fileHandle = valid file handle 
;----------------------------------------------------
.data 
	databaseMsg db "Database doesn't exist... Creating one.",endl
	programTitle db "x86 Bank", 0

.code
	INVOKE SetConsoleTitle, ADDR programTitle	; Set the console title

	INVOKE CreateFile, 							; Try to open database file
		ADDR databaseFile, GENERIC_WRITE, 
		DO_NOT_SHARE, NULL, OPEN_EXISTING, 
		FILE_ATTRIBUTE_NORMAL, 0

	cmp eax, INVALID_HANDLE_VALUE				; Check if the file exists
	jne quit									; If it does, do nothing

	mov edx, OFFSET databaseMsg
	call WriteString

	mov edx, OFFSET databaseFile				; If it doesn't, create one
	call CreateOutputFile

quit:
	mov fileHandle, eax							; Save the file handle
	
	call CloseFile								; Close the file
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

	call WaitMsg

	ret
Deposit ENDP

;----------------------------------------------------
Withdraw PROC USES edx ebx eax
;
; Allows the user to specify an amount of money
; that is subtracted from their account balance.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	withdrawPrompt db "Please enter the amount you would like to withdraw: $", 0
	withdrawSuccess db "You have successfully withdrawn $", 0
	withdrawError db "The withdraw has not been completed. (You have insufficient funds to do so.)", endl
	balance dd 100

.code 
	mov edx, OFFSET withdrawPrompt				; Print out prompt and read user int
	call WriteString 
	call ReadDec

	mov ebx, balance
	cmp eax, ebx								; Compare the input with the account balance
	jl L1										; Complete withdraw if input is less than balance
	jmp show_withdraw_error						; Print out error if input is greater than balance

L1:
	sub balance, eax							; Withdraw the money from the user's account 

	mov edx, OFFSET withdrawSuccess				; Print out the withdraw success
	call WriteString
	call WriteDec
	call Crlf

	call WaitMsg								; Wait for user to press any key to continue
	jmp quit

show_withdraw_error:
	mov edx, OFFSET withdrawError				; Print out the withdraw error
	call WriteString
	call WaitMsg								; Wait for user to press any key to continue

quit:
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

	call WaitMsg

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

	call WaitMsg

	ret
PrintLog ENDP

;----------------------------------------------------
Logout PROC
;
; Ends the main loop and quits out of the program
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
	jmp exit_program

	ret
Logout ENDP

END main