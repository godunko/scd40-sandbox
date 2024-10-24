--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);
pragma Ada_2022;

with A0B.Types;

package body GFX.Rasteriser.Bitmap_Fonts is

   ---------------
   -- Draw_Text --
   ---------------

   procedure Draw_Text
     (Framebuffer : in out GFX.Framebuffers.Framebuffer;
      Font        : SCD40_Sandbox.Fonts.Font_Descriptor;
      Color       : GFX.Framebuffers.Pixel;
      X           : GFX.Rasteriser.Device_Pixel_Index;
      Y           : GFX.Rasteriser.Device_Pixel_Index;
      Text        : Wide_String)
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
                  GFX.Framebuffers.Set
                    (Self  => Framebuffer,
                     X     => GFX.Rasteriser.Device_Pixel_Index (XC),
                     Y     => GFX.Rasteriser.Device_Pixel_Index (YC),
                     Value => Color);
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

         for J of Font.Map.all loop
            if Code in
              J.First .. J.First + A0B.Types.Unsigned_32 (J.Length) - 1
            then
               Glyph :=
                 Font.Glyph
                   (J.First_Glyph_Index
                      + A0B.Types.Unsigned_16 (Code - J.First) - 1)'Access;
            end if;
         end loop;

         Write_Glyph
           (XC,
            YC,
            Font.Bitmap (Glyph.Bitmap_Index .. Font.Bitmap'Last),
            A0B.Types.Unsigned_16 (Glyph.Box_Width),
            A0B.Types.Unsigned_16 (Glyph.Box_Height),
            A0B.Types.Integer_16 (Glyph.Offset_X),
            A0B.Types.Integer_16 (Glyph.Offset_Y),
            Glyph.Glyph_Width / 16);
      end loop;
   end Draw_Text;

end GFX.Rasteriser.Bitmap_Fonts;
