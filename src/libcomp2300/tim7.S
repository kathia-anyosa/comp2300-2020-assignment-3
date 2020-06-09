.syntax unified

@ ------------------------ TIM7 ------------------------
@ Timer 7 features a 16-bit prescaler and a 16-bit counter.
@ The prescaler divides the main clock (which runs at 80MHz according to definition in HAL),
@ and the counter counts up according to the divided clock.
@ When the counter counts up to the reload value,
@ an update event is triggered and an interrupt is fired.

@ --------------------- Module Interface --------------------
.global tim7_init, TIM7_IRQHandler

@ --------------------- Implementation --------------------
.include "libcomp2300/macros.S"

.set CK_PSC, 80000000

.type tim7_init, %function
@ tim7_init takes two parameters, clock divisor and count (in each case, only the lower 16-bits will be used)
@
@ the clock divisor determines how many CPU cycles per TIM7 tick
@ the count determines how many TIM7 ticks between the TIM7 interrupts firing
@
@ Remember that in the assignment template, the main clock is at 80MHz
@ so, for example, clock divisor = 10000 and count = 8000 will give a 1Hz interrupt
@ 
@ In short, (seconds between interrupts) = (clock divisor * count) / 80000000
@
@ --parameters--
@ r0: clock divisor (prescaler + 1)
@ r1: count
tim7_init:
  push {r4-r5, lr}
  mov r4, r0
  mov r5, r1

  @ enable peripheral clock
  @ RCC_APB1ENR_set 5
  ldr r0, =ADR_RCC
  ldr r1, =OFS_RCC_APB1ENR
  ldr r2, =5
  bl set_bit

  @ Set prescaler
  @ the counter clock frequency f(CK_CNT) = f(CK_PSC) / (prescaler + 1)
  @ since clock divisor = prescaler + 1,
  @ subtract 1 here to get the prescaler
  @ See Section 29.4.7
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_PSC
  sub r4, 1
  strh r4, [r0, r1]

  @ set counter reload value (Section 29.4.8)
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_ARR
  strh r5, [r0, r1]

  @ TIM7_EGR (Section 29.4.5)
  ldr r0, =ADR_TIM7
  ldr r1, =0x14
  ldr r2, [r0, r1]
  orr r2, 0b1
  str r2, [r0, r1]

  @ clear interrupt (Section 29.4.4)
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_SR
  mov r2, 0
  bl clear_bit

  @ enable timer 7  (Section 29.4.1s)
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_CR1
  mov r2, 0
  bl set_bit

  @ enable TIM7 DMA/interrupt (Section 29.4.3)
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_DIER
  mov r2, 0
  bl set_bit

  @ enable TIM7 interrupt in NVIC
  NVIC_set ISER 55  @ TIM7 is at position 55

  @ set debug freeze (Section 44.16.4)
  ldr r0, =ADR_DBGMCU_APB1FZR1
  mov r1, 0
  mov r2, 5
  bl set_bit

  @ NOTE: you MAY want to configure the priority of TIM7.
  @ put your code here if that's the case

  mov r0, #6 @EXTI0 position
  mov r1, 0b0000 @new priority
  bl NVIC_IPR_set_priority @set EXTI0 to highest priority

  mov r0, #55 @TIM7 position
  mov r1, 0b1111 @new priority
  bl NVIC_IPR_set_priority @set TIM7 to lowest priority

  bl sync
  pop {r4-r5, lr}
  bx lr
.size tim7_init, .-tim7_init

.type TIM7_IRQHandler, %function
@ --parameters--
@ none
TIM7_IRQHandler:
  push {r4-r11, lr}
  @ Your interrupt handler code goes here
  ldr r8, =sequence_counter @load sequence_counter memory address
  ldr r9, [r8] @load sequence_counter
  cmp r9, #38 @set index out of bounds
  beq reset_sequence @reset index if equal than 38
  bne continue_sequence @otherwise continue

  reset_sequence:
    mov r9, #0 @reset sequence_counter

  continue_sequence:
    tst r9, #1 @check if sequence_counter is even or odd
    beq toggle_sound_on @if even, toggle sound on
    bne toggle_sound_off @if odd, toggle sound off

  toggle_sound_on:
    GPIOx_ODR_set E, 14 @output 1 (trigger rise in note on/off line)
    add r9, #1 @increase sequence_counter by one
    str r9, [r8] @store sequence_counter in memory
    b clear

  toggle_sound_off:
    GPIOx_ODR_clear E, 14 @output 0 (trigger fall in note on/off line)
    add r9, #1 @increase sequence_counter by one
    str r9, [r8] @store sequence_counter in memory
    ldr r5, =pitch_counter @load pitch_counter memory address
    ldr r6, [r5] @load pitch_counter
    cmp r6, #18 @set index out of bounds
    beq restart_pitch_counter @reset index if equal to 18
    bne continue @otherwise continue

    restart_pitch_counter:
      mov r6, #0 @reset pitch_counter
      b toggle_10x @FIXME?

    continue:
      mov r7, #10 @set max index for while loop
      cmp r6, r7
      bls part_one @while loop with condition: pitch_counter <= 10
      bgt toggle_7x @while loop with condition: pitch_counter > 10

    part_one:
      tst r6, #1 @check if counter is odd
      beq toggle_10x @if even, toggle 10 times
      bne toggle_7x @if odd, toggle 7 times

    toggle_10x: @toggle output of pitch change line 20 times to trigger 10 rises
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      add r6, #1 @increase pitch_counter by one
      str r6, [r5] @store pitch_counter in memory
      b clear

    toggle_7x: @toggle output of pitch change line 14 times to trigger 7 rises
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      GPIOx_ODR_toggle E, 15
      add r6, #1 @increase pitch_counter by one
      str r6, [r5] @store pitch_counter in memory
      b clear

  clear: @ Clear interrupt (Section 29.4.4)
    ldr r0, =ADR_TIM7
    ldr r1, =OFS_TIMx_SR
    mov r2, 0
    bl clear_bit
    bl sync
    pop {r4-r11, lr}
    bx lr
.size TIM7_IRQHandler, .-TIM7_IRQHandler

.data
pitch_counter: @stores pitch_counter
  .word 0

sequence_counter: @stores sequence_counter
  .word 0