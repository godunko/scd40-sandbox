--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package A0B.ILI9488
  with Preelaborate
is

   RDDIDIF : constant := 16#04#;  --  Read Display Identification Information
                                  --  UNSUPPORTED, due to dummy bit (25bits)
   RDDST   : constant := 16#09#;  --  Read Display Status
                                  --  UNSUPPORTED, due to dummy bit (33bits)

   SLPIN   : constant := 16#10#;  --  Sleep IN
   SLPOUT  : constant := 16#11#;  --  Sleep OUT

   DISOFF  : constant := 16#28#;  --  Display OFF
   DISON   : constant := 16#29#;  --  Display ON

   RAMWR   : constant := 16#2C#;  --  Memory Write

   RDID1   : constant := 16#DA#;  --  Read ID1
   RDID2   : constant := 16#DB#;  --  Read ID2
   RDID3   : constant := 16#DC#;  --  Read ID3

end A0B.ILI9488;
