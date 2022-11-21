INCLUDE BankApp.inc 

.code
;----------------------------------------------------
Deposit PROC USES eax ebx edx
;
; Allows the user to specify an amount of money
; that is added to their account balance.
; Returns: nothing
;----------------------------------------------------
.data
	depositPrompt db "Please enter the amount you would like to deposit: $", 0
	depositSuccess db "You have successfully deposited $", 0
	depositError db "The deposit has not been completed. (Invalid Amount)", endl

.code
	push ebp
	mov ebp, esp

	mov edx, OFFSET depositPrompt				; Print out prompt and read user int
	call WriteString
	call ReadDec

	cmp eax, 0									; Check if input is greater than 0
	jg L1										; If it is, perform deposit

	mov edx, OFFSET depositError				; If it's not, print out error
	call WriteString
	call WaitMsg
	jmp quit

L1:
	mov ebx, [ebp + 20]							; ebx = address of currentUser
	assume ebx:ptr User							; Assume ebx is a pointer to user

	add [ebx].userBalance, eax					; Add to the user's balance


	mov edx, OFFSET depositSuccess				; Print out success
	call WriteString
	call WriteDec
	call Crlf

	INVOKE UpdateDatabase,						; Update database
		ADDR [ebx].userBalance
	assume ebx:nothing

	call WaitMsg

quit:
	pop ebp
	ret
Deposit ENDP

;----------------------------------------------------
Interest PROC USES eax ecx edx
;
; Calculates the user's accumulated interest
; using the formula: A = P(1 + rt)
; Returns: nothing
;----------------------------------------------------
.data
	interestPrompt db "Enter amount of years to calculate interest for: ", 0
	interestTotal db "Total interest at a rate of 3% is: $", 0
	interestRate = 3

.code
	push ebp
	mov ebp, esp
	mov edx, OFFSET interestPrompt				; Print out prompt and get user input
	call WriteString
	call ReadDec

	mov ecx, eax								; Calculate rt
	mov eax, interestRate
	imul eax, ecx

	add eax, 1									; Add 1 to rt
	mov ecx, [ebp + 20]							; ecx = address of currentUser
	assume ecx:ptr User
	imul eax, [ecx].userBalance					; Multiply by P

	assume ecx:nothing

	mov edx, OFFSET interestTotal				; Print out the total interest
	call WriteString
	call WriteDec
	call Crlf

	call WaitMsg

	pop ebp
	ret
Interest ENDP

;----------------------------------------------------
Logout PROC
;
; Ends the main loop and quits out of the program
; Recieves: nothing
; Returns: eax = -1
;----------------------------------------------------
	mov eax, -1

	ret
Logout ENDP

;----------------------------------------------------
PrintBalance PROC USES eax edx
;
; Prints the user's current balance.
; Recieves: nothing
; Returns: nothing
;----------------------------------------------------
.data
	balanceString db "Your current balance is $",0

.code
	push ebp
	mov ebp, esp
	mov edx, OFFSET balanceString
	call WriteString

	mov ebx, [ebp + 16]							; ebx = pointer to currentUser
	assume ebx:ptr User

	mov eax, [ebx].userBalance					; eax = currentUser.userBalance
	call WriteDec
	call Crlf

	assume ebx:nothing
	call WaitMsg
	pop ebp
	ret
PrintBalance ENDP

;----------------------------------------------------
PrintMenu PROC USES ebx ecx edx,
	currentUser:PTR DWORD
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
		dd PrintBalance
		db '5'
		dd Logout
		NumberOfEntries = ($ - CaseTable) / EntrySize

	menu db "Please select an option:", newLine,
			"1. Deposit Money", newLine,
			"2. Withdraw Money", newLine,
			"3. Calculate Interest", newLine,
			"4. Show Current Balance", newLine,
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
	push currentUser
	call NEAR PTR [ebx + 1]						; Yes, call procedure
	pop ebx
	jmp L3										; Exit loop
L2:	
	add ebx, EntrySize							; Point to next entry, repeat until ecx = 0
	loop L1
L3:
	ret
PrintMenu ENDP

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
	withdrawError db "The withdraw has not been completed. (You have insufficient funds to do so)", endl
	withdrawInvalid db "The withdraw has not been completed. (Invalid amount)", endl

.code 
	push ebp
	mov ebp, esp

	mov edx, OFFSET withdrawPrompt				; Print out prompt and read user int
	call WriteString 
	call ReadDec

	cmp eax, 0
	jle show_invalid_error

	mov ebx, [ebp + 20]
	assume ebx:ptr User
	cmp eax, [ebx].userBalance					; Compare the input with the account balance
	jl L1										; Complete withdraw if input is less than balance
	jmp show_withdraw_error						; Print out error if input is greater than balance

L1:
	sub [ebx].userBalance, eax					; Withdraw the money from the user's account 

	mov edx, OFFSET withdrawSuccess				; Print out the withdraw success
	call WriteString
	call WriteDec
	call Crlf

	INVOKE UpdateDatabase,						; Update database
		ADDR [ebx].userBalance
	assume ebx:nothing

	call WaitMsg								; Wait for user to press any key to continue
	jmp quit

show_invalid_error:
	mov edx, OFFSET withdrawInvalid
	call WriteString
	call WaitMsg
	jmp quit

show_withdraw_error:
	mov edx, OFFSET withdrawError				; Print out the withdraw error
	call WriteString
	call WaitMsg								; Wait for user to press any key to continue

quit:
	pop ebp
	ret
Withdraw ENDP
END