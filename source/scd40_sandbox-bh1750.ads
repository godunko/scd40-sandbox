--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

package SCD40_Sandbox.BH1750
  with Preelaborate
is

   procedure Initialize;

   function Get_Light_Value return A0B.Types.Unsigned_16;

end SCD40_Sandbox.BH1750;
