--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with GFX.Pixels.ILI9488_18;
with GFX.Framebuffers;
with SCD40_Sandbox.Fonts;

package GFX.Rasteriser.Bitmap_Fonts is

   procedure Draw_Text
     (Framebuffer : in out GFX.Framebuffers.Framebuffer;
      Font        : SCD40_Sandbox.Fonts.Font_Descriptor;
      Color       : GFX.Pixels.ILI9488_18.Pixel;
      X           : GFX.Rasteriser.Device_Pixel_Index;
      Y           : GFX.Rasteriser.Device_Pixel_Index;
      Text        : Wide_String);

end GFX.Rasteriser.Bitmap_Fonts;
