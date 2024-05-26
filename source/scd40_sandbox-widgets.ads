--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

package SCD40_Sandbox.Widgets
  with Preelaborate
is

   type Widget is tagged limited private
     with Preelaborable_Initialization;

   procedure Initialize
     (Self : in out Widget;
      X    : A0B.Types.Integer_32;
      Y    : A0B.Types.Integer_32;
      W    : A0B.Types.Integer_32;
      H    : A0B.Types.Integer_32;
      VL   : A0B.Types.Integer_32;
      VH   : A0B.Types.Integer_32;
      S    : access constant Wide_String := null);

   procedure Draw (Self : in out Widget; Value : A0B.Types.Integer_32);

private

   type Y_Array is
     array (A0B.Types.Integer_32 range <>) of A0B.Types.Integer_32;

   type Widget is tagged limited record
      X  : A0B.Types.Integer_32;
      Y  : A0B.Types.Integer_32;
      W  : A0B.Types.Integer_32;
      H  : A0B.Types.Integer_32;
      VH : A0B.Types.Integer_32;
      VL : A0B.Types.Integer_32;
      G  : Y_Array (0 .. 371);
      S  : access constant Wide_String;
   end record;

end SCD40_Sandbox.Widgets;
