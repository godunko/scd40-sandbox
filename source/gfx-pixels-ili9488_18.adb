--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package body GFX.Pixels.ILI9488_18 is

   --------------
   -- From_RGB --
   --------------

   function From_RGB
     (R : Interfaces.Unsigned_8;
      G : Interfaces.Unsigned_8;
      B : Interfaces.Unsigned_8) return Pixel is
   begin
      return
        Pixel
          (GX_Unsigned (R) * 2 ** 16
           or GX_Unsigned (G) * 2 ** 8
           or GX_Unsigned (B));
   end From_RGB;

end GFX.Pixels.ILI9488_18;
