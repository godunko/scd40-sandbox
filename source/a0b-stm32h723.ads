--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.ARMv7M;

package A0B.STM32H723
  with Preelaborate
is

   I2C1_EV : constant A0B.ARMv7M.External_Interrupt_Number := 31;
   I2C1_ER : constant A0B.ARMv7M.External_Interrupt_Number := 32;
   I2C2_EV : constant A0B.ARMv7M.External_Interrupt_Number := 33;
   I2C2_ER : constant A0B.ARMv7M.External_Interrupt_Number := 34;

   I2C3_EV : constant A0B.ARMv7M.External_Interrupt_Number := 72;
   I2C3_ER : constant A0B.ARMv7M.External_Interrupt_Number := 73;

   I2C4_EV : constant A0B.ARMv7M.External_Interrupt_Number := 95;
   I2C4_ER : constant A0B.ARMv7M.External_Interrupt_Number := 96;

   I2C5_EV : constant A0B.ARMv7M.External_Interrupt_Number := 157;
   I2C5_ER : constant A0B.ARMv7M.External_Interrupt_Number := 158;

end A0B.STM32H723;
