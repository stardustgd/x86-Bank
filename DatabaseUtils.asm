INCLUDE BankApp.inc 

.code
;----------------------------------------------------
EncryptPassword PROC PRIVATE USES esi
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
InitializeDatabase ENDP

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
LoginMenu ENDP

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
ResetArray PROC PRIVATE USES eax
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

	mov bytePosition, ebx 						; Calculate the byte position of the line being parsed
	sub bytePosition, esi 						; End of file - current byte position

	push eax
	mov eax, bytesRead 
	sub eax, bytePosition						; Total bytes read - bytePosition

	pop eax

	mov ecx, ebx 								; Calculate remaining bytes in the string
	sub ecx, edi

	jna eof										; Jump if end of file is reached

	mov al, 0ah									; Set accumulator to 0x0A (end line)
	repne scasb 								; Scan string for accumulator while zero flag is clear and ecx > 0

	mov ecx, edi 								; Set ecx to the length of the split
	dec ecx 
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

	sub eax, 32d 								; Move tokenOffset to point to the next token
	mov tokenOffset, eax 

	pop edi 									; Restore edi

	jmp L1

verify_login:
	INVOKE Str_compare,							; Compare the userName with name in file
		ADDR userName,
		ADDR nameToken

	ja restart_search							; If it doesn't match, search again
	jb restart_search
	
	INVOKE Str_compare,							; Compare userPass with pass in file
		ADDR userPass,
		ADDR passToken

	ja invalid_password							; If it doesn't match, return 1
	jb invalid_password

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
VerifyLogin ENDP
END