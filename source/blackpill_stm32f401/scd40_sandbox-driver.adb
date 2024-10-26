--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.ARMv7M.SysTick_Clock_Timer;
--  with A0B.Delays;
--  with A0B.I2C.STM32H723_I2C.I2C4;
with A0B.STM32F401.SVD.FLASH; use A0B.STM32F401.SVD.FLASH;
--  with A0B.STM32H723.SVD.I2C;  use A0B.STM32H723.SVD.I2C;
--  with A0B.STM32H723.SVD.RCC;  use A0B.STM32H723.SVD.RCC;
--  with A0B.Time;
--  with A0B.Types;
with A0B.Tasking;

--  with SCD40_Sandbox.BH1750;
--  with SCD40_Sandbox.BME280;
--  with SCD40_Sandbox.Display;
with HAQC.Configuration.Board;
--  with SCD40_Sandbox.Globals;
--  with SCD40_Sandbox.SCD40;
--  with SCD40_Sandbox.System_Clocks;
--  with SCD40_Sandbox.Touch;
with HAQC.Sensors.BME280;
with HAQC.UI;
with HAQC.GUI;

procedure SCD40_Sandbox.Driver is
begin
   --  FLASH_Periph.ACR.DCEN   := True;
   --  FLASH_Periph.ACR.ICEN   := True;
   --  FLASH_Periph.ACR.PRFTEN := True;

   A0B.ARMv7M.SysTick_Clock_Timer.Initialize
     (Use_Processor_Clock => True,
      Clock_Frequency     => 84_000_000);
   A0B.Tasking.Initialize (16#400#);

   HAQC.Configuration.Board.Initialize;

   HAQC.Sensors.BME280.Register_Task;
   HAQC.UI.Register_Task;
   HAQC.GUI.Register_Task;

   A0B.Tasking.Run;
end SCD40_Sandbox.Driver;
