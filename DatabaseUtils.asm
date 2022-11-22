INCLUDE BankApp.inc 

.data
	databaseFile db "database.txt",0
	fileHandle HANDLE ?
	bytesWritten dd 0
	nStdHandle dd ?

	tempUser User <>

.code
;----------------------------------------------------
DisableEcho PROC PRIVATE USES eax edx 
;
; Clears the ENABLE_ECHO_INPUT to turn off console
; echo.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
	push STD_INPUT_HANDLE
	call GetStdHandle
	mov nStdHandle, eax

	push eax
	push edx									; Create a slot

	INVOKE GetConsoleMode, eax, esp
	pop eax 									; Get current mode 

	and eax, NOT ENABLE_ECHO_INPUT				; Clear echo bit
	pop edx
	INVOKE SetConsoleMode, edx, eax

	ret
DisableEcho ENDP

;----------------------------------------------------
EnableEcho PROC PRIVATE USES eax edx
;
; Enables the ENABLE_ECHO_INPUT to turn on console
; echo.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
	push STD_INPUT_HANDLE
	call GetStdHandle
	mov nStdHandle, eax

	push eax
	push edx									; Create a slot

	INVOKE GetConsoleMode, eax, esp
	pop eax										; Get current mode

	or eax, ENABLE_ECHO_INPUT					; Set echo bit
	pop edx
	INVOKE SetConsoleMode, edx, eax

	ret
EnableEcho ENDP 

;----------------------------------------------------
EncryptPassword PROC PRIVATE USES esi
;
; Simple encryption/decryption from the Irvine
; x86 textbook.
; Recieves: ecx = size of buffer
; Returns: nothing
;----------------------------------------------------
	mov esi, 0
	
L1:
	xor userPass[esi], KEY
	inc esi
	loop L1

	ret
EncryptPassword ENDP

;----------------------------------------------------
InitializeDatabase PROC USES eax edx
;
; Creates a database file if one doesn't exist.
; Recieves: nothing
; Returns: fileHandle = valid file handle 
;----------------------------------------------------
.data
	programTitle db "x86 Bank", 0

.code
	INVOKE SetConsoleTitle, ADDR programTitle	; Set the console title

	lea edx, databaseFile				; Try to open database file
	call OpenInputFile

	cmp eax, INVALID_HANDLE_VALUE				; Check if the file exists
	jne quit									; If it does, do nothing

	call CreateOutputFile						; If it doesn't, create one

quit:
	mov fileHandle, eax							; Save the file handle
	call CloseFile								; Close the file
	ret
InitializeDatabase ENDP

;----------------------------------------------------
InitializeStruct PROC USES eax ebx,
	username:PTR DWORD, password:PTR DWORD,
	balance:PTR DWORD, bytePosition:PTR DWORD
;
; Transfers the values of tempUser to the
; current user.
; Returns: nothing
;----------------------------------------------------
	INVOKE Str_copy, ADDR tempUser.userUsername, username
	INVOKE Str_copy, ADDR tempUser.userPassword, password
	
	mov eax, balance
	mov ebx, tempUser.userBalance
	mov [eax], ebx

	mov eax, bytePosition
	mov ebx, tempUser.bytePosition
	mov [eax], ebx

	ret
InitializeStruct ENDP

;----------------------------------------------------
LoginMenu PROC USES ecx edx
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
	call EnableEcho								; Make sure echo is turned on
	mov edx, OFFSET usernamePrompt				; Print username prompt
	call WriteString

	mov edx, OFFSET userName					; Prompt for username
	mov ecx, SIZEOF userName
	call ReadString

	mov nameByteCount, eax						; Store the amount of bytes read

	mov edx, OFFSET passwordPrompt				; Print passowrd prompt
	call WriteString

	call DisableEcho							; Turn off console echo

	mov edx, OFFSET userPass					; Prompt for password
	mov ecx, SIZEOF userPass
	call ReadString

	call EnableEcho								; Turn on console echo

	mov passByteCount, eax

	mov ecx, passByteCount						; Encrypt password
	call EncryptPassword

	INVOKE Str_ucase, ADDR userName				; Convert username to uppercase

	ret
