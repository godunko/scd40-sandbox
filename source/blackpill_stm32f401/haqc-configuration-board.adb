--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.USART.Configuration_Utilities;

package body HAQC.Configuration.Board is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      UART_Configuration : A0B.STM32F401.USART.Asynchronous_Configuration;

   begin
      A0B.STM32F401.USART.Configuration_Utilities.Compute_Configuration
        (Peripheral_Frequency => 84_000_000,
         Baud_Rate            => 115_200,
         Configuration        => UART_Configuration);
      UART1.USART1_Asynchronous.Configure (UART_Configuration);

      I2C1.I2C1.Configure;

      SPI.Configure;

      LCD_RESET_Pin.Configure_Output
        (Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
      LCD_DC_Pin.Configure_Output
        (Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
      LCD_LED_Pin.Configure_Output
        (Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.No);
   end Initialize;

end HAQC.Configuration.Board;
