--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

package SCD40_Sandbox.Touch
  with Preelaborate
is

   procedure Initialize;

   procedure Get_Touch;

   type Values is record
      X  : A0B.Types.Unsigned_12;
      Y  : A0B.Types.Unsigned_12;
      Z1 : A0B.Types.Unsigned_12;
      Z2 : A0B.Types.Unsigned_12;
   end record;

   VAL : Values;

private

   type Unsigned_8_Array is
     array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_8;

   CMD : constant Unsigned_8_Array (0 .. 11) :=
     (16#B1#, 16#00#, 16#00#,
      16#C1#, 16#00#, 16#00#,
      16#D1#, 16#00#, 16#00#,
      16#90#, 16#00#, 16#00#);
   DAT : Unsigned_8_Array (0 .. 11) with Volatile;

end SCD40_Sandbox.Touch;
