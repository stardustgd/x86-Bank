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
Deposit PROTO, balance:PTR DWORD
Interest PROTO, balance:PTR DWORD
Logout PROTO
PrintBalance PROTO, balance:PTR DWORD
PrintMenu PROTO
Withdraw PROTO, balance:PTR DWORD

;----------------------------------------
;             Database Utilities
;----------------------------------------
InitializeDatabase PROTO
LoginMenu PROTO 
RegisterUser PROTO
UpdateDatabase PROTO
VerifyLogin PROTO