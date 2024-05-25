--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

with A0B.STM32H723.I2C;

package A0B.SCD40
  with Preelaborate
is

   SCD40_I2C_Address : constant A0B.Types.Unsigned_7 := 16#62#;

   --  type CO2_Concentration is range 0 .. 40_000;
   --
   --  type Temperature is delta 1/2*15 range ;

   --

   subtype Start_Periodic_Measument_Command
     is A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);

   procedure Build_Start_Periodic_Measument_Command
     (Buffer : out Start_Periodic_Measument_Command);

   --

   subtype Read_Measurement_Command
     is A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);

   subtype Read_Measurement_Response
     is A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 8);

   procedure Build_Read_Measurement_Command
     (Buffer : out Read_Measurement_Command);

   procedure Parse_Read_Measurement_Response
     (Buffer  : Read_Measurement_Response;
      CO2     : out A0B.Types.Unsigned_16;
      T       : out A0B.Types.Unsigned_16;
      RH      : out A0B.Types.Unsigned_16;
      Success : in out Boolean);

   --  3.6.1 set_temperature_offset

   subtype Set_Temperature_Offset_Command is
     A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 4);

   procedure Build_Set_Temperature_Offset_Command
     (Buffer   : out Set_Temperature_Offset_Command;
      Altitude : A0B.Types.Unsigned_16);
   --  Set temperature offset inside the customer device.
   --
   --  Value should be in range 0 .. 20 degrees of Celsius.

   --  3.6.3 set_sensor_altitude

   subtype Set_Sensor_Altitude_Command is
     A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 4);

   procedure Build_Set_Sensor_Altitude_Command
     (Buffer   : out Set_Sensor_Altitude_Command;
      Altitude : A0B.Types.Unsigned_16);
   --  Set altitude in meters.
   --
   --  Value should be in range 0 .. 3_000 m.

   --  3.6.5 set_ambient_pressure

   subtype Set_Ambient_Pressure_Command is
     A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 4);

   procedure Build_Set_Ambient_Pressure_Command
     (Buffer   : out Set_Ambient_Pressure_Command;
      Pressure : A0B.Types.Unsigned_32);
   --  Pressure is specified in Pa.
   --
   --  Value should be in range 70_000 .. 110_000 Pa.

   --

   subtype Get_Data_Ready_Status_Command
     is A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);

   subtype Get_Data_Ready_Status_Response
     is A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 2);

   procedure Build_Get_Data_Ready_Status_Command
     (Buffer : out Get_Data_Ready_Status_Command);

   procedure Parse_Get_Data_Ready_Status_Response
     (Response_Buffer : Get_Data_Ready_Status_Response;
      Ready           : out Boolean;
      Success         : in out Boolean);

   --  3.9.2 get_serial_number

   subtype Get_Serial_Number_Command
     is A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);

   subtype Get_Serial_Number_Response
     is A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 8);

   type Serial_Number is mod 2 ** 48;

   procedure Build_Serial_Number_Command
     (Buffer : out Get_Serial_Number_Command);

   procedure Parse_Get_Serial_Number_Response
     (Buffer        : Get_Serial_Number_Response;
      Serial_Number : out SCD40.Serial_Number;
      Success       : in out Boolean);

   --  3.9.4 perfom_factory_reset

   subtype Perfom_Factory_Reset_Command
     is A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);

   procedure Build_Perfom_Factory_Reset_Command
     (Buffer : out Perfom_Factory_Reset_Command);

end A0B.SCD40;
