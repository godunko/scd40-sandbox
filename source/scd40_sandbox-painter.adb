--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with System.Storage_Elements;

package body SCD40_Sandbox.Painter is

   Active_Color : A0B.Types.Unsigned_16 := 0;

   package Display is

      type NT35510_Command is new A0B.Types.Unsigned_16;

      --  SLPOUT : constant := 16#1100#;
      --  DISPON : constant := 16#2900#;
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
      --  MADCTL : constant := 16#3600#;
      --  COLMOD : constant := 16#3A00#;

      procedure Command (Command : NT35510_Command);

      procedure Write (Data : A0B.Types.Unsigned_16);

      procedure Set_Write_Rectangle
        (X : A0B.Types.Unsigned_16;
         Y : A0B.Types.Unsigned_16;
         W : A0B.Types.Unsigned_16;
         H : A0B.Types.Unsigned_16);

   end Display;

   package Font is

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

   end Font;

   -------------
   -- Display --
   -------------

   package body Display is

      Command_Register : NT35510_Command
        with Import,
             Convention => C,
             Address    => System.Storage_Elements.To_Address (16#6000_0000#);
      Data_Register    : A0B.Types.Unsigned_16
        with Import,
             Convention => C,
             Address    => System.Storage_Elements.To_Address (16#6000_0020#);

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

      -------------------------
      -- Set_Write_Rectangle --
      -------------------------

      procedure Set_Write_Rectangle
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
      end Set_Write_Rectangle;

      -----------
      -- Write --
      -----------

      procedure Write (Data : A0B.Types.Unsigned_16) is
      begin
         Data_Register := Data;
      end Write;

   end Display;

   ---------------
   -- Draw_Rect --
   ---------------

   procedure Draw_Rect
     (X : A0B.Types.Integer_32;
      Y : A0B.Types.Integer_32;
      W : A0B.Types.Integer_32;
      H : A0B.Types.Integer_32)
   is
   begin
      null;
   end Draw_Rect;

   ---------------
   -- Draw_Text --
   ---------------

   procedure Draw_Text
     (X    : A0B.Types.Integer_32;
      Y    : A0B.Types.Integer_32;
      Text : String)
   is
      use type A0B.Types.Unsigned_16;

      procedure Write_Glyph
        (X    : in out A0B.Types.Unsigned_16;
         Y    : A0B.Types.Unsigned_16;
         Bits : Font.Unsigned_8_Array;
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
         Display.Set_Write_Rectangle
           (X + DX,
            Y - H + DY,
            --  Y - Line_Height + H + DY,
            W,
            H);

         Display.Command (Display.RAMWR);

         for Byte of Bits loop
            Aux := Byte;

            for J in 0 .. 7 loop
               exit when Remain = 0;
               Remain := @ - 1;

               Display.Write
                 (if (Aux and 2#1000_0000#) /= 0
                  then Active_Color
                  else 16#2965#);

               Aux := A0B.Types.Shift_Left (@, 1);
            end loop;
            --  for Bit of Glyph loop
            --     Write (if Bit = 1 then 16#FFFF# else 16#0000#);
         end loop;

         --  X := @ + DX + W + 2;
         X := @ + 28;
      end Write_Glyph;

      XC : A0B.Types.Unsigned_16          := A0B.Types.Unsigned_16 (X);
      YC : constant A0B.Types.Unsigned_16 := A0B.Types.Unsigned_16 (Y);

   begin
      for Character of Text loop
         case Character is
            when ' ' => XC := @ + 28;
            when '%' => Write_Glyph (XC, YC, Font.Percent_Sign, 22, 28, 3, 0);
            when '0' => Write_Glyph (XC, YC, Font.Digit_Zero, 16, 28, 6, 0);
            when '1' => Write_Glyph (XC, YC, Font.Digit_One, 17, 28, 6, 0);
            when '2' => Write_Glyph (XC, YC, Font.Digit_Two, 17, 28, 6, 0);
            when '3' => Write_Glyph (XC, YC, Font.Digit_Three, 18, 28, 5, 0);
            when '4' => Write_Glyph (XC, YC, Font.Digit_Four, 20, 28, 4, 0);
            when '5' => Write_Glyph (XC, YC, Font.Digit_Five, 20, 28, 4, 0);
            when '6' => Write_Glyph (XC, YC, Font.Digit_Six, 16, 28, 6, 0);
            when '7' => Write_Glyph (XC, YC, Font.Digit_Seven, 17, 28, 6, 0);
            when '8' => Write_Glyph (XC, YC, Font.Digit_Eight, 16, 28, 6, 0);
            when '9' => Write_Glyph (XC, YC, Font.Digit_Nine, 16, 28, 4, 0);
            when 'C' =>
               Write_Glyph (XC, YC, Font.Degree_Celsius, 24, 36, 1, 0);
            when others => null;
         end case;
      end loop;
   end Draw_Text;

   ---------------
   -- Fill_Rect --
   ---------------

   procedure Fill_Rect
     (X : A0B.Types.Integer_32;
      Y : A0B.Types.Integer_32;
      W : A0B.Types.Integer_32;
      H : A0B.Types.Integer_32)
   is
      use type A0B.Types.Integer_32;

   begin
      Display.Set_Write_Rectangle
        (A0B.Types.Unsigned_16 (X),
         A0B.Types.Unsigned_16 (Y),
         A0B.Types.Unsigned_16 (W),
         A0B.Types.Unsigned_16 (H));

      Display.Command (Display.RAMWR);

      for J in 1 .. W * H loop
         Display.Write (Active_Color);
      end loop;
   end Fill_Rect;

   ---------------
   -- Set_Color --
   ---------------

   procedure Set_Color (Color : RGB565_Color) is
   begin
      Active_Color := Color;
   end Set_Color;

end SCD40_Sandbox.Painter;
