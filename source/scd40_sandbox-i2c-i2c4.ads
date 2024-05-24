--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  pragma Restrictions (No_Elaboration_Code);

package SCD40_Sandbox.I2C.I2C4
  with Preelaborate, Elaborate_Body
is

   I2C4 : aliased I2C4_Controller;

end SCD40_Sandbox.I2C.I2C4;
