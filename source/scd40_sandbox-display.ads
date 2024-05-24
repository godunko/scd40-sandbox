--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

package SCD40_Sandbox.Display
  with Preelaborate
is

   procedure Initialize;

   procedure Redraw
     (CO2_Concentration : A0B.Types.Unsigned_16;
      Temperature       : A0B.Types.Unsigned_16;
      Humidity          : A0B.Types.Unsigned_16);

end SCD40_Sandbox.Display;
