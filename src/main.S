.syntax unified
.global main
.global EXTI0_IRQHandler, EXTI3_IRQHandler
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
  GPIO_configure_output_pin E, 14 @output at PE14
  GPIO_configure_input_pin_it D, 0 @input at PD0

  @configure trigger for the interrupt for note on/off line
  EXTI_set_rising_edge_trigger 0
  EXTI_set_falling_edge_trigger 0
  NVIC_set ISER 6 @enable EXTI interrupt in the NVIC

  @configure GPIO pins for pitch change line
  GPIO_configure_output_pin E, 15 @output at PE15
  GPIO_configure_input_pin_it B, 3 @input at PB3

  @configure trigger for the interrupt for pitch change line
  EXTI_set_rising_edge_trigger 3
  NVIC_set ISER 9 @enable EXTI interrupt in the NVIC

  @ clear output pins
  GPIOx_ODR_clear E, 14
  GPIOx_ODR_clear E, 15

  @SENDER - implement timer
  mov r0, 1000 @clock divisor (prescaler + 1)
  mov r1, 2000 @count
  bl tim7_init

  @RECEIVER - implement waveform
  play_sound:
    bl wave_play_next_sample @play the next sample of the currently set wave
    b play_sound @loop back to continue playing sound

  b main
.size main, .-main

@note on/off line interrupt handler function
.type EXTI0_IRQHandler, %function
EXTI0_IRQHandler: 
  push {r4-r11, lr}
  mov r4, 0x7fff @temp variable holding amplitude
  GPIOx_IDR_read D, 0 @read value to get voltage value (rise or fall)
  beq silence @if zero, play silence
  bne play @if one, play sound

  silence:
    mov r4, 0 @set amplitude parameter to zero

  play:
    mov r1, r4 @move temp variable to parameter r1
    bl wave_change @change waveform so that its amplitude is either zero or 0x7fff

  EXTI_PR_clear_pending 0 @clear pending register
  pop {r4-r11, lr}
  bx lr
.size EXTI0_IRQHandler, .-EXTI0_IRQHandler

@pitch change line interrupt handler function
.type EXTI3_IRQHandler, %function
EXTI3_IRQHandler: 
  push {r4-r11, lr}
  ldr r4, =index @load index memory address
  ldr r5, [r4] @load current index into r5
  mov r6, #28 @set maximum index in frequency array
  subs r7, r6, r5 @substract them to see if Z=0
  beq reset_index
  bne increase

  reset_index:
    mov r5, #0 @set index to zero

  increase: 
    add r5, r5, #4 @updated index in r6

  str r5, [r4] @ store index
  ldr r8, =frequency
  ldr r9, [r8, r5] @get new frequency from table
  mov r0, r9
  mov r10, 0x7fff @change depending on current note on/off
  GPIOx_IDR_read D, 0 @what is the current amplitude
  beq reset_amplitude
  bne change_frequency

  reset_amplitude:
    mov r10, #0 @set amplitude to zero

  change_frequency:
    mov r1, r10 @move temp variable to parameter r1
    bl wave_change

  EXTI_PR_clear_pending 3 @clear pending register
  pop {r4-r11, lr}
  bx lr
.size EXTI3_IRQHandler, .-EXTI3_IRQHandler

.data
.align 2 @ align memory addresses to a word boundry (leave here)
@ \/ memory entries go below \/
@2-byte alignment, therefore the indexes increase by 4
frequency: @all frequencies have been scaled by a factor of 100
  .word 22000, 24694, 26163, 29366, 32963, 36999, 39200, 44000

index: @stores current frequency index
  .word 0