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
     (Data : SCD40_Sandbox.I2C.Unsigned_8_Array) return A0B.Types.Unsigned_8;

   -----------------------------------------
   -- Build_Get_Data_Ready_Status_Command --
   -----------------------------------------

   procedure Build_Get_Data_Ready_Status_Command
     (Buffer : out Get_Data_Ready_Status_Command) is
   begin
      Buffer (0) := 16#E4#;
      Buffer (1) := 16#B8#;
   end Build_Get_Data_Ready_Status_Command;

   ----------------------------------------
   -- Build_Perfom_Factory_Reset_Command --
   ----------------------------------------

   procedure Build_Perfom_Factory_Reset_Command
     (Buffer : out Perfom_Factory_Reset_Command) is
   begin
      Buffer (0) := 16#36#;
      Buffer (1) := 16#32#;
   end Build_Perfom_Factory_Reset_Command;

   ---------------------------------
   -- Build_Serial_Number_Command --
   ---------------------------------

   procedure Build_Serial_Number_Command
     (Buffer : out Get_Serial_Number_Command) is
   begin
      Buffer (0) := 16#36#;
      Buffer (1) := 16#82#;
   end Build_Serial_Number_Command;

   ------------------------------------
   -- Build_Read_Measurement_Command --
   ------------------------------------

   procedure Build_Read_Measurement_Command
     (Buffer : out Read_Measurement_Command) is
   begin
      Buffer (0) := 16#EC#;
      Buffer (1) := 16#05#;
   end Build_Read_Measurement_Command;

   --------------------------------------------
   -- Build_Start_Periodic_Measument_Command --
   --------------------------------------------

   procedure Build_Start_Periodic_Measument_Command
     (Buffer : out Start_Periodic_Measument_Command) is
   begin
      Buffer (0) := 16#21#;
      Buffer (1) := 16#b1#;
   end Build_Start_Periodic_Measument_Command;

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
     (Data : SCD40_Sandbox.I2C.Unsigned_8_Array) return A0B.Types.Unsigned_8
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
