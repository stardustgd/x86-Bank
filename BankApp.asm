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

User STRUCT 
	userUsername BYTE 32 DUP(?)
	userPassword BYTE 32 DUP(?)
	userBalance DWORD ? 
	bytePosition DWORD ?
User ENDS

.const
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
	call Clrscr
	jmp L1

exit_program::
	call Clrscr
	mov edx, OFFSET goodbyeText
	call WriteString

	exit
main ENDP

;----------------------------------------------------
loginMenu PROC USES ecx edx
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

	userName db 32 DUP(?)
	userPass db 32 DUP(?)

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

	mov ecx, passByteCount						; Encrypt password
	call EncryptPassword

	INVOKE Str_ucase, ADDR userName				; Convert username to uppercase

	ret
loginMenu ENDP

;----------------------------------------------------
verifyLogin PROC USES ebx ecx edx edi esi
	LOCAL buffer[5000]:BYTE, bytesRead:DWORD,
		  tokenOffset:DWORD, lineSize:DWORD,
		  fileLine[96]:BYTE, nameToken[32]:BYTE, 
		  passToken[32]:BYTE, moneyToken[32]:BYTE
;
; Opens the database file and checks if the supplied username
; and password exists in the database. If it doesn't, the
; username and password will be registered to the database.
; Recieves: nothing
; Returns: eax = 0 if success
;		   eax = 1 if fail
;----------------------------------------------------
.data 
	errorMessage db "Couldn't open the file.", endl
	readError db "Couldn't read file.", endl
	invalidPassword db "Incorrect password.", endl
	BUFFER_SIZE = 5000

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
	lea edx, buffer 

	call ReadFromFile							; Read the file
	jc show_read_error							; Print out error message if read failed.

	mov bytesRead, eax							; Store the amount of bytes read
	
	mov eax, fileHandle							; Close the file
	call CloseFile 

	mov ecx, bytesRead
	lea edi, buffer								; Point to the beginning of the file
	lea ebx, [edi + ecx]						; Point to the end of the file

parse_line:
	mov esi, edi								; Get position of the first byte

	mov currentUser.bytePosition, ebx 			; Calculate the byte position of the line being parsed
	sub currentUser.bytePosition, esi 			; End of file - current byte position

	push eax
	mov eax, bytesRead 
	sub eax, currentUser.bytePosition			; Total bytes read - bytePosition
	mov currentUser.bytePosition, eax

	pop eax

	mov ecx, ebx 								; Calculate remaining bytes in the string
	sub ecx, edi

	jna eof										; Jump if end of file is reached

	mov al, 0ah									; Set accumulator to 0x0A (end line)
	repne scasb 								; Scan string for accumulator while zero flag is clear and ecx > 0

	mov ecx, edi 								; Set ecx to the length of the split
	sub ecx, esi
	mov lineSize, ecx							; Save the size of the line 

	push edi									; Save edi and ebx
	push ebx

	lea edi, fileLine							; Parse a line in the file 
	rep movsb

	jmp tokenize 								; Split the line into tokens

tokenize:
	lea eax, nameToken 							; Prepare to tokenize the line into three variables
	mov tokenOffset, eax

	mov ecx, lineSize 
	lea edi, fileLine
	lea ebx, [edi + ecx]

L1:
	mov esi, edi 								; Get position of first byte
	mov ecx, ebx 								; Calculate remaining bytes in the line
	sub ecx, edi 

	jna verify_login							; Jump if end line is reached

	mov al, ','									; Set accumualtor to comma 
	repne scasb 								; Scan string for accumulator 

	mov ecx, edi 								; Set ecx to the length of the split
	dec ecx 
	sub ecx, esi

	push edi 									; Save edi
	mov eax, tokenOffset 						; Set the tokenOffset in eax

	mov edi, eax 								; Move the token into a variable (can be nameToken, passToken, or moneyToken)
	rep movsb 
	mov BYTE PTR[edi], 0						; Null terminate the token			

	sub eax, 32d 								; Move tokenOffset to point to the next token
	mov tokenOffset, eax 

	pop edi 									; Restore edi

	jmp L1

