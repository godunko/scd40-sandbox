--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Interfaces;

with A0B.Types;

with A0B.SCD40;

package SCD40_Sandbox.Globals
  with Preelaborate
is

   --  Serial_Response : A0B.SCD40.Get_Serial_Number_Response;
   Serial          : A0B.SCD40.Serial_Number with Volatile;

   --  Ready_Response : aliased A0B.SCD40.Get_Data_Ready_Status_Response;
   Ready          : Boolean := False;

   --  Measurement_Response : A0B.SCD40.Read_Measurement_Response;
   CO2                  : A0B.Types.Unsigned_16 := 0 with Volatile;
   T                    : A0B.Types.Unsigned_16 := 0 with Volatile;
   RH                   : A0B.Types.Unsigned_16 := 0 with Volatile;

   Pressure             : Interfaces.IEEE_Float_64 := 0.0 with Volatile;
   Temperature          : Interfaces.IEEE_Float_64 := 0.0 with Volatile;
   Humidity             : Interfaces.IEEE_Float_64 := 0.0 with Volatile;

   Light                : A0B.Types.Unsigned_16 := 0 with Volatile;

end SCD40_Sandbox.Globals;
