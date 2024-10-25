--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Pixel of ILI9488 display in 18-bit color mode.
--
--  RRRRRR.. GGGGGG.. BBBBBB..
--
--  bits marked by '.' are ignored by the display, thus used to store 6 bit
--  alpha value.

pragma Restrictions (No_Elaboration_Code);

package GFX.Pixels.ILI9488_18 is

   type Pixel is private;

   function From_RGB
     (R : Interfaces.Unsigned_8;
      G : Interfaces.Unsigned_8;
      B : Interfaces.Unsigned_8) return Pixel;

private

   type Pixel is mod 2 ** 24 with Size => 24;

end GFX.Pixels.ILI9488_18;
