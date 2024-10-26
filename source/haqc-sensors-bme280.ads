--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package HAQC.Sensors.BME280 is

   type Temperature_Type is delta 1.0 / 100.0 range -99.0 .. 99.0;

   type Relative_Humidity_Type is delta 1.0 / 2 ** 10 range 0.0 .. 100.0;

   type Pressure_Type is delta 1.0 / 2 ** 8 range 30_000.0 .. 110_000.0;

   type Measurement_Type (Valid : Boolean := False) is record
      case Valid is
         when False =>
            null;

         when True =>
            Temperature       : Temperature_Type;
            Relative_Humidity : Relative_Humidity_Type;
            Pressure          : Pressure_Type;
      end case;
   end record;

   function Temperature return Temperature_Type;

   function Relative_Humidity return Relative_Humidity_Type;

   function Pressure return Pressure_Type;

   procedure Register_Task;

end HAQC.Sensors.BME280;
