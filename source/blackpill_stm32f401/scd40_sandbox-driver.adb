--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.ARMv7M.SysTick_Clock_Timer;
--  with A0B.STM32F401.SVD.FLASH; use A0B.STM32F401.SVD.FLASH;
with A0B.Tasking;

with HAQC.Configuration.Board;
with HAQC.Sensors.BME280;
with HAQC.Sensors.SCD40;
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
   HAQC.Sensors.SCD40.Register_Task;
   HAQC.UI.Register_Task;
   HAQC.GUI.Register_Task;

   A0B.Tasking.Run;
end SCD40_Sandbox.Driver;