verify_login:
	INVOKE Str_compare,							; Compare the userName with name in file
		ADDR userName,
		ADDR nameToken

	jne restart_search							; If it doesn't match, search again
	
	INVOKE Str_compare,							; Compare userPass with pass in file
		ADDR userPass,
		ADDR passToken

	jne invalid_password						; If it doesn't match, return 1

	lea edx, moneyToken							; Convert moneyToken to an integer
	mov ecx, SIZEOF moneyToken
	call ParseInteger32

	mov currentUser.userBalance, eax			; Store balance into struct

	INVOKE Str_copy, ADDR nameToken, 			; Store username into struct
		ADDR currentUser.userUsername

	INVOKE Str_copy, ADDR passToken, 			; Store password into struct 
		ADDR currentUser.userPassword

	mov eax, 0									; Return eax = 0 (success)
	jmp restore_registers

restart_search:
	mov ecx, SIZEOF fileLine					; Reset fileLine
	lea edi, fileLine
	call ResetArray
	
	mov ecx, SIZEOF nameToken					; Reset nameToken
	lea edi, nameToken
	call ResetArray

	mov ecx, SIZEOF passToken					; Reset passToken
	lea edi, passToken
	call ResetArray

	mov ecx, SIZEOF moneyToken					; Reset moneyToken
	lea edi, moneyToken
	call ResetArray

	pop ebx										; Restore ebx and edi
	pop edi

	jmp parse_line

eof:
	call RegisterUser							; If the end of the file has been reached,
	mov eax, 0									; and no match has been found, then register
	jmp restore_registers						; the user to the database.

invalid_password:
	mov edx, OFFSET invalidPassword				; Print out error
	call WriteString 

	mov eax, 1									; Return eax = 1
	jmp restore_registers

show_read_error:
	mov edx, OFFSET readError
	call WriteString
	jmp quit 

restore_registers:
	pop ebx
	pop edi
	jmp quit

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
	initializeMoney db ",500", 0ah				; Initilaize account with $500

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
	mov currentUser.userBalance, 500			; Store balance into struct

	INVOKE Str_copy, ADDR userName, 			; Store username into struct
		ADDR currentUser.userUsername

	INVOKE Str_copy, ADDR userPass, 			; Store password into struct 
		ADDR currentUser.userPassword

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
	mov eax, fileHandle
	call CloseFile
	ret
RegisterUser ENDP

;----------------------------------------------------
ResetArray PROC USES eax
;
; Goes through each byte in an array and moves 0
; into it.
; Recieves: ecx = size of array
;			edi = offset of array
; Returns: nothing
;----------------------------------------------------
.code
	mov al, 0

L1:
	mov [edi], al
	inc edi 
	loop L1

	ret 
ResetArray ENDP

;----------------------------------------------------
EncryptPassword PROC USES esi
;
; Simple encryption/decryption from the Irvine
; x86 textbook.
; Recieves: ecx = size of buffer
; Returns: nothing
;----------------------------------------------------
.data
	KEY = 239
	BUFMAX = 32

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
initializeDatabase PROC USES eax edx
;
; Creates a database file if one doesn't exist.
; Recieves: nothing
; Returns: fileHandle = valid file handle 
;----------------------------------------------------
.data
	programTitle db "x86 Bank", 0

.code
	INVOKE SetConsoleTitle, ADDR programTitle	; Set the console title

	INVOKE CreateFile, 							; Try to open database file
		ADDR databaseFile, GENERIC_WRITE, 
		DO_NOT_SHARE, NULL, OPEN_EXISTING, 
		FILE_ATTRIBUTE_NORMAL, 0

	cmp eax, INVALID_HANDLE_VALUE				; Check if the file exists
	jne quit									; If it does, do nothing

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
.data
	depositPrompt db "Please enter the amount you would like to deposit: $", 0
	depositSuccess db "You have successfully deposited $", 0
	depositError db "The deposit has not been completed. (Invalid Amount)", endl

.code
	mov edx, OFFSET depositPrompt
	call WriteString
	call ReadInt

	cmp eax, 0
	jge L1

	mov edx, OFFSET depositError
	call WriteString
	call WaitMsg
	jmp quit

L1:
	add currentUser.userBalance, eax

	mov edx, OFFSET depositSuccess
	call WriteString
	call WriteDec
	call Crlf
	call UpdateDatabase

	call WaitMsg


quit:
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

