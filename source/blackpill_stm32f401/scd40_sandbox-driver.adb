--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.ARMv7M.SysTick;
--  with A0B.Delays;
--  with A0B.I2C.STM32H723_I2C.I2C4;
--  with A0B.STM32H723.SVD.GPIO; use A0B.STM32H723.SVD.GPIO;
--  with A0B.STM32H723.SVD.I2C;  use A0B.STM32H723.SVD.I2C;
--  with A0B.STM32H723.SVD.RCC;  use A0B.STM32H723.SVD.RCC;
--  with A0B.Time;
--  with A0B.Types;
--
--  with SCD40_Sandbox.BH1750;
--  with SCD40_Sandbox.BME280;
--  with SCD40_Sandbox.Display;
--  with SCD40_Sandbox.Globals;
--  with SCD40_Sandbox.SCD40;
--  with SCD40_Sandbox.System_Clocks;
--  with SCD40_Sandbox.Touch;
--
--  with LADO.Acquisition;

procedure SCD40_Sandbox.Driver is
begin
   A0B.ARMv7M.SysTick.Initialize
     (Use_Processor_Clock => True,
      Clock_Frequency     => 84_000_000);

   null;
end SCD40_Sandbox.Driver;
