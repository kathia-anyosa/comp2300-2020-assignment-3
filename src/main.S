.syntax unified
.global main
.include "libcomp2300/macros.S"

@COMP2300 Assignment 3 Part 1 - Implementing the P2300 communication protocol

.type main, %function
main:
  bl init @initialise headphone jack
  bl BSP_AUDIO_Buffer @play buffer 
  RCC_APB2ENR_set 0 @ enable SYSCFG clock

  @set up wires
  @enable clocks for pins
  GPIOx_clock_enable B
  GPIOx_clock_enable D
  GPIOx_clock_enable E

  @configure GPIO pins for note on/off line
  GPIO_configure_input_pin_it E, 14 @input located at PE14
  GPIO_configure_output_pin D, 0 @output located at PD0

  @configure GPIO pins for pitch change line
  GPIO_configure_input_pin_it E, 15 @input located at PE15
  GPIO_configure_output_pin B, 3 @output located at PB3

  @configure GPIO pins to trigger an interrupt


  @configure trigger for interrupt

  @enable EXTI interrupt in the NVIC

  @interrupt handler functions - declare and globally visible
  @must follow proper calling conventions: r4-r11 are 
  @saved and restored at the start and ed of the handler
  @must clear pending registers before it exits - use EXTI_PR_clear_pending



  @use bl sync to allow time for operations to persist (once or after each?)



  play_sound:
    bl wave_play_next_sample @play the next sample of the currently set wave
    b play_sound @loop back to continue playing sound

  nop
  b main
.size main, .-main
@use wave_change somewhere to change frequency

.data
.align 2 @ align memory addresses to a word boundry (leave here)
@ \/ memory entries go below \/
frequency:
  .word 22000, 24694, 26163, 29366, 32963, 36999, 39200, 44000 