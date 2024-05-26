--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with SCD40_Sandbox.Fonts.DejaVuSansCondensed_48;
with SCD40_Sandbox.Painter;

package body SCD40_Sandbox.Widgets is

   Shadow_Color           : constant := 16#18C3#;
   Background_Color       : constant := 16#2124#;
   Label_Background_Color : constant := 16#2965#;
   Label_Line_Color       : constant := 16#4228#;
   Label_Text_Color       : constant := 16#DF1B#;
   Line_Color             : constant := 16#0392#;
   Fill_Color             : constant := 16#21C7#;

   TW : constant := 28;

   function Map
     (L : A0B.Types.Integer_32;
      H : A0B.Types.Integer_32;
      V : A0B.Types.Integer_32) return A0B.Types.Integer_32;

   ----------
   -- Draw --
   ----------

   procedure Draw (Self : in out Widget; Value : A0B.Types.Integer_32) is
      use type A0B.Types.Integer_32;

      Text        : constant String :=
        A0B.Types.Integer_32'Image (Value)
          & (if Self.S = ' ' then "" else " " & Self.S);
      Text_Width  : constant A0B.Types.Integer_32 := Text'Length * TW;
      Text_Offset : constant A0B.Types.Integer_32 :=
        (Self.W - Text_Width) / 2;

   begin
      Self.G (Self.G'First .. Self.G'Last - 1) :=
        Self.G (Self.G'First + 1 .. Self.G'Last);
      Self.G (Self.G'Last) := Map (Self.VL, Self.VH, Value);

      Painter.Set_Color (Shadow_Color);
      Painter.Fill_Rect (Self.X - 8, Self.Y - 8, Self.W + 16, Self.H + 16);

      Painter.Set_Color (Background_Color);
      Painter.Fill_Rect (Self.X, Self.Y, Self.W, Self.H);

      Painter.Set_Color (Label_Background_Color);
      Painter.Fill_Rect (Self.X + 4, Self.Y + 4, Self.W - 8, 68 - 6);

      Painter.Set_Color (Label_Line_Color);
      Painter.Fill_Rect (Self.X + 4, Self.Y + 68 - 2, Self.W - 8, 2);

      Painter.Set_Color (Label_Text_Color);
      Painter.Set_Font
        (SCD40_Sandbox.Fonts.DejaVuSansCondensed_48.Font'Access);
      Painter.Draw_Text (Self.X + Text_Offset, Self.Y + 50, Text);

      for J in 0 .. Self.W - 1 - 8 loop
         if Self.G (J) in 0 .. 99 then
            Painter.Set_Color (Line_Color);
            Painter.Fill_Rect
              (Self.X + 4 + J, Self.Y + 76 + Self.G (J), 1, 1);

            if Self.G (J) < 99 then
               Painter.Set_Color (Fill_Color);
               Painter.Fill_Rect
                 (Self.X + 4 + J,
                  Self.Y + 76 + Self.G (J) + 1,
                  1,
                  99 - Self.G (J));
            end if;
         end if;
      end loop;
   end Draw;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self : in out Widget;
      X    : A0B.Types.Integer_32;
      Y    : A0B.Types.Integer_32;
      W    : A0B.Types.Integer_32;
      H    : A0B.Types.Integer_32;
      VL   : A0B.Types.Integer_32;
      VH   : A0B.Types.Integer_32;
      S    : Character) is
   begin
      Self.X  := X;
      Self.Y  := Y;
      Self.W  := W;
      Self.H  := H;
      Self.VL := VL;
      Self.VH := VH;
      Self.G  := (others => A0B.Types.Integer_32'First);
      Self.S  := S;
   end Initialize;

   ---------
   -- Map --
   ---------

   function Map
     (L : A0B.Types.Integer_32;
      H : A0B.Types.Integer_32;
      V : A0B.Types.Integer_32) return A0B.Types.Integer_32
   is
      use type A0B.Types.Integer_32;

   begin
      if V < L then
         return 99;

      elsif V > H then
         return 0;

      else
         return 99 - ((99 - 0) * (V - L) / (H - L));
      end if;
   end Map;

end SCD40_Sandbox.Widgets;
