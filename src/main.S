.syntax unified
.global main
.global EXTI15_10_IRQHandler
.include "libcomp2300/macros.S"

@COMP2300 Assignment 3 Part 1 - Implementing the P2300 communication protocol

.type main, %function
main:
  bl init @initialise headphone jack
  bl BSP_AUDIO_Buffer @play buffer 
  RCC_APB2ENR_set 0 @enable SYSCFG clock

  @enable clocks for pins
  GPIOx_clock_enable B @enable GPIOB clock
  GPIOx_clock_enable D @enable GPIOD clock
  GPIOx_clock_enable E @enable GPIOE clock

  @configure GPIO pins for note on/off line
  GPIO_configure_input_pin_it E, 14 @input located at PE14
  GPIO_configure_output_pin D, 0 @output located at PD0

  @configure trigger for the interrupt for note on/off line
  EXTI_set_rising_edge_trigger 14
  EXTI_set_falling_edge_trigger 14
  NVIC_set ISER 40 @enable EXTI interrupt in the NVIC

  @configure GPIO pins for pitch change line
  GPIO_configure_input_pin_it E, 15 @input located at PE15
  GPIO_configure_output_pin B, 3 @output located at PB3

  @configure trigger for the interrupt for pitch change line
  EXTI_set_rising_edge_trigger 15
  NVIC_set ISER 40 @enable EXTI interrupt in the NVIC

  @ clear output pins
  GPIOx_ODR_clear D, 0
  GPIOx_ODR_clear B, 3


  @use bl sync to allow time for operations to persist (once or after each?)

  play_sound:
    bl wave_play_next_sample @play the next sample of the currently set wave
    b play_sound @loop back to continue playing sound

  nop
  b main
.size main, .-main
@use wave_change somewhere to change frequency
@ r0: frequency
@ r1: amplitude (lower 16-bit as signed)

@interrupt handler functions - declare and make globally visible
  @must follow proper calling conventions: r4-r11 are 
  @saved and restored at the start and end of the handler
  @must clear pending registers before it exits - use EXTI_PR_clear_pending
@interrupt handler function //depends on where the trigger happened
.type EXTI15_10_IRQHandler, %function
EXTI15_10_IRQHandler:
push {lr, r4-r11}

@some code

EXTI_PR_clear_pending
pop {lr, r4-r11}
bl lr
.size EXTI15_10_IRQHandler, .-EXTI15_10_IRQHandler

.data
.align 2 @ align memory addresses to a word boundry (leave here)
@ \/ memory entries go below \/
@2-byte alignment, therefore the indexes increase by 4
frequency: @all frequencies have been scaled by a factor of 100
  .word 22000, 24694, 26163, 29366, 32963, 36999, 39200, 44000