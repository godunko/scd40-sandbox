--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SCD40_Sandbox.Fonts
  with Preelaborate
is

   type Unsigned_8_Array is
     array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_8;

   type Glyph_Descriptor is record
      Bitmap_Index : A0B.Types.Unsigned_32;
      Glyph_Width  : A0B.Types.Unsigned_16;
      Box_Width    : A0B.Types.Unsigned_8;
      Box_Height   : A0B.Types.Unsigned_8;
      Offset_X     : A0B.Types.Integer_8;
      Offset_Y     : A0B.Types.Integer_8;
   end record;

   type Glyph_Descriptor_Access is access constant Glyph_Descriptor;

   type Glyph_Descriptor_Array is
     array (A0B.Types.Unsigned_16 range <>) of aliased Glyph_Descriptor;

   type Character_Range_Descriptor is record
      First             : A0B.Types.Unsigned_32;
      Length            : A0B.Types.Unsigned_16;
      First_Glyph_Index : A0B.Types.Unsigned_16;
   end record;

   type Character_Range_Descriptor_Array is
     array (A0B.Types.Unsigned_32 range <>) of Character_Range_Descriptor;

   type Font_Descriptor is record
      Bitmap      : access constant Unsigned_8_Array;
      Glyph       : access constant Glyph_Descriptor_Array;
      Map         : access constant Character_Range_Descriptor_Array;
      Line_Height : A0B.Types.Unsigned_8;
      Base_Line   : A0B.Types.Unsigned_8;
   end record;

   type Font_Descriptor_Access is access constant Font_Descriptor;

end SCD40_Sandbox.Fonts;
