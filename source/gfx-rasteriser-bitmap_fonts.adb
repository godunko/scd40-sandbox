--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

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
      Text        : Wide_String) is
   begin
      raise Program_Error;
   end Draw_Text;

end GFX.Rasteriser.Bitmap_Fonts;