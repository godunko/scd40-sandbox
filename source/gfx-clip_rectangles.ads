--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package GFX.Clip_Rectangles
  with Pure
is

   type GI_Clip_Rectangle is record
      Top    : GFX.GX_Integer;
      Left   : GFX.GX_Integer;
      Right  : GFX.GX_Integer;
      Bottom : GFX.GX_Integer;
   end record;

end GFX.Clip_Rectangles;
