--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

package SCD40_Sandbox.SCD40
  with Preelaborate
is

   procedure Initialize;

   procedure Configure;

   procedure Get_Data_Ready_Status;

   procedure Set_Ambient_Pressure (To : A0B.Types.Unsigned_32);

   procedure Read_Measurement;

private

   procedure Perfom_Factory_Reset;

   procedure Reinit;

end SCD40_Sandbox.SCD40;
