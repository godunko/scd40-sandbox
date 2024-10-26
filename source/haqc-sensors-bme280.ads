--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package HAQC.Sensors.BME280 is

   --  type Deci_Celsius is delta 1.0 / 2 ** 9 range -99_0.00 .. 99_0.00;
   --  --  1 degree celsius is 10 Deci_Celsius
   --
   --  function Temperature
   --    (Value       : Measurement;
   --     Calibration : Calibration_Constants) return Deci_Celsius;
   --  --  Get the temperature from raw values in 0.1 Celsius
   --
   --  Humidity_Small : constant := 1.0 / 2 ** 10;
   --
   --  type Relative_Humidity is delta Humidity_Small range 0.0 .. 100.0;
   --  --  Relative humidity in percent
   --
   --  function Humidity
   --    (Value       : Measurement;
   --     Temperature : Deci_Celsius;
   --     Calibration : Calibration_Constants) return Relative_Humidity;
   --  --  Get the humidity from raw values
   --
   --  Pressure_Small : constant := 1.0 / 2 ** 8;
   --
   --  type Pressure_Pa is delta Pressure_Small range 30_000.0 .. 110_000.0;
   --  --  Pressure in Pa

   type Temperature_Type is delta 1.0 / 100.0 range -99.0 .. 99.0;

   type Relative_Humidity_Type is delta 1.0 / 2 ** 10 range 0.0 .. 100.0;

   type Pressure_Type is delta 1.0 / 2 ** 8 range 30_000.0 .. 110_000.0;

   function Temperature return Temperature_Type;

   function Relative_Humidity return Relative_Humidity_Type;

   function Pressure return Pressure_Type;

   procedure Register_Task;

end HAQC.Sensors.BME280;
