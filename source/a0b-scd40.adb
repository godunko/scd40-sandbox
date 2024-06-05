--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body A0B.SCD40 is

   use type A0B.Types.Unsigned_16;
   use type A0B.Types.Unsigned_8;

   CRC8_POLYNOMIAL : constant := 16#31#;
   CRC8_INIT       : constant := 16#FF#;

   function Sensirion_CRC
     (Data : A0B.I2C.Unsigned_8_Array) return A0B.Types.Unsigned_8;

   --------------------------------------
   -- Build_Set_Ambient_Pressure_Input --
   --------------------------------------

   procedure Build_Set_Ambient_Pressure_Input
     (Buffer   : out Set_Ambient_Pressure_Input;
      Pressure : A0B.Types.Unsigned_32)
   is
      use type A0B.Types.Unsigned_32;

      Value : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (Pressure / 100);
      H     : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (A0B.Types.Shift_Right (Value, 8));
      L     : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (Value and 16#FF#);

   begin
      Buffer (0) := H;
      Buffer (1) := L;
      Buffer (2) := Sensirion_CRC (Buffer (0 .. 1));
   end Build_Set_Ambient_Pressure_Input;

   -------------------------------------
   -- Build_Set_Sensor_Altitude_Input --
   -------------------------------------

   procedure Build_Set_Sensor_Altitude_Input
     (Buffer   : out Set_Sensor_Altitude_Input;
      Altitude : A0B.Types.Unsigned_16)
   is
      H     : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (A0B.Types.Shift_Right (Altitude, 8));
      L     : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (Altitude and 16#FF#);

   begin
      Buffer (0) := H;
      Buffer (1) := L;
      Buffer (2) := Sensirion_CRC (Buffer (0 .. 1));
   end Build_Set_Sensor_Altitude_Input;

   ----------------------------------------
   -- Build_Set_Temperature_Offset_Input --
   ----------------------------------------

   procedure Build_Set_Temperature_Offset_Input
     (Buffer   : out Set_Temperature_Offset_Input;
      Altitude : A0B.Types.Unsigned_16)
   is
      H     : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (A0B.Types.Shift_Right (Altitude, 8));
      L     : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (Altitude and 16#FF#);

   begin
      Buffer (0) := H;
      Buffer (1) := L;
      Buffer (2) := Sensirion_CRC (Buffer (0 .. 1));
   end Build_Set_Temperature_Offset_Input;

   -----------------------------------------
   -- Parse_Get_Data_Ready_Status_Command --
   -----------------------------------------

   procedure Parse_Get_Data_Ready_Status_Response
     (Response_Buffer : Get_Data_Ready_Status_Response;
      Ready           : out Boolean;
      Success         : in out Boolean) is
   begin
      if not Success
        or Sensirion_CRC (Response_Buffer (0 .. 1)) /= Response_Buffer (2)
      then
         Success := False;
         Ready   := False;

         return;
      end if;

      Ready :=
        ((A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (Response_Buffer (0)), 8)
            or A0B.Types.Unsigned_16 (Response_Buffer (1)))
          and 2#0000_0111_1111_1111#)
            /= 0;
   end Parse_Get_Data_Ready_Status_Response;

   --------------------------------------
   -- Parse_Get_Serial_Number_Response --
   --------------------------------------

   procedure Parse_Get_Serial_Number_Response
     (Buffer        : Get_Serial_Number_Response;
      Serial_Number : out SCD40.Serial_Number;
      Success       : in out Boolean)
   is
      use type A0B.Types.Unsigned_64;

      Aux : A0B.Types.Unsigned_64;

   begin
      if not Success
        or Sensirion_CRC (Buffer (0 .. 1)) /= Buffer (2)
        or Sensirion_CRC (Buffer (3 .. 4)) /= Buffer (5)
        or Sensirion_CRC (Buffer (6 .. 7)) /= Buffer (8)
      then
         Success       := False;
         Serial_Number := 0;
         --  CO2     := 0;
         --  T       := 0;
         --  RH      := 0;

         return;
      end if;

      Aux :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_64 (Buffer (0)), 40)
          or A0B.Types.Shift_Left (A0B.Types.Unsigned_64 (Buffer (1)), 32)
          or A0B.Types.Shift_Left (A0B.Types.Unsigned_64 (Buffer (3)), 24)
          or A0B.Types.Shift_Left (A0B.Types.Unsigned_64 (Buffer (4)), 16)
          or A0B.Types.Shift_Left (A0B.Types.Unsigned_64 (Buffer (6)), 8)
          or A0B.Types.Unsigned_64 (Buffer (7));

      Serial_Number := SCD40.Serial_Number (Aux);
   end Parse_Get_Serial_Number_Response;

   -------------------------------------
   -- Parse_Read_Measurement_Response --
   -------------------------------------

   procedure Parse_Read_Measurement_Response
     (Buffer  : Read_Measurement_Response;
      CO2     : out A0B.Types.Unsigned_16;
      T       : out A0B.Types.Unsigned_16;
      RH      : out A0B.Types.Unsigned_16;
      Success : in out Boolean)
   is
      ST : A0B.Types.Unsigned_16;
      SH : A0B.Types.Unsigned_16;

   begin
      if not Success
        or Sensirion_CRC (Buffer (0 .. 1)) /= Buffer (2)
        or Sensirion_CRC (Buffer (3 .. 4)) /= Buffer (5)
        or Sensirion_CRC (Buffer (6 .. 7)) /= Buffer (8)
      then
         Success := False;
         CO2     := 0;
         T       := 0;
         RH      := 0;

         return;
      end if;

      CO2 :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (Buffer (0)), 8)
          or A0B.Types.Unsigned_16 (Buffer (1));
      ST   :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (Buffer (3)), 8)
          or A0B.Types.Unsigned_16 (Buffer (4));
      SH  :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (Buffer (6)), 8)
          or A0B.Types.Unsigned_16 (Buffer (7));

      T :=
        A0B.Types.Unsigned_16
          (-45.0 + 175.0 * (Float (ST) / Float (2 ** 16 - 1)));
      RH :=
        A0B.Types.Unsigned_16
          (100.0 * (Float (SH) / Float (2 ** 16 - 1)));
   end Parse_Read_Measurement_Response;

   -------------------
   -- Sensirion_CRC --
   -------------------

   function Sensirion_CRC
     (Data : A0B.I2C.Unsigned_8_Array) return A0B.Types.Unsigned_8
   is
      CRC : A0B.Types.Unsigned_8 := CRC8_INIT;

   begin
      for C of Data loop
         CRC := @ xor C;

         for J in reverse 0 .. 7 loop
            if (CRC and 16#80#) /= 0 then
               CRC := A0B.Types.Shift_Left (@, 1) xor CRC8_POLYNOMIAL;

            else
               CRC := A0B.Types.Shift_Left (@, 1);
            end if;
         end loop;
      end loop;

      return CRC;
   end Sensirion_CRC;

end A0B.SCD40;
