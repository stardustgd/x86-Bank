INCLUDE Irvine32.inc 

;----------------------------------------
;                Constants
;----------------------------------------
endl EQU <0dh, 0ah, 0>
newLine EQU <0dh, 0ah>
databaseFile EQU "database.txt",0

User STRUCT 
	userUsername BYTE 32 DUP(?)
	userPassword BYTE 32 DUP(?)
	userBalance DWORD ? 
User ENDS 

;----------------------------------------
;              Bank Utilities
;----------------------------------------
Deposit PROTO
Interest PROTO
Logout PROTO
PrintBalance PROTO
PrintMenu PROTO
Withdraw PROTO

;----------------------------------------
;             Database Utilities
;----------------------------------------
InitializeDatabase PROTO
LoginMenu PROTO 
RegisterUser PROTO
UpdateDatabase PROTO
VerifyLogin PROTO