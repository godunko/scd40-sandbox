--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with System.Storage_Elements;

with A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.Memory_Protection_Unit;
with A0B.Callbacks.Generic_Parameterless;
with A0B.SVD.STM32H723.FMC;  use A0B.SVD.STM32H723.FMC;
with A0B.SVD.STM32H723.GPIO; use A0B.SVD.STM32H723.GPIO;
with A0B.SVD.STM32H723.RCC;  use A0B.SVD.STM32H723.RCC;
with A0B.Time.Clock;
with A0B.Timer;

package body SCD40_Sandbox.Display is

   DIVM2   : constant := 25;
   MULN2   : constant := 240 - 1;
   DIVR2   : constant := 2 - 1;
   PLL2GRE : constant := 2#00#;

   procedure Configure_PLL2;
   --  Configure PLL2R @120MHz to be used as clock for FMC.

   procedure Configure_FMC;

   procedure Configure_MPU;

   procedure Configure_GPIO;

   type NT35510_Command is new A0B.Types.Unsigned_16;

   SLPOUT : constant := 16#1100#;
   DISPON : constant := 16#2900#;
   CASET  : constant := 16#2A00#;
   CASET0 : constant := CASET + 0;
   CASET1 : constant := CASET + 1;
   CASET2 : constant := CASET + 2;
   CASET3 : constant := CASET + 3;
   RASET  : constant := 16#2B00#;
   RASET0 : constant := RASET + 0;
   RASET1 : constant := RASET + 1;
   RASET2 : constant := RASET + 2;
   RASET3 : constant := RASET + 3;
   RAMWR  : constant := 16#2C00#;
   MADCTL : constant := 16#3600#;
   COLMOD : constant := 16#3A00#;

   procedure Command (Command : NT35510_Command);

   procedure Write (Data : A0B.Types.Unsigned_16);

   procedure Command_Write
     (Command : NT35510_Command;
      Data    : A0B.Types.Unsigned_16);

   Command_Register : NT35510_Command
     with Import,
          Convention => C,
          Address    => System.Storage_Elements.To_Address (16#6000_0000#);
   Data_Register    : A0B.Types.Unsigned_16
     with Import,
          Convention => C,
          Address    => System.Storage_Elements.To_Address (16#6000_0020#);

   procedure Delay_For (Interval : A0B.Time.Time_Span);

   procedure On_Delay;

   package On_Delay_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Delay);

   Delay_Timeout : aliased A0B.Timer.Timeout_Control_Block;
   Delay_Done    : Boolean := True with Volatile;

   procedure Clear;
   --  Clear content of the screen.

   --  type Unsigned_1_Array is
   --    array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_1;

   C_RGB : constant := 16#001F#;
   T_RGB : constant := 16#07E0#;
   H_RGB : constant := 16#F800#;

   Clear_Duration : A0B.Time.Duration with Volatile;

   type Point is record
      C : A0B.Types.Unsigned_16;
      T : A0B.Types.Unsigned_16;
      H : A0B.Types.Unsigned_16;
   end record;

   Points : array (A0B.Types.Unsigned_16 range 0 .. 799) of Point :=
     [others => (others => 0)];

   type Unsigned_8_Array is
     array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_8;

   Percent_Sign : constant Unsigned_8_Array :=
     [16#7#, 16#e0#, 16#0#, 16#7f#, 16#e0#, 16#3#, 16#81#, 16#c0#,
      16#1c#, 16#3#, 16#80#, 16#60#, 16#6#, 16#1#, 16#80#, 16#18#,
      16#7#, 16#0#, 16#e0#, 16#ce#, 16#7#, 16#7#, 16#1f#, 16#f8#,
      16#70#, 16#1f#, 16#83#, 16#80#, 16#0#, 16#38#, 16#0#, 16#1#,
      16#c0#, 16#0#, 16#1c#, 16#0#, 16#1#, 16#e0#, 16#0#, 16#e#,
      16#0#, 16#0#, 16#f0#, 16#0#, 16#7#, 16#0#, 16#0#, 16#78#,
      16#0#, 16#3#, 16#80#, 16#f8#, 16#38#, 16#f#, 16#f8#, 16#c0#,
      16#70#, 16#70#, 16#3#, 16#80#, 16#e0#, 16#c#, 16#1#, 16#80#,
      16#30#, 16#6#, 16#0#, 16#e0#, 16#38#, 16#1#, 16#c1#, 16#c0#,
      16#3#, 16#fe#, 16#0#, 16#7#, 16#e0#];

   Digit_Zero : constant Unsigned_8_Array :=
     --  [16#1f#, 16#06#, 16#31#, 16#01#, 16#20#, 16#28#, 16#07#, 16#00#,
     --   16#60#, 16#0c#, 16#01#, 16#80#, 16#30#, 16#06#, 16#00#, 16#c0#,
     --   16#18#, 16#03#, 16#00#, 16#d0#, 16#12#, 16#06#, 16#31#, 16#83#,
     --   16#e0#];
     [16#07#, 16#e0#, 16#0f#, 16#f8#, 16#1c#, 16#3c#, 16#30#, 16#1c#,
      16#30#, 16#0e#, 16#60#, 16#06#, 16#60#, 16#6#, 16#60#, 16#7#,
      16#c0#, 16#03#, 16#c0#, 16#03#, 16#c0#, 16#3#, 16#c0#, 16#3#,
      16#c0#, 16#03#, 16#c0#, 16#03#, 16#c0#, 16#3#, 16#c0#, 16#3#,
      16#c0#, 16#03#, 16#c0#, 16#03#, 16#c0#, 16#3#, 16#c0#, 16#7#,
      16#e0#, 16#06#, 16#60#, 16#06#, 16#60#, 16#6#, 16#70#, 16#c#,
      16#30#, 16#1c#, 16#3c#, 16#38#, 16#1f#, 16#f0#, 16#7#, 16#e0#];
   Digit_One  : constant Unsigned_8_Array :=
     [16#1#, 16#80#, 16#1#, 16#c0#, 16#3#, 16#e0#, 16#3#, 16#30#,
      16#3#, 16#18#, 16#3#, 16#c#, 16#3#, 16#6#, 16#0#, 16#3#,
      16#0#, 16#1#, 16#80#, 16#0#, 16#c0#, 16#0#, 16#60#, 16#0#,
      16#30#, 16#0#, 16#18#, 16#0#, 16#c#, 16#0#, 16#6#, 16#0#,
      16#3#, 16#0#, 16#1#, 16#80#, 16#0#, 16#c0#, 16#0#, 16#60#,
      16#0#, 16#30#, 16#0#, 16#18#, 16#0#, 16#c#, 16#0#, 16#6#,
      16#0#, 16#3#, 16#0#, 16#1#, 16#80#, 16#0#, 16#c0#, 16#3f#,
      16#ff#, 16#ff#, 16#ff#, 16#f0#];
   Digit_Two  : constant Unsigned_8_Array :=
     [16#3#, 16#f0#, 16#7#, 16#fe#, 16#7#, 16#3#, 16#86#, 16#0#,
      16#e6#, 16#0#, 16#3b#, 16#0#, 16#f#, 16#0#, 16#7#, 16#80#,
      16#3#, 16#c0#, 16#1#, 16#e0#, 16#1#, 16#80#, 16#0#, 16#c0#,
      16#0#, 16#c0#, 16#0#, 16#e0#, 16#0#, 16#e0#, 16#1#, 16#c0#,
      16#1#, 16#c0#, 16#3#, 16#80#, 16#3#, 16#80#, 16#3#, 16#0#,
      16#3#, 16#0#, 16#3#, 16#0#, 16#3#, 16#0#, 16#1#, 16#80#,
      16#6#, 16#c0#, 16#3#, 16#60#, 16#1#, 16#b0#, 16#0#, 16#df#,
      16#ff#, 16#ef#, 16#ff#, 16#f0#];
   Digit_Three : constant Unsigned_8_Array :=
     [16#3#, 16#f8#, 16#3#, 16#ff#, 16#81#, 16#c0#, 16#f0#, 16#e0#,
      16#e#, 16#60#, 16#1#, 16#b8#, 16#0#, 16#30#, 16#0#, 16#c#,
      16#0#, 16#3#, 16#0#, 16#0#, 16#c0#, 16#0#, 16#70#, 16#0#,
      16#18#, 16#0#, 16#e#, 16#0#, 16#fe#, 16#0#, 16#3f#, 16#80#,
      16#0#, 16#70#, 16#0#, 16#e#, 16#0#, 16#1#, 16#80#, 16#0#,
      16#30#, 16#0#, 16#c#, 16#0#, 16#3#, 16#0#, 16#0#, 16#c0#,
      16#0#, 16#34#, 16#0#, 16#1d#, 16#80#, 16#6#, 16#30#, 16#3#,
      16#7#, 16#3#, 16#c0#, 16#ff#, 16#c0#, 16#f#, 16#c0#];
   Digit_Four : constant Unsigned_8_Array :=
     [16#0#, 16#3#, 16#0#, 16#0#, 16#70#, 16#0#, 16#f#, 16#0#,
      16#0#, 16#f0#, 16#0#, 16#1b#, 16#0#, 16#3#, 16#30#, 16#0#,
      16#73#, 16#0#, 16#6#, 16#30#, 16#0#, 16#c3#, 16#0#, 16#18#,
      16#30#, 16#3#, 16#3#, 16#0#, 16#70#, 16#30#, 16#6#, 16#3#,
      16#0#, 16#c0#, 16#30#, 16#18#, 16#3#, 16#3#, 16#80#, 16#30#,
      16#70#, 16#3#, 16#6#, 16#0#, 16#30#, 16#ff#, 16#ff#, 16#ff#,
      16#ff#, 16#ff#, 16#0#, 16#3#, 16#0#, 16#0#, 16#30#, 16#0#,
      16#3#, 16#0#, 16#0#, 16#30#, 16#0#, 16#3#, 16#0#, 16#0#,
      16#30#, 16#0#, 16#3f#, 16#f0#, 16#3#, 16#ff#];
   Digit_Five : constant Unsigned_8_Array :=
     [16#f#, 16#ff#, 16#f0#, 16#ff#, 16#ff#, 16#c#, 16#0#, 16#0#,
      16#c0#, 16#0#, 16#c#, 16#0#, 16#0#, 16#c0#, 16#0#, 16#c#,
      16#0#, 16#0#, 16#c0#, 16#0#, 16#c#, 16#0#, 16#0#, 16#c0#,
      16#0#, 16#c#, 16#0#, 16#0#, 16#ff#, 16#e0#, 16#f#, 16#ff#,
      16#80#, 16#0#, 16#3c#, 16#0#, 16#0#, 16#e0#, 16#0#, 16#6#,
      16#0#, 16#0#, 16#30#, 16#0#, 16#3#, 16#0#, 16#0#, 16#30#,
      16#0#, 16#3#, 16#0#, 16#0#, 16#30#, 16#0#, 16#3#, 16#0#,
      16#0#, 16#6c#, 16#0#, 16#e#, 16#e0#, 16#1#, 16#c3#, 16#c0#,
      16#78#, 16#1f#, 16#ff#, 16#0#, 16#3f#, 16#80#];
   Digit_Six : constant Unsigned_8_Array :=
     [16#3#, 16#ff#, 16#f#, 16#ff#, 16#1e#, 16#0#, 16#38#, 16#0#,
      16#70#, 16#0#, 16#60#, 16#0#, 16#c0#, 16#0#, 16#c0#, 16#0#,
      16#c0#, 16#0#, 16#c0#, 16#0#, 16#c0#, 16#0#, 16#c3#, 16#e0#,
      16#cf#, 16#f8#, 16#fc#, 16#3c#, 16#f0#, 16#e#, 16#e0#, 16#6#,
      16#e0#, 16#7#, 16#c0#, 16#3#, 16#c0#, 16#3#, 16#c0#, 16#3#,
      16#c0#, 16#3#, 16#c0#, 16#3#, 16#60#, 16#7#, 16#60#, 16#6#,
      16#70#, 16#e#, 16#38#, 16#1c#, 16#1f#, 16#f8#, 16#7#, 16#e0#];
   Digit_Seven : constant Unsigned_8_Array :=
     [16#ff#, 16#ff#, 16#ff#, 16#ff#, 16#f0#, 16#0#, 16#78#, 16#0#,
      16#6c#, 16#0#, 16#36#, 16#0#, 16#1b#, 16#0#, 16#8#, 16#0#,
      16#c#, 16#0#, 16#6#, 16#0#, 16#3#, 16#0#, 16#3#, 16#0#,
      16#1#, 16#80#, 16#0#, 16#c0#, 16#0#, 16#c0#, 16#0#, 16#60#,
      16#0#, 16#30#, 16#0#, 16#10#, 16#0#, 16#18#, 16#0#, 16#c#,
      16#0#, 16#6#, 16#0#, 16#6#, 16#0#, 16#3#, 16#0#, 16#1#,
      16#80#, 16#1#, 16#80#, 16#0#, 16#c0#, 16#0#, 16#60#, 16#0#,
      16#20#, 16#0#, 16#30#, 16#0#];
   Digit_Eight : constant Unsigned_8_Array :=
     [16#7#, 16#e0#, 16#1f#, 16#f8#, 16#78#, 16#1e#, 16#60#, 16#6#,
      16#e0#, 16#7#, 16#c0#, 16#3#, 16#c0#, 16#3#, 16#c0#, 16#3#,
      16#c0#, 16#7#, 16#60#, 16#6#, 16#78#, 16#e#, 16#1f#, 16#f8#,
      16#1f#, 16#f8#, 16#38#, 16#1c#, 16#60#, 16#e#, 16#60#, 16#6#,
      16#c0#, 16#3#, 16#c0#, 16#3#, 16#c0#, 16#3#, 16#c0#, 16#3#,
      16#c0#, 16#3#, 16#c0#, 16#3#, 16#c0#, 16#3#, 16#60#, 16#6#,
      16#60#, 16#e#, 16#38#, 16#1c#, 16#1f#, 16#f8#, 16#7#, 16#e0#];
   Digit_Nine : constant Unsigned_8_Array :=
     [16#7#, 16#e0#, 16#1f#, 16#f8#, 16#38#, 16#1c#, 16#70#, 16#e#,
      16#60#, 16#6#, 16#e0#, 16#6#, 16#c0#, 16#3#, 16#c0#, 16#3#,
      16#c0#, 16#3#, 16#c0#, 16#3#, 16#c0#, 16#3#, 16#e0#, 16#7#,
      16#60#, 16#7#, 16#70#, 16#f#, 16#3c#, 16#3b#, 16#1f#, 16#f3#,
      16#7#, 16#e3#, 16#0#, 16#3#, 16#0#, 16#3#, 16#0#, 16#3#,
      16#0#, 16#3#, 16#0#, 16#7#, 16#0#, 16#6#, 16#0#, 16#e#,
      16#0#, 16#1c#, 16#0#, 16#78#, 16#ff#, 16#f0#, 16#ff#, 16#c0#];

   Degree_Celsius : constant Unsigned_8_Array :=
     [16#3e#, 16#0#, 16#0#, 16#63#, 16#0#, 16#0#, 16#c1#, 16#80#,
      16#0#, 16#c1#, 16#80#, 16#0#, 16#c1#, 16#80#, 16#0#, 16#e3#,
      16#80#, 16#0#, 16#7f#, 16#0#, 16#0#, 16#3e#, 16#0#, 16#0#,
      16#0#, 16#0#, 16#0#, 16#0#, 16#1f#, 16#e3#, 16#0#, 16#7f#,
      16#fa#, 16#0#, 16#e0#, 16#1e#, 16#1#, 16#80#, 16#6#, 16#3#,
      16#0#, 16#3#, 16#7#, 16#0#, 16#3#, 16#6#, 16#0#, 16#0#,
      16#c#, 16#0#, 16#0#, 16#c#, 16#0#, 16#0#, 16#c#, 16#0#,
      16#0#, 16#8#, 16#0#, 16#0#, 16#18#, 16#0#, 16#0#, 16#18#,
      16#0#, 16#0#, 16#18#, 16#0#, 16#0#, 16#18#, 16#0#, 16#0#,
      16#18#, 16#0#, 16#0#, 16#8#, 16#0#, 16#0#, 16#c#, 16#0#,
      16#0#, 16#c#, 16#0#, 16#0#, 16#e#, 16#0#, 16#0#, 16#6#,
      16#0#, 16#0#, 16#3#, 16#0#, 16#0#, 16#3#, 16#80#, 16#6#,
      16#1#, 16#c0#, 16#e#, 16#0#, 16#f0#, 16#3c#, 16#0#, 16#7f#,
      16#f0#, 16#0#, 16#f#, 16#c0#];

   --  Digit_Zero : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 1, 1, 0, 0, 0,
   --       0, 1, 1, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_One  : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 1, 1, 1, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_Two  : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 0, 0, 1, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 1, 0, 0, 0, 0, 0,
   --       0, 1, 0, 0, 0, 0, 0, 0,
   --       0, 1, 1, 1, 1, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_Three : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 0, 0, 1, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 0, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_Four : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 1, 0, 0, 0, 0,
   --       0, 1, 1, 1, 1, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 1, 1, 1, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_Five : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 1, 1, 1, 1, 0, 0, 0,
   --       0, 1, 0, 0, 0, 0, 0, 0,
   --       0, 0, 1, 0, 0, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_Six : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 0, 0, 0, 0,
   --       0, 1, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_Seven : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 1, 1, 1, 1, 0, 0, 0,
   --       0, 0, 0, 0, 1, 0, 0, 0,
   --       0, 0, 0, 0, 1, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 1, 0, 0, 0, 0, 0,
   --       0, 1, 0, 0, 0, 0, 0, 0,
   --       0, 1, 0, 0, 0, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_Eight : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];
   --  Digit_Nine : constant Unsigned_1_Array (0 .. 63) :=
   --      [0, 0, 1, 1, 0, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 1, 0, 0, 1, 0, 0, 0,
   --       0, 0, 1, 1, 1, 0, 0, 0,
   --       0, 0, 0, 0, 1, 0, 0, 0,
   --       0, 0, 0, 1, 0, 0, 0, 0,
   --       0, 0, 1, 0, 0, 0, 0, 0,
   --       0, 0, 0, 0, 0, 0, 0, 0];

   procedure Set_Draw_Rectangle
     (X : A0B.Types.Unsigned_16;
      Y : A0B.Types.Unsigned_16;
      W : A0B.Types.Unsigned_16;
      H : A0B.Types.Unsigned_16);

   ------------------------
   -- Set_Draw_Rectangle --
   ------------------------

   procedure Set_Draw_Rectangle
     (X : A0B.Types.Unsigned_16;
      Y : A0B.Types.Unsigned_16;
      W : A0B.Types.Unsigned_16;
      H : A0B.Types.Unsigned_16)
   is
      use type A0B.Types.Unsigned_16;

      XSH : constant A0B.Types.Unsigned_16 := A0B.Types.Shift_Right (X, 8);
      XSL : constant A0B.Types.Unsigned_16 := X and 16#00FF#;
      YSH : constant A0B.Types.Unsigned_16 := A0B.Types.Shift_Right (Y, 8);
      YSL : constant A0B.Types.Unsigned_16 := Y and 16#00FF#;
      XE  : constant A0B.Types.Unsigned_16 := X + W - 1;
      YE  : constant A0B.Types.Unsigned_16 := Y + H - 1;
      XEH : constant A0B.Types.Unsigned_16 := A0B.Types.Shift_Right (XE, 8);
      XEL : constant A0B.Types.Unsigned_16 := XE and 16#00FF#;
      YEH : constant A0B.Types.Unsigned_16 := A0B.Types.Shift_Right (YE, 8);
      YEL : constant A0B.Types.Unsigned_16 := YE and 16#00FF#;

   begin
      Command_Write (CASET0, XSH);
      Command_Write (CASET1, XSL);
      Command_Write (CASET2, XEH);
      Command_Write (CASET3, XEL);
      --  Set horizontal drawing range

      Command_Write (RASET0, YSH);
      Command_Write (RASET1, YSL);
      Command_Write (RASET2, YEH);
      Command_Write (RASET3, YEL);
      --  Set vertical drawing range
   end Set_Draw_Rectangle;

   -----------
   -- Clear --
   -----------

   procedure Clear is
      use type A0B.Time.Monotonic_Time;

      Start : constant A0B.Time.Monotonic_Time := A0B.Time.Clock;

   begin
      Set_Draw_Rectangle (0, 0, 800, 480);
      --  Command_Write (CASET0, 16#00#);
      --  Command_Write (CASET1, 16#00#);
      --  Command_Write (CASET2, 16#03#);
      --  Command_Write (CASET3, 16#1F#);
      --  --  Set horizontal drawing range 0 .. 799
      --
      --  Command_Write (RASET0, 16#00#);
      --  Command_Write (RASET1, 16#00#);
      --  Command_Write (RASET2, 16#01#);
      --  Command_Write (RASET3, 16#8F#);
      --  --  Set vertical drawing range 0 .. 399

      Command (RAMWR);

      for J in 1 .. 800 * 480 loop
         Write (16#0000#);
      end loop;

      Clear_Duration := A0B.Time.To_Duration (A0B.Time.Clock - Start);
   end Clear;

   -------------
   -- Command --
   -------------

   procedure Command (Command : NT35510_Command) is
   begin
      Command_Register := Command;
   end Command;

   -------------------
   -- Command_Write --
   -------------------

   procedure Command_Write
     (Command : NT35510_Command;
      Data    : A0B.Types.Unsigned_16) is
   begin
      Command_Register := Command;
      Data_Register    := Data;
   end Command_Write;

   --------------------
   -- Configure_GPIO --
   --------------------

   procedure Configure_GPIO is

      subtype Low_Line is Integer range 0 .. 7;
      subtype High_Line is Integer range 8 .. 15;

      -----------------
      -- Configure_H --
      -----------------

      procedure Configure_H
        (Peripheral  : in out GPIO_Peripheral;
         Line        : High_Line;
         Alternative : AFRH_AFSEL_Element) is
      begin
         Peripheral.OSPEEDR.Arr (Line) := 2#11#;      --  Very high speed
         Peripheral.OTYPER.OT.Arr (Line) := False;    --  Output push-pull
         Peripheral.PUPDR.Arr (Line) := 2#00#;
         --  No pullup, no pulldown
         Peripheral.AFRH.Arr (Line) := Alternative;   --  Alternate function
         Peripheral.MODER.Arr (Line) := 2#10#;        --  Alternate function
      end Configure_H;

      -----------------
      -- Configure_L --
      -----------------

      procedure Configure_L
        (Peripheral  : in out GPIO_Peripheral;
         Line        : Low_Line;
         Alternative : AFRH_AFSEL_Element) is
      begin
         Peripheral.OSPEEDR.Arr (Line) := 2#11#;      --  Very high speed
         Peripheral.OTYPER.OT.Arr (Line) := False;    --  Output push-pull
         Peripheral.PUPDR.Arr (Line) := 2#00#;
         --  No pullup, no pulldown
         Peripheral.AFRL.Arr (Line) := Alternative;   --  Alternate function
         Peripheral.MODER.Arr (Line) := 2#10#;        --  Alternate function
      end Configure_L;

   begin
      --  Enable clocks

      RCC_Periph.AHB4ENR.GPIOAEN := True;
      RCC_Periph.AHB4ENR.GPIOCEN := True;
      RCC_Periph.AHB4ENR.GPIODEN := True;
      RCC_Periph.AHB4ENR.GPIOEEN := True;
      RCC_Periph.AHB4ENR.GPIOFEN := True;

      --  PA4  -> FMC_D8
      Configure_L (GPIOA_Periph, 4, 12);
      --  PA5  -> FMC_D9
      Configure_L (GPIOA_Periph, 5, 12);
      --  PC0  -> FMC_D12
      Configure_L (GPIOC_Periph, 0, 1);
      --  PC7  -> FMC_NE1
      Configure_L (GPIOC_Periph, 7, 9);
      --  PD0  -> FMC_D2
      Configure_L (GPIOD_Periph, 0, 12);
      --  PD1  -> FMC_D3
      Configure_L (GPIOD_Periph, 1, 12);
      --  PD4  -> FMC_NOE
      Configure_L (GPIOD_Periph, 4, 12);
      --  PD5  -> FMC_NWE
      Configure_L (GPIOD_Periph, 5, 12);
      --  PD8  -> FMC_D13
      Configure_H (GPIOD_Periph, 8, 12);
      --  PD9  -> FMC_D14
      Configure_H (GPIOD_Periph, 9, 12);
      --  PD10 -> FMC_D15
      Configure_H (GPIOD_Periph, 10, 12);
      --  PD14 -> FMC_D0
      Configure_H (GPIOD_Periph, 14, 12);
      --  PD15 -> FMC_D1
      Configure_H (GPIOD_Periph, 15, 12);
      --  PE7  -> FMC_D4
      Configure_L (GPIOE_Periph, 7, 12);
      --  PE8  -> FMC_D5
      Configure_H (GPIOE_Periph, 8, 12);
      --  PE9  -> FMC_D6
      Configure_H (GPIOE_Periph, 9, 12);
      --  PE10 -> FMC_D7
      Configure_H (GPIOE_Periph, 10, 12);
      --  PE13 -> FMC_D10
      Configure_H (GPIOE_Periph, 13, 12);
      --  PE14 -> FMC_D11
      Configure_H (GPIOE_Periph, 14, 12);
      --  PF4  -> FMC_A4
      Configure_L (GPIOF_Periph, 4, 12);
   end Configure_GPIO;

   -------------------
   -- Configure_FMC --
   -------------------

   procedure Configure_FMC is
   begin
      RCC_Periph.D1CCIPR.FMCSEL := 2#10#;  --  PLL2R
      RCC_Periph.AHB3ENR.FMCEN := True;

      declare
         Val : BCR_Register := FMC_Periph.BCR1;

      begin
         Val.MBKEN     := True;   --  Corresponding memory bank is enabled
         Val.MUXEN     := False;  --  Address/Data non-multiplexed
         Val.MTYP      := 2#00#;  --  SRAM
         Val.MWID      := 2#01#;  --  16 bits
         Val.FACCEN    := False;
         --  Corresponding NOR Flash memory access is disabled
         Val.BURSTEN   := False;
         --  Burst mode disabled. Read accesses are performed in Asynchronous
         --  mode.
         Val.WAITPOL   := False;  --  NWAIT active low
         Val.WAITCFG   := False;
         --  NWAIT signal is active one data cycle before wait state
         Val.WREN      := True;
         --  Write operations are enabled for the bank by the FMC
         Val.WAITEN    := False;  --  NWAIT signal is disabled
         Val.EXTMOD    := True;
         --  Values inside FMC_BWTR register are taken into account
         Val.ASYNCWAIT := False;
         --  NWAIT signal is not taken in to account when running an
         --  asynchronous protocol
         Val.CPSIZE    := 2#000#;
         --  No burst split when crossing page boundary.
         Val.CBURSTRW  := False;
         --  Write operations are always performed in Asynchronous mode.
         Val.CCLKEN    := False;
         --  The FMC_CLK is only generated during the synchronous memory
         --  access (read/write transaction).
         Val.WFDIS     := False;  --  Write FIFO enabled
         Val.BMAP      := 2#00#;  --  Default mapping
         Val.FMCEN     := True;   --  Enable the FMC controller

         FMC_Periph.BCR1 := Val;
      end;

      --  Setup timing of the read operation.
      --
      --  Timings of the read operation for registers and memory are
      --  different. Values below corresponds to longer operation -
      --  graphical memory read.
      --
      --  Minimal duration of low level of the RD signal is 150 ns. This
      --  values is set by DATAST field.
      --
      --  Minimal Duration of the high level of the RD signal is 250 ns. It is
      --  combined by values of the ADDSET and BUSTURN fields, plus one clock
      --  cycle between two consequencive asynchronous read operations.

      declare
         Val : BTR_Register := FMC_Periph.BTR1;

      begin
         Val.ACCMOD  := 2#00#;  --  Access mode A
         Val.DATLAT  := 15;
         Val.CLKDIV  := 15;
         Val.BUSTURN := 14;
         Val.DATAST  := 18;
         Val.ADDHLD  := 15;
         Val.ADDSET  := 15;

         FMC_Periph.BTR1 := Val;
      end;

      --  Setup timing of the write operation.
      --
      --
      --  Minimal duration of the low level of the WR signal is 15 ns. It is
      --  set by the DATAST field.
      --
      --  Minimal duration of the high level of the WR signal is 15 ns. It is
      --  set by the ADDSET and BUSTURN fields, plus one clock circle between
      --  raising of the signal level and end of the write operation.

      declare
         Val : BWTR_Register := FMC_Periph.BWTR1;

      begin
         Val.ACCMOD  := 2#00#;  --  Access mode A
         Val.BUSTURN := 0;
         Val.DATAST  := 2;
         Val.ADDHLD  := 15;
         Val.ADDSET  := 1;

         FMC_Periph.BWTR1 := Val;
      end;
   end Configure_FMC;

   -------------------
   -- Configure_MPU --
   -------------------

   procedure Configure_MPU is
   begin
      A0B.ARMv7M.Memory_Protection_Unit.MPU.MPU_RNR :=
        (REGION => 1, others => <>);

      A0B.ARMv7M.Memory_Protection_Unit.MPU.MPU_RBAR :=
        (ADDR => System.Storage_Elements.To_Address (16#6000_0000#));
      A0B.ARMv7M.Memory_Protection_Unit.MPU.MPU_RASR :=
        (ENABLE => True,    --  Region is enabled
         SIZE   => 5,       --  64 bytes
         SRD    => 2#0000_0000#,
         B      => False,   --  Not bufferable
         C      => False,   --  Not cachable
         S      => True,    --  Sharable
         TEX    => 0,
         AP     => 2#011#,  --  Full access
         XN     => True,
         --  Execution of an instruction fetched from this region not
         --  permitted
         others => <>);
   end Configure_MPU;

   --------------------
   -- Configure_PLL2 --
   --------------------

   procedure Configure_PLL2 is
      --  This configuration should be synchronized somehow with startup code.
      --  It assumes use of HSE @25MHz to drive PLLs.

   begin
      --  Disable the main PLL.

      RCC_Periph.CR.PLL2ON := False;

      --  Wait till PLL is disabled.

      while RCC_Periph.CR.PLL2RDY loop
         null;
      end loop;

      --  Configure PLL2.

      declare
         Aux : PLLCKSELR_Register := RCC_Periph.PLLCKSELR;

      begin
         Aux.DIVM2 := DIVM2;

         RCC_Periph.PLLCKSELR := Aux;
      end;

      declare
         Aux : PLL2DIVR_Register := RCC_Periph.PLL2DIVR;

      begin
         Aux.DIVN1  := MULN2;
         Aux.DIVP1  := 0;
         Aux.DIVQ1  := 0;
         Aux.DIVR1  := DIVR2;

         RCC_Periph.PLL2DIVR := Aux;
      end;

      declare
         Aux : PLLCFGR_Register := RCC_Periph.PLLCFGR;

      begin
         Aux.PLL2FRACEN := False;
         Aux.PLL2VCOSEL := True;
         Aux.PLL2RGE    := PLL2GRE;
         Aux.DIVR2EN    := True;

         RCC_Periph.PLLCFGR := Aux;
      end;

      RCC_Periph.PLL2FRACR.FRACN2 := 0;

      --  Enable the PLL.

      RCC_Periph.CR.PLL2ON := True;

      --  Wait till PLL is enabled.

      while not RCC_Periph.CR.PLL2RDY loop
         null;
      end loop;
   end Configure_PLL2;

   ---------------
   -- Delay_For --
   ---------------

   procedure Delay_For (Interval : A0B.Time.Time_Span) is
   begin
      Delay_Done := False;

      A0B.Timer.Enqueue
        (Delay_Timeout, On_Delay_Callbacks.Create_Callback, Interval);

      while not Delay_Done loop
         A0B.ARMv7M.CMSIS.Wait_For_Interrupt;
      end loop;
   end Delay_For;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Configure_PLL2;
      Configure_FMC;
      Configure_GPIO;
      Configure_MPU;

      --  Reset_Low;
      --  Delay_For (Microseconds (10));
      --  Reset_High;

      Delay_For (A0B.Time.Milliseconds (120));

      Command (SLPOUT);
      Delay_For (A0B.Time.Milliseconds (120));

      Command_Write (MADCTL, 2#0110_0000#);
      --  Column Address Order: reverted
      --  Row/Column Exchange: exchanged

      Command_Write (COLMOD, 2#0101_0101#);
      --  Pixel Format for RGB Interface: 16-bit/pixel
      --  Pixel Format for MCU Interface: 16-bit/pixel

      Clear;
      --  Cleaup display memory

      Command (DISPON);
   end Initialize;

   --------------
   -- On_Delay --
   --------------

   procedure On_Delay is
   begin
      Delay_Done := True;
   end On_Delay;

   ------------
   -- Redraw --
   ------------

   procedure Redraw
     (CO2_Concentration : A0B.Types.Unsigned_16;
      Temperature       : A0B.Types.Unsigned_16;
      Humidity          : A0B.Types.Unsigned_16)
   is
      use type A0B.Types.Integer_32;
      use type A0B.Types.Unsigned_16;

      ----------
      -- Draw --
      ----------

      procedure Draw
        (X     : A0B.Types.Unsigned_16;
         Y     : A0B.Types.Unsigned_16;
         Color : A0B.Types.Unsigned_16;
         Text  : String)
      is

         --  Line_Height : constant := 37;
         --  Baseline    : constant := 1;

         -----------------
         -- Write_Glyph --
         -----------------

         --  procedure Write_Glyph
         --    (X     : in out A0B.Types.Unsigned_16;
         --     Y     : A0B.Types.Unsigned_16;
         --     Glyph : Unsigned_1_Array)
         --  is
         --     use type A0B.Types.Unsigned_1;
         --
         --  begin
         --     Set_Draw_Rectangle (X, Y, 8, 8);
         --
         --     Command (RAMWR);
         --
         --     for Bit of Glyph loop
         --        Write (if Bit = 1 then 16#FFFF# else 16#0000#);
         --     end loop;
         --
         --     X := @ + 8;
         --  end Write_Glyph;

         procedure Write_Glyph
           (X    : in out A0B.Types.Unsigned_16;
            Y    : A0B.Types.Unsigned_16;
            Bits : Unsigned_8_Array;
            W    : A0B.Types.Unsigned_16;
            H    : A0B.Types.Unsigned_16;
            DX   : A0B.Types.Unsigned_16;
            DY   : A0B.Types.Unsigned_16)
         is
            use type A0B.Types.Unsigned_8;
            use type A0B.Types.Unsigned_32;

            Remain : A0B.Types.Unsigned_32 :=
              A0B.Types.Unsigned_32 (W) * A0B.Types.Unsigned_32 (H);
            Aux    : A0B.Types.Unsigned_8;

         begin
            Set_Draw_Rectangle
              (X + DX,
               Y - H + DY,
               --  Y - Line_Height + H + DY,
               W,
               H);

            Command (RAMWR);

            for Byte of Bits loop
               Aux := Byte;

               for J in 0 .. 7 loop
                  exit when Remain = 0;
                  Remain := @ - 1;

                  Write
                    (if (Aux and 2#1000_0000#) /= 0
                       then Color
                       else 16#0000#);

                  Aux := A0B.Types.Shift_Left (@, 1);
               end loop;
            --  for Bit of Glyph loop
            --     Write (if Bit = 1 then 16#FFFF# else 16#0000#);
            end loop;

            X := @ + DX + W + 2;
            --  X := @ + 28;
         end Write_Glyph;

         XC : A0B.Types.Unsigned_16          := X;
         YC : constant A0B.Types.Unsigned_16 := Y;

      begin
         for Character of Text loop
            case Character is
            when ' ' => null;
            when '%' => Write_Glyph (XC, YC, Percent_Sign, 22, 28, 3, 0);
            when '0' => Write_Glyph (XC, YC, Digit_Zero, 16, 28, 6, 0);
            when '1' => Write_Glyph (XC, YC, Digit_One, 17, 28, 6, 0);
            when '2' => Write_Glyph (XC, YC, Digit_Two, 17, 28, 6, 0);
            when '3' => Write_Glyph (XC, YC, Digit_Three, 18, 28, 5, 0);
            when '4' => Write_Glyph (XC, YC, Digit_Four, 20, 28, 4, 0);
            when '5' => Write_Glyph (XC, YC, Digit_Five, 20, 28, 4, 0);
            when '6' => Write_Glyph (XC, YC, Digit_Six, 16, 28, 6, 0);
            when '7' => Write_Glyph (XC, YC, Digit_Seven, 17, 28, 6, 0);
            when '8' => Write_Glyph (XC, YC, Digit_Eight, 16, 28, 6, 0);
            when '9' => Write_Glyph (XC, YC, Digit_Nine, 16, 28, 4, 0);
            when 'C' => Write_Glyph (XC, YC, Degree_Celsius, 24, 36, 1, 0);
            when others => null;
            end case;
         end loop;
      end Draw;

      ---------
      -- Map --
      ---------

      function Map
        (L : A0B.Types.Integer_32;
         H : A0B.Types.Integer_32;
         V : A0B.Types.Unsigned_16) return A0B.Types.Unsigned_16
      is
         --  L32 : constant A0B.Types.Integer_32 := A0B.Types.Integer_32 (L);
         --  H32 : constant A0B.Types.Integer_32 := A0B.Types.Integer_32 (H);
         V32 : constant A0B.Types.Integer_32 := A0B.Types.Integer_32 (V);

      begin
         return
           A0B.Types.Unsigned_16
             (479 - ((479 - 0) * (V32 - L) / (H - L)));
      end Map;

      --  Text : constant String := "0123456789";

      --  X    : constant A0B.Types.Unsigned_16 := 0;
      --  Y    : constant A0B.Types.Unsigned_16 := 0;

      C : constant String := A0B.Types.Unsigned_16'Image (CO2_Concentration);
      T : constant String := A0B.Types.Unsigned_16'Image (Temperature);
      H : constant String := A0B.Types.Unsigned_16'Image (Humidity);

      CG : constant A0B.Types.Unsigned_16 := Map (0, 2_000, CO2_Concentration);
      TG : constant A0B.Types.Unsigned_16 := Map (-20, 80, Temperature);
      HG : constant A0B.Types.Unsigned_16 := Map (0, 100, Humidity);

   begin
      Points (0 .. 798) := Points (1 .. 799);
      Points (799) := (CG, TG, HG);

      Clear;

      for J in Points'Range loop
         Set_Draw_Rectangle (J, Points (J).C, 1, 1);
         Command_Write (RAMWR, C_RGB);

         Set_Draw_Rectangle (J, Points (J).H, 1, 1);
         Command_Write (RAMWR, H_RGB);

         Set_Draw_Rectangle (J, Points (J).T, 1, 1);
         Command_Write (RAMWR, T_RGB);
      end loop;

      --  Draw (X, Y, Text);
      Draw (100, 100, C_RGB, C);
      Draw (100, 200, T_RGB, T & "C");
      Draw (100, 300, H_RGB, H & "%");
   end Redraw;

   -----------
   -- Write --
   -----------

   procedure Write (Data : A0B.Types.Unsigned_16) is
   begin
      Data_Register := Data;
   end Write;

end SCD40_Sandbox.Display;
