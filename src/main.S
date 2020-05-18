.syntax unified
.global main
.include "libcomp2300/macros.S"


.type main, %function
main:
  nop
  b main
.size main, .-main


.data
.align 2 @ align memory addresses to a word boundry (leave here)
@ \/ memory entries go below \/
