		org	0

;SmartMedia Driver
; cache size 4096 byte (2MB)

media_type:	equ	0	;0:2MB(cache size 4KB)
				;1:4MB,8MB(cache size 8KB)
				;2:16MB,32MB(cache size 16KB)

ssect:		equ	4096
		include	SSFDC.ASM

		end
