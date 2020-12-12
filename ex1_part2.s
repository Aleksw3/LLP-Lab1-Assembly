.syntax unified

  .include "efm32gg.s" // Additional definitions added

.section .vectors

  .long   stack_top               /* Top of Stack                 */
  .long   _reset                  /* Reset Handler                */
  .long   dummy_handler           /* NMI Handler                  */
  .long   dummy_handler           /* Hard Fault Handler           */
  .long   dummy_handler           /* MPU Fault Handler            */
  .long   dummy_handler           /* Bus Fault Handler            */
  .long   dummy_handler           /* Usage Fault Handler          */
  .long   dummy_handler           /* Reserved                     */
  .long   dummy_handler           /* Reserved                     */
  .long   dummy_handler           /* Reserved                     */
  .long   dummy_handler           /* Reserved                     */
  .long   dummy_handler           /* SVCall Handler               */
  .long   dummy_handler           /* Debug Monitor Handler        */
  .long   dummy_handler           /* Reserved                     */
  .long   dummy_handler           /* PendSV Handler               */
  .long   dummy_handler           /* SysTick Handler              */

  /* External Interrupts */
  .long   dummy_handler
  .long   gpio_handler            /* GPIO even handler */
  .long   dummy_handler
  .long   dummy_handler
  .long   dummy_handler
  .long   dummy_handler
  .long   dummy_handler
  .long   dummy_handler
  .long   dummy_handler
  .long   dummy_handler
  .long   dummy_handler
  .long   gpio_handler           /* GPIO odd handler */
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

	      .section .text

.globl  _reset
.type   _reset, %function

.thumb_func
_reset: 
	// Load base address of clock management unit(CMU)
	ldr r1, =CMU_BASE
	// Load current value of the High frequency peripheral clock enable register
	ldr r2, [r1, #CMU_HFPERCLKEN0]   

	// Set bit 13 to 1 to enable clock for GPIO
      ldr r3, =GPIO_CLK_ENABLE_BIT
	orr r2, r2, r3 
	str r2, [r1, #CMU_HFPERCLKEN0]    

	//load base address of LED GPIOs
	ldr r0, =GPIO_PA_BASE

	// Set current level of GPIO pins to high = 20mA
	mov r2, #0x02
	str r2, [r0, #GPIO_CTRL] 

	// Configure GPIO pins for LEDS as push-pull outputs with drive strength set by the configuration of drivemode(GPIO_CTRL)
	ldr r2, =0x55555555
	str r2, [r0, #GPIO_MODEH]

	// Load base address of button GPIOs
	ldr r1, =GPIO_PC_BASE

	// Configure button GPIOs as inputs with a pull-up filter (glitch supression filter)
	ldr r2, =0x33333333
	str r2, [r1, #GPIO_MODEL]

	// Enable pull-up for inputs
	ldr r2, =0xFF
	str r2, [r1, #GPIO_DOUT]

	// Load base address for GPIO
	ldr r4, =GPIO_BASE

	// Enable interrupt for pins of GPIO on PC by setting bit 2 to 1
	ldr r2, =0x22222222
	str r2, [r4, #GPIO_EXTIPSELL]

	ldr r2, =0xFF
	// Enable rising edge trigger for IRQ[n]
	str r2, [r4, #GPIO_EXTIFALL]
	// Enable falling edge trigger for IRQ[n]
	str r2, [r4, #GPIO_EXTIRISE]
	// Enable interrupt IRQ[n]
	str r2, [r4, #GPIO_IEN]


	// Enable interrupts for even and odd GPIO pins
	ldr r3, =ISER0
	ldr r2, =ISER0_BIT_ODD | ISER0_BIT_EVEN
	str r2, [r3]

    //enable deep sleep and sleep entry after interrupt handling in the system control register
	ldr r2, =SCR
	ldr r3, =DEEPSLEEP_EN | SLEEPONEXIT_EN
	str r3, [r2]

	// Go to sleep(Wait for interrupt)
	WFI

	// End of function 
	bx lr 
	
.thumb_func
gpio_handler:
	// Get interrupt flags
	ldr r3, [r4, #GPIO_IF]  
	
	// Get status of buttons (pushed or unpushed)
	ldr r2, [r1, #GPIO_DIN]

	// left shift values by 8 and set LEDs accordingly
	lsl r2, r2, #8
	str r2, [r0, #GPIO_DOUT]		

	// Clear interrupt flag register 
	str r3, [r4, #GPIO_IFC] 

	// End of function
	bx lr	
	
.thumb_func
dummy_handler:  
        bx lr  // do nothing