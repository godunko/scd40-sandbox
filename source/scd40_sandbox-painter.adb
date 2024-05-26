--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with System.Storage_Elements;

package body SCD40_Sandbox.Painter is

   Active_Color : A0B.Types.Unsigned_16 := 0;
   Active_Font  : SCD40_Sandbox.Fonts.Font_Descriptor_Access;

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
      Text : Wide_String)
   is
      use type A0B.Types.Unsigned_16;
      use type A0B.Types.Unsigned_32;

      procedure Write_Glyph
        (X    : in out A0B.Types.Unsigned_16;
         Y    : A0B.Types.Unsigned_16;
         Bits : SCD40_Sandbox.Fonts.Unsigned_8_Array;
         W    : A0B.Types.Unsigned_16;
         H    : A0B.Types.Unsigned_16;
         DX   : A0B.Types.Integer_16;
         DY   : A0B.Types.Integer_16;
         GW   : A0B.Types.Unsigned_16 := 28)
      is
         use type A0B.Types.Unsigned_8;
         use type A0B.Types.Integer_32;

         Aux : A0B.Types.Unsigned_8;

         XS  : constant A0B.Types.Unsigned_16 :=
           A0B.Types.Unsigned_16
             (A0B.Types.Integer_32 (X) + A0B.Types.Integer_32 (DX));
         YS  : constant A0B.Types.Unsigned_16 :=
           A0B.Types.Unsigned_16
             (A0B.Types.Integer_32 (Y)
                - A0B.Types.Integer_32 (DY)
                - A0B.Types.Integer_32 (H));
         XE  : constant A0B.Types.Unsigned_16 := XS + W - 1;
         YE  : constant A0B.Types.Unsigned_16 := YS + H - 1;
         XC  : A0B.Types.Unsigned_16 := XS;
         YC  : A0B.Types.Unsigned_16 := YS;

      begin
         Outer :
         for Byte of Bits loop
            Aux := Byte;

            for J in 0 .. 7 loop
               if (Aux and 2#1000_0000#) /= 0 then
                  Display.Set_Write_Rectangle (XC, YC, 1, 1);
                  Display.Command (Display.RAMWR);
                  Display.Write (Active_Color);
               end if;

               Aux := A0B.Types.Shift_Left (@, 1);

               XC := @ + 1;

               if XC > XE then
                  XC := XS;
                  YC := @ + 1;

                  exit Outer when YC > YE;
               end if;
            end loop;
         end loop Outer;

         X := @ + GW;
      end Write_Glyph;

      use type SCD40_Sandbox.Fonts.Glyph_Descriptor_Access;

      XC : A0B.Types.Unsigned_16          := A0B.Types.Unsigned_16 (X);
      YC : constant A0B.Types.Unsigned_16 := A0B.Types.Unsigned_16 (Y);

      Glyph : SCD40_Sandbox.Fonts.Glyph_Descriptor_Access;
      Code  : A0B.Types.Unsigned_32;

   begin
      for Character of Text loop
         Code := Standard.Wide_Character'Pos (Character);

         for J of Active_Font.Map.all loop
            if Code in
              J.First .. J.First + A0B.Types.Unsigned_32 (J.Length) - 1
            then
               Glyph :=
                 Active_Font.Glyph
                   (J.First_Glyph_Index
                      + A0B.Types.Unsigned_16 (Code - J.First) - 1)'Access;
            end if;
         end loop;

         Write_Glyph
           (XC,
            YC,
            Active_Font.Bitmap
              (Glyph.Bitmap_Index .. Active_Font.Bitmap'Last),
            A0B.Types.Unsigned_16 (Glyph.Box_Width),
            A0B.Types.Unsigned_16 (Glyph.Box_Height),
            A0B.Types.Integer_16 (Glyph.Offset_X),
            A0B.Types.Integer_16 (Glyph.Offset_Y),
            Glyph.Glyph_Width / 16);
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

   --------------
   -- Set_Font --
   --------------

   procedure Set_Font (Font : SCD40_Sandbox.Fonts.Font_Descriptor_Access) is
   begin
      Active_Font := Font;
   end Set_Font;

end SCD40_Sandbox.Painter;
