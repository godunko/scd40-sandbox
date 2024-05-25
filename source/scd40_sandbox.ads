--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

private with A0B.Callbacks.Generic_Parameterless;
with A0B.Types;

package SCD40_Sandbox
  with Preelaborate
is

   SCD40_I2C_Address  : constant A0B.Types.Unsigned_7 := 16#62#;
   BME280_I2C_Address : constant A0B.Types.Unsigned_7 := 16#76#;
   BH1750_I2C_Address : constant A0B.Types.Unsigned_7 := 16#23#;

private

   procedure On_Done is null;

   package Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Done);

end SCD40_Sandbox;
