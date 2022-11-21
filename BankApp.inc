INCLUDE Irvine32.inc

;----------------------------------------
;                Constants
;----------------------------------------
endl EQU <0dh, 0ah, 0>
newLine EQU <0dh, 0ah>
KEY = 239

;----------------------------------------
;                 Structs
;----------------------------------------
User STRUCT 
	userUsername BYTE 32 DUP(?)
	userPassword BYTE 32 DUP(?)
	userBalance DWORD ?
	bytePosition dd ?
User ENDS 

;----------------------------------------
;              Bank Utilities
;----------------------------------------
Deposit PROTO
Interest PROTO
Logout PROTO
PrintBalance PROTO
PrintMenu PROTO, currentUser:PTR DWORD
Withdraw PROTO

;----------------------------------------
;             Database Utilities
;----------------------------------------
InitializeDatabase PROTO
InitializeStruct PROTO, username:PTR DWORD,
	password:PTR DWORD, balance:PTR DWORD,
	bytePosition:PTR DWORD
LoginMenu PROTO 
RegisterUser PROTO
UpdateDatabase PROTO
VerifyLogin PROTO