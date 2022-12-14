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

  @SENDER - implement timer, which is set to interrupt every 0.25 seconds
  mov r0, 4000 @clock divisor
  mov r1, 5000 @count
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
  ldr r5, =current_index @load current_index memory address
  ldr r6, [r5] @load current_index
  ldr r7, =frequency @load frequency memory address
  ldr r8, [r7, r6] @load current frequency
  mov r4, 0x7fff @temp variable holding amplitude
  GPIOx_IDR_read D, 0 @read value to get voltage (rise 1 or fall 0)
  beq silence @if zero, play silence
  bne play @if one, play sound

  silence:
    mov r4, #0 @amplitude set to zero

  play:
    mov r0, r8 @move frequency to parameter r0
    mov r1, r4 @move amplitude to parameter r1
    bl wave_change @change waveform accordingly

  EXTI_PR_clear_pending 0 @clear pending interrupt pin 0
  pop {r4-r11, lr}
  bx lr
.size EXTI0_IRQHandler, .-EXTI0_IRQHandler

@pitch change line interrupt handler function
.type EXTI3_IRQHandler, %function
EXTI3_IRQHandler:
  push {r4-r11, lr}
  ldr r4, =current_index @load current_index memory address
  ldr r5, [r4] @load current_index
  mov r6, #32 @set index out of bounds
  cmp r6, r5 
  beq reset_index @reset index if greater than 28
  bne increase @otherwise increase index

  reset_index:
    mov r5, #0 @reset current_index

  increase:
    ldr r8, =frequency @load frequency memory address
    ldr r9, [r8, r5] @load new frequency from table
    add r5, r5, #4 @increase current_index by one
    str r5, [r4] @store new current_index
  
  mov r0, r9 @move frequency to parameter r0
    
  EXTI_PR_clear_pending 3 @clear pending interrupt pin 3
  pop {r4-r11, lr}
  bx lr
.size EXTI3_IRQHandler, .-EXTI3_IRQHandler

.data
.align 2 @ align memory addresses to a word boundry (leave here)
@ \/ memory entries go below \/
frequency: @stores frequencies (scaled by a factor of 100)
  .word 22000, 24694, 26163, 29366, 32963, 36999, 39200, 44000

current_index: @stores current frequency index
  .word 0