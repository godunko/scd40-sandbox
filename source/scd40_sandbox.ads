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

   Device_Id_I2C_Address : constant A0B.Types.Unsigned_7 := 2#1111_100#;
   SCD40_I2C_Address     : constant A0B.Types.Unsigned_7 := 16#62#;
   BNO055_I2C_Address    : constant A0B.Types.Unsigned_7 := 16#29#;
   MPU6XXX_Address       : constant A0B.Types.Unsigned_7 := 16#68#;

   B1 : A0B.Types.Unsigned_8;
   B2 : A0B.Types.Unsigned_8;
   B3 : A0B.Types.Unsigned_8;

private

   procedure On_Done is null;

   package Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Done);

   --  Serial_Response : A0B.SCD40.Get_Data_Ready_Status_Response;
   --  Serail          : A0B.SCD40.Serial_Number;

end SCD40_Sandbox;