.code 
	mov edx, OFFSET withdrawPrompt				; Print out prompt and read user int
	call WriteString 
	call ReadDec

	mov ebx, currentUser.userBalance
	cmp eax, ebx								; Compare the input with the account balance
	jl L1										; Complete withdraw if input is less than balance
	jmp show_withdraw_error						; Print out error if input is greater than balance

L1:
	sub currentUser.userBalance, eax			; Withdraw the money from the user's account 

	mov edx, OFFSET withdrawSuccess				; Print out the withdraw success
	call WriteString
	call WriteDec
	call Crlf
	call UpdateDatabase

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
	mov eax, currentUser.userBalance
	call WriteInt

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

;----------------------------------------------------
UpdateDatabase PROC USES eax ebx ecx edx edi esi
	LOCAL buffer[5000]:BYTE, fileLine[96]:BYTE,
		  moneyToken[32]:BYTE, currentByte:DWORD, 
		  lineSize:DWORD, bytesRead:DWORD,
		  newLineChar:BYTE
;
; Updates the current user's balance in the database
; whenever a deposit/withdraw is done. 
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	BUFFER_SIZE = 5000
	numFormat db "%d",0

.code
	mov newLineChar, 0ah						; Initialize newLineChar

	mov edx, OFFSET databaseFile				; Prepare to read the database file
	call OpenInputFile
	mov fileHandle, eax 

	cmp eax, INVALID_HANDLE_VALUE				; File handling
	jne read_success

	mov edx, OFFSET errorMessage				; Print out error
	call WriteString
	jmp quit

read_success:
	mov ecx, BUFFER_SIZE
	lea edx, buffer	

	call ReadFromFile							; Read the file
	jc show_read_error

	mov bytesRead, eax

	mov eax, fileHandle
	call CloseFile

	mov ecx, bytesRead							; Prepare the loop for parsing lines
	lea edi, buffer
	lea ebx, [edi + ecx]

	mov edx, OFFSET databaseFile				; Begin to override the file
	call CreateOutputFile
	mov fileHandle, eax

parse_line:
	mov esi, edi								; Calculate the current byte 

	mov currentByte, ebx 
	sub currentByte, esi

	mov eax, bytesRead
	sub eax, currentByte

	mov currentByte, eax 						; Store the current byte

	mov ecx, ebx								; Calculate remaining bytes in the file
	sub ecx, edi

	jna quit									; Quit if eof

	mov al, 0ah									; Set accumulator to 0x0A (end line)
	repne scasb									; Scan string for accumulator

	mov ecx, edi								; Set ecx to length of the split
	sub ecx, esi
	mov lineSize, ecx

	pushad

	mov eax, currentByte						; Check if the current byte is the same as the
	cmp currentUser.bytePosition, eax			; current user's byte position
	je print_new								; If it is, write the new line to file

	lea edi, fileLine							; If it's not, write the original data to the file
	rep movsb

	mov eax, fileHandle
	mov ecx, lineSize
	lea edx, fileLine
	call WriteToFile
	
	mov ecx, SIZEOF lineSize					; Reset the lineSize array
	lea edi, fileLine
	call ResetArray

	popad
	jmp parse_line

print_new:
	pushad

	mov eax, fileHandle							; Write the username
	mov ecx, nameByteCount
	lea edx, currentUser.userUsername
	call WriteToFile

	mov eax, fileHandle							; Write a comma
	mov ecx, 1
	lea edx, commaSeparator
	call WriteToFile

	mov eax, fileHandle							; Write the password
	mov ecx, passByteCount
	lea edx, currentUser.userPassword
	call WriteToFile
	
	mov eax, fileHandle							; Write a comma
	mov ecx, 1
	lea edx, commaSeparator
	call WriteToFile

	INVOKE wsprintf,							; Parse integer to string using wsprintf		
		ADDR moneyToken,
		ADDR numFormat,
		[currentUser.userBalance]

	mov ecx, eax								; Write the balance
	mov eax, fileHandle
	lea edx, moneyToken
	call WriteToFile

	mov eax, fileHandle							; Write newline 
	mov ecx, 1
	lea edx, newLineChar
	call WriteToFile

	popad
	jmp parse_line

show_read_error:
	jmp quit

quit:
	mov eax, fileHandle							; Close the file
	call CloseFile	
	ret
UpdateDatabase ENDP

END main