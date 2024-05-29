--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

package SCD40_Sandbox.Fonts.DejaVuSansCondensed_24
  with Preelaborate
is

   use type A0B.Types.Integer_8;

   Bitmap_Data : aliased constant Unsigned_8_Array :=

   Glyph_Data : aliased constant Glyph_Descriptor_Array :=

   Range_Data : aliased constant Character_Range_Descriptor_Array :=

   Font : aliased constant Font_Descriptor :=
     (Bitmap      => Bitmap_Data'Access,
      Glyph       => Glyph_Data'Access,
      Map         => Range_Data'Access,
      Line_Height => ,
      Base_Line   => );

end SCD40_Sandbox.Fonts;
