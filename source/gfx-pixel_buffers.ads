--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with GFX.Pixels.ILI9488_18;
with GFX.Generic_Pixel_Buffers_24;

package GFX.Pixel_Buffers is
  new GFX.Generic_Pixel_Buffers_24 (GFX.Pixels.ILI9488_18.Pixel)
    with Preelaborate;
