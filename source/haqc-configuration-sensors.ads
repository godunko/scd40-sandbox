--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.I2C;

package HAQC.Configuration.Sensors is

   pragma Preelaborate;

   SCD40_I2C_Address  : constant A0B.I2C.Device_Address := 16#62#;
   BME280_I2C_Address : constant A0B.I2C.Device_Address := 16#76#;
   --  BH1750_I2C_Address : constant A0B.I2C.Device_Address := 16#23#;

end HAQC.Configuration.Sensors;
