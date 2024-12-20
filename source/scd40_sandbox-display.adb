--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Interfaces;
with System.Storage_Elements;

with A0B.ARMv7M.SCS.MPU;
with A0B.Delays;
with A0B.STM32H723.SVD.FMC;  use A0B.STM32H723.SVD.FMC;
with A0B.STM32H723.SVD.GPIO; use A0B.STM32H723.SVD.GPIO;
with A0B.STM32H723.SVD.RCC;  use A0B.STM32H723.SVD.RCC;
with A0B.Time.Clock;
with A0B.Types;

with SCD40_Sandbox.Fonts.DejaVuSansCondensed_32;
with SCD40_Sandbox.Globals;
with SCD40_Sandbox.Painter;
with SCD40_Sandbox.Touch;
with SCD40_Sandbox.Widgets;

--  with LADO.Acquisition;

package body SCD40_Sandbox.Display is

   procedure Configure_FMC;

   procedure Configure_MPU;

   procedure Configure_GPIO;

   type NT35510_Command is new A0B.Types.Unsigned_16;

   SLPOUT : constant := 16#1100#;
   DISPON : constant := 16#2900#;
   MADCTL : constant := 16#3600#;
   COLMOD : constant := 16#3A00#;

   procedure Command (Command : NT35510_Command);

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

   procedure Clear;
   --  Clear content of the screen.

   --  C_RGB : constant := 16#FFC0#;
   --  T_RGB : constant := 16#07E0#;
   --  H_RGB : constant := 16#F800#;
   --  P_RGB : constant := 16#001F#;
   --  L_RGB : constant := 16#D69A#;
   --  S_RGB : constant := 16#4228#;
   S_RGB : constant := 16#9CD3#;
   H_RGB : constant := S_RGB;
   T_RGB : constant := S_RGB;
   P_RGB : constant := S_RGB;
   L_RGB : constant := S_RGB;

   Background_Color : constant := 16#18E3#;

   TW : SCD40_Sandbox.Widgets.Widget;
   HW : SCD40_Sandbox.Widgets.Widget;
   CW : SCD40_Sandbox.Widgets.Widget;
   PW : SCD40_Sandbox.Widgets.Widget;

   Degree_Celsius : aliased constant Wide_String := "℃";
   Percent        : aliased constant Wide_String := "%";
   PPM            : aliased constant Wide_String := "PPM";
   Pa             : aliased constant Wide_String := "Pa";
   lx             : aliased constant Wide_String := "lx";
   mmHg           : aliased constant Wide_String := "mmHg";

   Clear_Duration : A0B.Time.Duration with Volatile;

   -----------
   -- Clear --
   -----------

   procedure Clear is
      use type A0B.Time.Monotonic_Time;

      Start : constant A0B.Time.Monotonic_Time := A0B.Time.Clock;

   begin
      Painter.Set_Color (Background_Color);
      Painter.Fill_Rect (0, 0, 800, 480);

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

      --  PD0  -> FMC_D2
      Configure_L (GPIOD_Periph, 0, 12);
      --  PD1  -> FMC_D3
      Configure_L (GPIOD_Periph, 1, 12);
      --  PD4  -> FMC_NOE
      Configure_L (GPIOD_Periph, 4, 12);
      --  PD5  -> FMC_NWE
      Configure_L (GPIOD_Periph, 5, 12);
      --  PD7  -> FMC_NE1
      Configure_L (GPIOD_Periph, 7, 12);
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
      --  PE11 -> FMC_D8
      Configure_H (GPIOE_Periph, 11, 12);
      --  PE12 -> FMC_D9
      Configure_H (GPIOE_Periph, 12, 12);
      --  PE13 -> FMC_D10
      Configure_H (GPIOE_Periph, 13, 12);
      --  PE14 -> FMC_D11
      Configure_H (GPIOE_Periph, 14, 12);
      --  PE15 -> FMC_D12
      Configure_H (GPIOE_Periph, 15, 12);
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
      A0B.ARMv7M.SCS.MPU.MPU_RNR := (REGION => 1, others => <>);

      A0B.ARMv7M.SCS.MPU.MPU_RBAR :=
        (ADDR => System.Storage_Elements.To_Address (16#6000_0000#));
      A0B.ARMv7M.SCS.MPU.MPU_RASR :=
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

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use type A0B.Types.Integer_32;

   begin
      Configure_FMC;
      Configure_GPIO;
      Configure_MPU;

      --  Reset_Low;
      --  Delay_For (Microseconds (10));
      --  Reset_High;

      A0B.Delays.Delay_For (A0B.Time.Milliseconds (120));

      Command (SLPOUT);
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (120));

      Command_Write (MADCTL, 2#0110_0000#);
      --  Column Address Order: reverted
      --  Row/Column Exchange: exchanged

      Command_Write (COLMOD, 2#0101_0101#);
      --  Pixel Format for RGB Interface: 16-bit/pixel
      --  Pixel Format for MCU Interface: 16-bit/pixel

      Clear;
      --  Cleaup display memory

      Command (DISPON);

      --  Initialize widgets.

      TW.Initialize (10, 50, 380, 180, -20, 60, Degree_Celsius'Access);
      HW.Initialize (410, 50, 380, 180, 0, 100, Percent'Access);
      PW.Initialize (10, 250, 380, 180, 60_000, 120_000, Pa'Access);
      CW.Initialize (410, 250, 380, 180, 300, 2_100, PPM'Access);
   end Initialize;

   ------------
   -- Redraw --
   ------------

   procedure Redraw is
      use type Interfaces.IEEE_Float_64;

      BPM : constant Wide_String :=
        A0B.Types.Unsigned_32'Wide_Image
          (A0B.Types.Unsigned_32 (Globals.Pressure * 0.00750062));
      BT : constant Wide_String :=
        A0B.Types.Unsigned_32'Wide_Image
          (A0B.Types.Unsigned_32 (Globals.Temperature));
      BH : constant Wide_String :=
        A0B.Types.Unsigned_32'Wide_Image
          (A0B.Types.Unsigned_32 (Globals.Humidity));
      L  : constant Wide_String :=
        A0B.Types.Unsigned_16'Wide_Image (Globals.Light);

   begin
      TW.Draw (A0B.Types.Integer_32 (Globals.T));
      HW.Draw (A0B.Types.Integer_32 (Globals.RH));
      PW.Draw (A0B.Types.Integer_32 (Globals.Pressure));
      CW.Draw (A0B.Types.Integer_32 (Globals.CO2));

      Painter.Set_Color (Background_Color);
      Painter.Fill_Rect (0, 440, 800, 40);

      Painter.Set_Font
        (SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font'Access);
      Painter.Set_Color (L_RGB);
      Painter.Draw_Text (20, 470, L & " " & lx);
      Painter.Set_Color (T_RGB);
      Painter.Draw_Text (250, 470, BT & " " & Degree_Celsius);
      Painter.Set_Color (H_RGB);
      Painter.Draw_Text (450, 470, BH & " " & Percent);
      Painter.Set_Color (P_RGB);
      Painter.Draw_Text (600, 470, BPM & " " & mmHg);
   end Redraw;

   ------------------
   -- Redraw_Touch --
   ------------------

   procedure Redraw_Touch is
      --  use type A0B.Types.Unsigned_16;
      --  use type A0B.Types.Unsigned_32;
      --  use type A0B.Types.Integer_32;

   begin
      Painter.Set_Color (Background_Color);
      Painter.Fill_Rect (0, 0, 800, 50);

      Painter.Set_Font
        (SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font'Access);
      Painter.Set_Color (P_RGB);

      declare
         use type A0B.Types.Unsigned_12;
         use type A0B.Types.Integer_32;

         X  : constant Wide_String :=
           A0B.Types.Unsigned_12'Wide_Image (SCD40_Sandbox.Touch.VAL.X);
         Y  : constant Wide_String :=
           A0B.Types.Unsigned_12'Wide_Image (SCD40_Sandbox.Touch.VAL.Y);
         Z1 : constant Wide_String :=
           A0B.Types.Unsigned_12'Wide_Image (SCD40_Sandbox.Touch.VAL.Z1);
         Z2 : constant Wide_String :=
           A0B.Types.Unsigned_12'Wide_Image (SCD40_Sandbox.Touch.VAL.Z2);
         --  PV : constant A0B.Types.Unsigned_12 :=
         --    SCD40_Sandbox.Touch.VAL.Z2
         --      / A0B.Types.Unsigned_12'Max (SCD40_Sandbox.Touch.VAL.Z1, 1);
         --  P  : constant Wide_String :=
         --    A0B.Types.Unsigned_12'Wide_Image (PV);
         DZ : constant Wide_String :=
           A0B.Types.Unsigned_12'Wide_Image
             (SCD40_Sandbox.Touch.VAL.Z2 - SCD40_Sandbox.Touch.VAL.Z1);

      begin
         Painter.Draw_Text (50, 43, X);
         Painter.Draw_Text (150, 43, Y);
         Painter.Draw_Text (550, 43, Z1);
         Painter.Draw_Text (650, 43, Z2);

         if SCD40_Sandbox.Touch.Is_Touched then
            declare
               PZ2 : constant A0B.Types.Integer_32 :=
                 ((A0B.Types.Integer_32 (SCD40_Sandbox.Touch.VAL.Z2) + 1) * 1);
               --  (A0B.Types.Integer_32 (SCD40_Sandbox.Touch.VAL.Z2) * 256);
               PZ1 : constant A0B.Types.Integer_32 :=
                 A0B.Types.Integer_32 (SCD40_Sandbox.Touch.VAL.Z1) + 1;
               --  A0B.Types.Integer_32'Max
               --    (1, A0B.Types.Integer_32 (SCD40_Sandbox.Touch.VAL.Z1));
               DZ1 : constant A0B.Types.Integer_32 := PZ2 / PZ1 - 1 * 1;
               PV  : constant A0B.Types.Integer_32 :=
                 DZ1 * A0B.Types.Integer_32 (SCD40_Sandbox.Touch.VAL.X) / 1;
               P  : constant Wide_String :=
                 A0B.Types.Integer_32'Wide_Image (PV);

            begin
               Painter.Draw_Text (250, 43, P);
               Painter.Draw_Text (450, 43, DZ);
            end;
         end if;
      end;

      --  Painter.Set_Color (16#FFC0#);
      --
      --  for J in A0B.Types.Unsigned_32 (0) .. 799 loop
      --     Painter.Fill_Rect
      --       (A0B.Types.Integer_32 (J),
      --        150
      --          + (if (LADO.Acquisition.Buffer (J) and 2#0001#) /= 0
      --               then 0 else 20),
      --        1,
      --        1);
      --     Painter.Fill_Rect
      --       (A0B.Types.Integer_32 (J),
      --        200
      --          + (if (LADO.Acquisition.Buffer (J) and 2#0010#) /= 0
      --               then 0 else 20),
      --        1,
      --        1);
      --     --  if (LAO.Acquisition.Buffer (J) and 2#0001#) /= 0 then
      --  end loop;
   end Redraw_Touch;

end SCD40_Sandbox.Display;
