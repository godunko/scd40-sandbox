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

   --  use type A0B.Types.Unsigned_64;

   --  Device_Address : constant A0B.Types.Unsigned_7 := MPU6XXX_Address;
   --  Register_Address : constant A0B.Types.Unsigned_8 := 117;
   --  Device_Address : constant A0B.Types.Unsigned_7 := BNO055_I2C_Address;
   --  Register_Address : constant A0B.Types.Unsigned_8 := 0;
   --  Device_Address : constant A0B.Types.Unsigned_7 := SCD40_I2C_Address;

   --  Write_Data : SDC40_Sandbox.I2C.Unsigned_8_Array (0 .. 1);
   --  Read_Data  : SDC40_Sandbox.I2C.Unsigned_8_Array (0 .. 2);
   --  CRC        : A0B.Types.Unsigned_8 with Volatile;

   --  Ready    : Boolean := False with Volatile;
   --  Idle     : A0B.Types.Unsigned_64 := 0 with Volatile;

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

   --  CRC := Sensirion_CRC (Read_Data (0 .. 1));

   ---------------------------------------------------------------------------

   --  --  Initiate communication (address phase)
   --
   --  declare
   --     use type A0B.Types.Unsigned_10;
   --
   --     Val : CR2_Register := I2C4_Periph.CR2;
   --
   --  begin
   --     Val.ADD10    := False;
   --     --  Val.SADD.Val := A0B.Types.Unsigned_10 (MPU6XXX_Address) * 2;
   --
   --     Val.SADD.Val := A0B.Types.Unsigned_10 (Device_Id_I2C_Address) * 2;
   --     --  Val.SADD.Val := A0B.Types.Unsigned_10 (BNO055_I2C_Address);
   --     --  Val.SADD   := A0B.Types.Unsigned_10 (SDC40_I2C_Address);
   --     Val.RD_WRN   := False;  --  Master requests a write transfer.
   --     Val.NBYTES   := 1;
   --
   --     Val.AUTOEND  := False;
   --     Val.RELOAD   := False;
   --
   --     I2C4_Periph.CR2 := Val;
   --  end;
   --
   --  --  Send START condition
   --
   --  I2C4_Periph.CR2.START := True;
   --
   --  --  while not I2C4_Periph.ISR.TXIS loop
   --  --     null;
   --  --  end loop;
   --  --
   --  --  I2C4_Periph.TXDR.TXDATA := 117;
   --  --
   --  --  --  Wait till end of the trasfer
   --  --
   --  --  while not I2C4_Periph.ISR.TC loop
   --  --     null;
   --  --  end loop;
   --  --
   --  --  --  Prepare to read
   --  --
   --  --  declare
   --  --     Val : CR2_Register := I2C4_Periph.CR2;
   --  --
   --  --  begin
   --  --     --  Val.ADD10  := False;
   --  --     --  Val.SADD   := Device_Id_I2C_Address;
   --  --     --  Val.SADD   := A0B.Types.Unsigned_10 (SDC40_I2C_Address);
   --  --     Val.RD_WRN := True;  --  Master requests a write transfer.
   --  --     Val.NBYTES := 3;
   --  --
   --  --     Val.AUTOEND := True;
   --  --     --  Val.RELOAD  := False;
   --  --
   --  --     I2C4_Periph.CR2 := Val;
   --  --  end;
   --  --
   --  --  --  Send ReSTART condition
   --  --
   --  --  I2C4_Periph.CR2.START := True;
   --  --
   --  --  --  Receive 1-st byte
   --  --
   --  --  while not I2C4_Periph.ISR.RXNE loop
   --  --     null;
   --  --  end loop;
   --  --
   --  --  B1 := I2C4_Periph.RXDR.RXDATA;
   --
   --  --  Send SDC40 Device Address
   --
   --  while not I2C4_Periph.ISR.TXIS loop
   --     null;
   --  end loop;
   --
   --  I2C4_Periph.TXDR.TXDATA :=
   --    A0B.Types.Shift_Left (A0B.Types.Unsigned_8 (Device_Address), 1);
   --
   --  --  Wait till end of the trasfer
   --
   --  while not I2C4_Periph.ISR.TC loop
   --     null;
   --  end loop;
   --
   --  --  Prepare to read
   --
   --  declare
   --     Val : CR2_Register := I2C4_Periph.CR2;
   --
   --  begin
   --     Val.RD_WRN := True;  --  Master requests a write transfer.
   --     Val.NBYTES := 3;
   --
   --     Val.AUTOEND := True;
   --     --  Val.RELOAD  := False;
   --
   --     I2C4_Periph.CR2 := Val;
   --  end;
   --
   --  --  Send ReSTART condition
   --
   --  I2C4_Periph.CR2.START := True;
   --
   --  --  Receive 1-st byte
   --
   --  while not I2C4_Periph.ISR.RXNE loop
   --     null;
   --  end loop;
   --
   --  B1 := I2C4_Periph.RXDR.RXDATA;
   --
   --  --  Receive 2-st byte
   --
   --  while not I2C4_Periph.ISR.RXNE loop
   --     null;
   --  end loop;
   --
   --  B2 := I2C4_Periph.RXDR.RXDATA;
   --
   --  --  Receive 3-st byte
   --
   --  while not I2C4_Periph.ISR.RXNE loop
   --     null;
   --  end loop;
   --
   --  B3 := I2C4_Periph.RXDR.RXDATA;

   --  loop
   --     null;
   --  end loop;
end SCD40_Sandbox.Main;
