--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.ARMv7M.SysTick;
with A0B.Delays;
with A0B.I2C.STM32H723_I2C.I2C4;
with A0B.SVD.STM32H723.GPIO; use A0B.SVD.STM32H723.GPIO;
with A0B.SVD.STM32H723.I2C;  use A0B.SVD.STM32H723.I2C;
with A0B.SVD.STM32H723.RCC;  use A0B.SVD.STM32H723.RCC;
with A0B.Time;
with A0B.Types;

with SCD40_Sandbox.BH1750;
with SCD40_Sandbox.BME280;
with SCD40_Sandbox.Display;
with SCD40_Sandbox.Globals;
with SCD40_Sandbox.SCD40;
with SCD40_Sandbox.System_Clocks;
with SCD40_Sandbox.Touch;

--  with LADO.Acquisition;

procedure SCD40_Sandbox.Main is
begin
   A0B.ARMv7M.SysTick.Initialize (True, 520_000_000);
   SCD40_Sandbox.System_Clocks.Initialize;

   --  LADO.Acquisition.Initialize;

   --  Select I2C4 clock source

   declare
      Val : D3CCIPR_Register := RCC_Periph.D3CCIPR;

   begin
      Val.I2C4SEL := 2#00#;  --  rcc_pclk4

      RCC_Periph.D3CCIPR := Val;
   end;

   --  Enable I2C4 peripheral clock

   declare
      Val : APB4ENR_Register := RCC_Periph.APB4ENR;

   begin
      Val.I2C4EN := True;

      RCC_Periph.APB4ENR := Val;
   end;

   --  Enable GPIOF peripheral clock

   declare
      Val : AHB4ENR_Register := RCC_Periph.AHB4ENR;

   begin
      Val.GPIOFEN := True;

      RCC_Periph.AHB4ENR := Val;
   end;

   --  Configure SCL line

   GPIOF_Periph.OSPEEDR.Arr (14) := 2#00#;   --  Low speed
   GPIOF_Periph.OTYPER.OT.Arr (14) := True;  --  Open drain
   GPIOF_Periph.PUPDR.Arr (14) := 2#00#;     --  No pullup, no pulldown
   GPIOF_Periph.AFRH.Arr (14) := 4;          --  Alternate function 4
   GPIOF_Periph.MODER.Arr (14) := 2#10#;     --  Alternate function

   --  Configure SDA line

   GPIOF_Periph.OSPEEDR.Arr (15) := 2#00#;   --  Low speed
   GPIOF_Periph.OTYPER.OT.Arr (15) := True;  --  Open drain
   GPIOF_Periph.PUPDR.Arr (15) := 2#00#;     --  No pullup, no pulldown
   GPIOF_Periph.AFRH.Arr (15) := 4;          --  Alternate function 4
   GPIOF_Periph.MODER.Arr (15) := 2#10#;     --  Alternate function

   A0B.I2C.STM32H723_I2C.I2C4.I2C4.Configure;

   ---------------------------------------------------------------------------

   SCD40_Sandbox.Display.Initialize;
   --  LADO.Acquisition.Run;
   SCD40_Sandbox.BME280.Initialize;
   SCD40_Sandbox.BH1750.Initialize;
   SCD40_Sandbox.SCD40.Initialize;
   SCD40_Sandbox.Touch.Initialize;

   SCD40_Sandbox.BME280.Configure
     (Mode                     => BME280.Normal,
      Pressure_Oversampling    => 16,
      Temperature_Oversampling => 16,
      Humidity_Oversampling    => 16);

   SCD40_Sandbox.SCD40.Configure;

   loop
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (250));

      SCD40_Sandbox.Touch.Get_Touch;
      SCD40_Sandbox.Display.Redraw_Touch;

      --  SCD40_Sandbox.Display.Redraw;

      SCD40_Sandbox.SCD40.Get_Data_Ready_Status;
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (1));

      if Globals.Ready then
         declare
            Data : constant SCD40_Sandbox.BME280.Sensor_Data
              := BME280.Get_Sensor_Data;

         begin
            BME280.Get_Compensated
              (Data        => Data,
               Pressure    => Globals.Pressure,
               Temperature => Globals.Temperature,
               Humitidy    => Globals.Humidity);
         end;

         Globals.Light := BH1750.Get_Light_Value;

         SCD40_Sandbox.SCD40.Set_Ambient_Pressure
           (A0B.Types.Unsigned_32'Min
              (110_000,
               A0B.Types.Unsigned_32'Max
                 (70_100, A0B.Types.Unsigned_32 (Globals.Pressure))));
         A0B.Delays.Delay_For (A0B.Time.Milliseconds (1));

         SCD40_Sandbox.SCD40.Read_Measurement;
         A0B.Delays.Delay_For (A0B.Time.Milliseconds (1));

         SCD40_Sandbox.Display.Redraw;
      end if;
   end loop;
end SCD40_Sandbox.Main;
