--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Interfaces;

private with A0B.Types;

package SCD40_Sandbox.BME280
  with Preelaborate
is

   type Power_Mode is (Sleep, Forced, Normal)
     with Size => 2;
   for Power_Mode use (Sleep => 16#00#, Forced => 2#10#, Normal => 2#11#);

   type Sensor_Data is private;

   procedure Initialize;

   procedure Configure
     (Mode                     : Power_Mode;
      Pressure_Oversampling    : Integer;
      Temperature_Oversampling : Integer;
      Humidity_Oversampling    : Integer);
   --  Allowed values for the oversamplig are:
   --     0 - sensor disabled
   --     1 - oversamling x1
   --     2 - oversamling x2
   --     4 - oversamling x4
   --     8 - oversamling x8
   --    16 - oversamling x16

   function Get_Sensor_Data return Sensor_Data;

   procedure Get_Compensated
     (Data        : Sensor_Data;
      Pressure    : out Interfaces.IEEE_Float_64;
      Temperature : out Interfaces.IEEE_Float_64;
      Humitidy    : out Interfaces.IEEE_Float_64);

private

   type Sensor_Data is record
      pressure    : A0B.Types.Unsigned_32;
      temperature : A0B.Types.Unsigned_32;
      humidity    : A0B.Types.Unsigned_32;
   end record;

end SCD40_Sandbox.BME280;
