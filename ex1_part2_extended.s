.syntax unified

.include "efm32gg.s"

.section .vectors

.long   stack_top               /* Top of Stack               00  */
.long   _reset                  /* Reset Handler              04  */
.long   dummy_handler           /* NMI Handler                08  */
.long   dummy_handler           /* Hard Fault Handler         0C  */
.long   dummy_handler           /* MPU Fault Handler          10  */
.long   dummy_handler           /* Bus Fault Handler          14  */
.long   dummy_handler           /* Usage Fault Handler        18  */
.long   dummy_handler           /* Reserved                   1C  */
.long   dummy_handler           /* Reserved                   20  */
.long   dummy_handler           /* Reserved                   24  */
.long   dummy_handler           /* Reserved                   28  */
.long   dummy_handler           /* SVCall Handler             2C  */
.long   dummy_handler           /* Debug Monitor Handler      30  */
.long   dummy_handler           /* Reserved                   34  */
.long   dummy_handler           /* PendSV Handler             38  */
.long   dummy_handler           /* SysTick Handler            3C  */

/* External Interrupts */
.long   dummy_handler
.long   gpio_handler            /* GPIO even handler 44 */
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   gpio_handler            /* GPIO odd handler 6C */
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler
.long   dummy_handler

/////////////////////////////////////////////////////////////////////////////
// Start of text section
//
/////////////////////////////////////////////////////////////////////////////
.section .text

gpio_innit:
    // Setup enable for gpio clk
    ldr r0, =CMU_BASE
    ldr r1, [r0, #CMU_HFPERCLKEN0]
    orr r2, r1, 0x00002000
    str r2, [r0,#CMU_HFPERCLKEN0]

    // Setup output for LED
    ldr r0, =GPIO_PA_BASE
    // Setting drive strength high
    mov r5, #0x01
    str r5, [r0, #GPIO_CTRL]
    // Setting pins 8-15 to output
    ldr r5, =0x55555555
    str r5, [r0, #GPIO_MODEH]
    // Initializing LED to off
    ldr r4, =0xFF00
    str r4, [r0, #GPIO_DOUT]

    // Setup input for buttons
    ldr r0, =GPIO_PC_BASE
    // Setting pins 8-15 to output
    ldr r5, =0x33333333
    str r5, [r0, #GPIO_MODEL]
    // Enabling internal pull-up
    ldr r5, =0xFF
    str r5, [r0, #GPIO_DOUT]

    // Setup interrupt for gpio
    ldr r0, =GPIO_BASE
    // Selecting which port to trigger the interrupt flag
    ldr r5, =0x22222222
    str r5, [r0, #GPIO_EXTIPSELL]
    // Setting interrupt on 1->0 transition
    ldr r4, =0xFF
    str r4, [r0, #GPIO_EXTIFALL]
    str r4, [r0, #GPIO_IEN]
    // Enabling interrupt handling
    ldr r0, =ISER0
    ldr r5, =0x802 //bit 1 and 11 to enable interrupt on odd and even GPIO pins
    str r5, [r0]

    // initializing the counter to 0
    ldr r8, =0xFF
    ldr r5, =0xFF

    // Enable deep sleep and sleep entry after interrupt handling
    ldr r2, =SCR
    mov r3, #0x06
    str r3, [r2]

    // Go to sleep(Wait for interrupt)
    WFI

    bx lr

.globl  _reset
.type   _reset, %function
.thumb_func
_reset:
b gpio_innit

/////////////////////////////////////////////////////////////////////////////
//
// GPIO handler
// The CPU will jump here when there is a GPIO interrupt
//
/////////////////////////////////////////////////////////////////////////////

.thumb_func
gpio_handler:
    ldr r2, =GPIO_BASE
    ldr r6, [r2, #GPIO_IF]  // Loading interupt flags

    ldr r1, =GPIO_PA_BASE
    ldr r0, =GPIO_PC_BASE
    ldr r4, [r0, #GPIO_DIN] // Loading input from GPIO_PC
    AND r3, r4, #0xFF // Combining a mask with input to get status of switches on pin 0 to 7

    /* We made a bitwise counter with the result displayed on the LEDs.
       Switches 1..4 has these functions: reset LEDs, count up, change LED drivemode and count down
       We are comparing GPIO_DIN against different masks to determine if buttons is pressed
       After testing the four switches we update the LED accordingly */

    // Switch1 for resetting the counter to 0
    cmp r3, #0xFE // Testing if bit 0 is low => SW1 active
    beq if_SW1 //Go

    // Switch2 for count up
    cmp r3, #0xFD // Testing if bit 1 is low => SW2 active
    beq if_SW2

    // Switch3 for light strength/drivemode
    cmp r3, #0xFB // Testing if bit 2 is low => SW3 active
    beq if_SW3

    // Switch4 for count down
    cmp r3, #0xF7 // Testing if bit 3 is low => SW4 active
    beq if_SW4
    b clr_flg

    if_SW1:
        ldr r8, =0xFF // Default value for LED off
        b endif

    if_SW2:
        // Decreasing the number to increase the counter, since the output is inverse
        sub r8, r8, #1
        b endif

    if_SW3:
        cmp r5, #3 // Since drivemode is between 0 and 3, we "wrap" to avoid overflow
        beq wrap
        add r5, r5, #1 // Drivemode = drivemode + 1
        b end_SW3
    wrap:
        mov r5, #0 // Drivemode = 0
        b end_SW3
    end_SW3:
        str r5, [r1, #GPIO_CTRL] // Updating the drivemode
        b clr_flg

    if_SW4:
        cmp r8, #0xFF
        beq clr_flg
        // Increasing the number to decrease the counter, since the output is inverse
        add r8, r8, #1
    // End of the if-statements for SW1..4

    endif:
        // Shifting r8 one byte left, and updating LED output
        lsl r4, r8, #8
        str r4, [r1, #GPIO_DOUT]

    clr_flg:
    // Clearing interupt flags
    str r6, [r2, #GPIO_IFC]
    // Return to sleep
    bx lr

/////////////////////////////////////////////////////////////////////////////

.thumb_func
dummy_handler:
bx lr  // do nothing