LoginMenu ENDP

;----------------------------------------------------
RegisterUser PROC USES edx
;
; Registers a user to the database.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	commaSeparator db ","
	initializeMoney db ",500", 0ah				; Initilaize account with $500
	registerPrompt db "You are not registered with x86 Bank. Would you like to register? (Y/N)", endl

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
	je terminate_register

	cmp al, 4eh									; Check if char N
	je terminate_register

	jmp L1										; Repeat until valid input

register_user:
	mov tempUser.userBalance, 500				; Store balance into struct

	INVOKE Str_copy, ADDR userName, 			; Store username into struct
		ADDR tempUser.userUsername

	INVOKE Str_copy, ADDR userPass, 			; Store password into struct 
		ADDR tempUser.userPassword

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

terminate_register:
	mov eax, -1
	ret

quit:
	mov eax, fileHandle
	call CloseFile

	mov eax, 0
	ret
RegisterUser ENDP

;----------------------------------------------------
ResetArray PROC PRIVATE USES eax
;
; Goes through each byte in an array and moves 0
; into it.
; Recieves: ecx = size of array
;			edi = offset of array
; Returns: nothing
;----------------------------------------------------
	mov al, 0

L1:
	mov [edi], al
	inc edi 
	loop L1

	ret 
ResetArray ENDP

;----------------------------------------------------
UpdateDatabase PROC USES eax ebx ecx edx edi esi,
	balance:PTR DWORD
	LOCAL buffer[5000]:BYTE, fileLine[96]:BYTE,
		  moneyToken[32]:BYTE, currentByte:DWORD, 
		  lineSize:DWORD, bytesRead:DWORD,
		  newLineChar:BYTE
;
; Updates the current user's balance in the database
; whenever a deposit/withdraw is done. 
; Returns: nothing
;----------------------------------------------------
.data
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
	cmp tempUser.bytePosition, eax				; current user's byte position
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
	lea edx, tempUser.userUsername
	call WriteToFile

	mov eax, fileHandle							; Write a comma
	mov ecx, 1
	lea edx, commaSeparator
	call WriteToFile

	mov eax, fileHandle							; Write the password
	mov ecx, passByteCount
	lea edx, tempUser.userPassword
	call WriteToFile
	
	mov eax, fileHandle							; Write a comma
	mov ecx, 1
	lea edx, commaSeparator
	call WriteToFile

	mov eax, balance

	INVOKE wsprintf,							; Parse integer to string using wsprintf		
		ADDR moneyToken, 
		ADDR numFormat, [eax]

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

;----------------------------------------------------
VerifyLogin PROC USES ebx ecx edx edi esi
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
;		   eax = -1 if user doesn't want to register
;----------------------------------------------------
.data 
	errorMessage db "Couldn't open the file.", endl
	invalidPassword db "Incorrect password.", endl
	readError db "Couldn't read file.", endl

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

	mov tempUser.bytePosition, ebx 				; Calculate the byte position of the line being parsed
	sub tempUser.bytePosition, esi 				; End of file - current byte position

	push eax
	mov eax, bytesRead 
	sub eax, tempUser.bytePosition				; Total bytes read - bytePosition
	mov tempUser.bytePosition, eax

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

	mov tempUser.userBalance, eax				; Store balance into struct

	INVOKE Str_copy, ADDR nameToken, 			; Store username into struct
		ADDR tempUser.userUsername

	INVOKE Str_copy, ADDR passToken, 			; Store password into struct 
		ADDR tempUser.userPassword

	; lea edx, userPass
	; call WriteString

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
	call Clrscr
	call RegisterUser							; If the end of the file has been reached,
	jmp restore_registers						; and no match has been found, then register
												; the user to the database.

invalid_password:
	call Clrscr
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

quit:
	ret
VerifyLogin ENDP
END