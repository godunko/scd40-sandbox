--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  PLL configuration and peripherals clock selection.
--
--  Peripherals reuse PLL channels, so all configuration done in single place
--  for better visibility.

package SCD40_Sandbox.System_Clocks
  with Preelaborate
is

   procedure Initialize;

end SCD40_Sandbox.System_Clocks;
