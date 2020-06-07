.syntax unified
.global main
.include "libcomp2300/macros.S"


.type main, %function
main:
  bl init @initialise headphone jack
  bl BSP_AUDIO_Buffer @initialise buffer 

  @set up wires

  play_sound:
    bl wave_play_next_sample @Play the next sample of the currently set wave
    b play_sound @loop back to continue playing sound

  nop
  b main
.size main, .-main


.data
.align 2 @ align memory addresses to a word boundry (leave here)
@ \/ memory entries go below \/
frequency:
  .word 22000, 24694, 26163, 29366, 32963, 36999, 39200, 44000 