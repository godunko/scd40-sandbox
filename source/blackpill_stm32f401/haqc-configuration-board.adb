--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  with A0B.Delays;
--  with A0B.I2C.SCD40;
--  with A0B.I2C.STM32H723_I2C.I2C4;
--  with A
--  with A0B.STM32F401.I2C;
--  with A0B.SCD40;
--  with A0B.Time;
--
--  with SCD40_Sandbox.Await;
--  with SCD40_Sandbox.Globals;

with A0B.STM32F401.USART.Configuration_Utilities;

package body HAQC.Configuration.Board is

   --  IMU_INT_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB15;

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
   end Initialize;

end HAQC.Configuration.Board;
