--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

with A0B.I2C;

package A0B.SCD40
  with Preelaborate
is

   SCD40_I2C_Address : constant A0B.Types.Unsigned_7 := 16#62#;

   Get_Data_Ready_Status      : constant := 16#E4B8#;
   Get_Serial_Number          : constant := 16#3682#;
   Read_Measurement           : constant := 16#EC05#;
   Reinit                     : constant := 16#3646#;
   Perform_Factory_Reset      : constant := 16#3632#;
   Set_Ambient_Pressure       : constant := 16#E000#;
   Set_Sensor_Altitude        : constant := 16#2427#;
   Set_Temperature_Offset     : constant := 16#241D#;
   Start_Periodic_Measurement : constant := 16#21B1#;
   Stop_Periodic_Measurement  : constant := 16#3F86#;

   --  type CO2_Concentration is range 0 .. 40_000;
   --
   --  type Temperature is delta 1/2*15 range ;

   --

   subtype Read_Measurement_Response is A0B.I2C.Unsigned_8_Array (0 .. 8);

   procedure Parse_Read_Measurement_Response
     (Buffer  : Read_Measurement_Response;
      CO2     : out A0B.Types.Unsigned_16;
      T       : out A0B.Types.Unsigned_16;
      RH      : out A0B.Types.Unsigned_16;
      Success : in out Boolean);

   --  3.6.1 set_temperature_offset

   subtype Set_Temperature_Offset_Input is A0B.I2C.Unsigned_8_Array (0 .. 2);

   procedure Build_Set_Temperature_Offset_Input
     (Buffer   : out Set_Temperature_Offset_Input;
      Altitude : A0B.Types.Unsigned_16);
   --  Set temperature offset inside the customer device.
   --
   --  Value should be in range 0 .. 20 degrees of Celsius.

   --  3.6.3 set_sensor_altitude

   subtype Set_Sensor_Altitude_Input is A0B.I2C.Unsigned_8_Array (0 .. 2);

   procedure Build_Set_Sensor_Altitude_Input
     (Buffer   : out Set_Sensor_Altitude_Input;
      Altitude : A0B.Types.Unsigned_16);
   --  Set altitude in meters.
   --
   --  Value should be in range 0 .. 3_000 m.

   --  3.6.5 set_ambient_pressure

   subtype Set_Ambient_Pressure_Input is A0B.I2C.Unsigned_8_Array (0 .. 2);

   procedure Build_Set_Ambient_Pressure_Input
     (Buffer   : out Set_Ambient_Pressure_Input;
      Pressure : A0B.Types.Unsigned_32);
   --  Pressure is specified in Pa.
   --
   --  Value should be in range 70_000 .. 110_000 Pa.

   --

   subtype Get_Data_Ready_Status_Response
     is A0B.I2C.Unsigned_8_Array (0 .. 2);

   procedure Parse_Get_Data_Ready_Status_Response
     (Response_Buffer : Get_Data_Ready_Status_Response;
      Ready           : out Boolean;
      Success         : in out Boolean);

   --  3.9.2 get_serial_number

   subtype Get_Serial_Number_Response is A0B.I2C.Unsigned_8_Array (0 .. 8);

   type Serial_Number is mod 2 ** 48;

   procedure Parse_Get_Serial_Number_Response
     (Buffer        : Get_Serial_Number_Response;
      Serial_Number : out SCD40.Serial_Number;
      Success       : in out Boolean);

end A0B.SCD40;
