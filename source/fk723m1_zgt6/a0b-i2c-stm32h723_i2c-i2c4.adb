--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body A0B.I2C.STM32H723_I2C.I2C4 is

   procedure I2C4_EV_Handler
     with Export, Convention => C, External_Name => "I2C4_EV_Handler";

   procedure I2C4_ER_Handler
     with Export, Convention => C, External_Name => "I2C4_ER_Handler";

   ---------------------
   -- I2C4_ER_Handler --
   ---------------------

   procedure I2C4_ER_Handler is
   begin
      I2C4.On_Error_Interrupt;
   end I2C4_ER_Handler;

   ---------------------
   -- I2C4_EV_Handler --
   ---------------------

   procedure I2C4_EV_Handler is
   begin
      I2C4.On_Event_Interrupt;
   end I2C4_EV_Handler;

end A0B.I2C.STM32H723_I2C.I2C4;
