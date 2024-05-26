--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

with SCD40_Sandbox.Fonts;

package SCD40_Sandbox.Painter
  with Preelaborate
is

   subtype X_Coordinate is A0B.Types.Integer_32;

   subtype Y_Coordinate is A0B.Types.Integer_32;

   subtype RGB565_Color is A0B.Types.Unsigned_16;

   procedure Set_Color (Color : RGB565_Color);

   procedure Set_Font (Font : SCD40_Sandbox.Fonts.Font_Descriptor_Access);

   procedure Draw_Rect
     (X : A0B.Types.Integer_32;
      Y : A0B.Types.Integer_32;
      W : A0B.Types.Integer_32;
      H : A0B.Types.Integer_32);

   procedure Fill_Rect
     (X : A0B.Types.Integer_32;
      Y : A0B.Types.Integer_32;
      W : A0B.Types.Integer_32;
      H : A0B.Types.Integer_32);

   procedure Draw_Text
     (X    : A0B.Types.Integer_32;
      Y    : A0B.Types.Integer_32;
      Text : String);

end SCD40_Sandbox.Painter;
