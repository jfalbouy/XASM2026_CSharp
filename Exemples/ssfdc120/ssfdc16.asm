		org	0

;SmartMedia Driver
; cache size 16384 byte (16MB,32MB)

media_type:	equ	2	;0:2MB(cache size 4KB)
				;1:4MB,8MB(cache size 8KB)
				;2:16MB,32MB(cache size 16KB)

ssect:		equ	16384
		include	SSFDC.ASM

		end
