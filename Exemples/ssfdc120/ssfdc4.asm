		org	0

;SmartMedia Driver
; cache size 8192 byte (4MB,8MB)

media_type:	equ	1	;0:2MB(cache size 4KB)
				;1:4MB,8MB(cache size 8KB)
				;2:16MB,32MB(cache size 16KB)

ssect:		equ	8192
		include	SSFDC.ASM

		end
