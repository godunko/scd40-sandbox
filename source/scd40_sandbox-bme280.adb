--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Unchecked_Conversion;

with A0B.Delays;
with A0B.STM32H723.I2C.I2C4;
with A0B.Time;
with A0B.Types.GCC_Builtins;

with SCD40_Sandbox.Await;

package body SCD40_Sandbox.BME280
  with Preelaborate
is

   BME_Sensor_Slave :
     A0B.STM32H723.I2C.I2C_Slave_Device
       (A0B.STM32H723.I2C.I2C4.I2C4'Access, BME280_I2C_Address);

   CALIB00_Address   : constant := 16#88#;
   CHIP_ID_Address   : constant := 16#D0#;
   RESET_Address     : constant := 16#E0#;
   CALIB26_Address   : constant := 16#E1#;
   CTRL_HUM_Address  : constant := 16#F2#;
   STATUS_Address    : constant := 16#F3#;
   CTRL_MEAS_Address : constant := 16#F4#;
   CONFIG_Address    : constant := 16#F5#;
   PRESS_MSB_Address : constant := 16#F7#;

   BME280_CHIP_ID   : constant := 16#60#;
   RESET_KEY        : constant := 16#B6#;

   type Status_Register is record
      im_update    : Boolean;
      Reserved_1_2 : A0B.Types.Reserved_2;
      measuring    : Boolean;
      Reserved_4_7 : A0B.Types.Reserved_4;
   end record with Object_Size => 8;

   for Status_Register use record
      im_update    at 0 range 0 .. 0;
      Reserved_1_2 at 0 range 1 .. 2;
      measuring    at 0 range 3 .. 3;
      Reserved_4_7 at 0 range 4 .. 7;
   end record;

   type Ctrl_Hum_Register is record
      osrs_h       : A0B.Types.Unsigned_3;
      Reserved_3_7 : A0B.Types.Reserved_5;
   end record with Object_Size => 8;

   for Ctrl_Hum_Register use record
      osrs_h       at 0 range 0 .. 2;
      Reserved_3_7 at 0 range 3 .. 7;
   end record;

   type Ctrl_Meas_Register is record
      mode   : Power_Mode;
      osrs_p : A0B.Types.Unsigned_3;
      osrs_t : A0B.Types.Unsigned_3;
   end record with Object_Size => 8;

   for Ctrl_Meas_Register use record
      mode   at 0 range 0 .. 1;
      osrs_p at 0 range 2 .. 4;
      osrs_t at 0 range 5 .. 7;
   end record;

   type Config_Register is record
      spi3w_en   : Boolean;
      Reserved_1 : A0B.Types.Reserved_1;
      filter     : A0B.Types.Unsigned_3;
      t_sb       : A0B.Types.Unsigned_3;
   end record with Object_Size => 8;

   for Config_Register use record
      spi3w_en   at 0 range 0 .. 0;
      Reserved_1 at 0 range 1 .. 1;
      filter     at 0 range 2 .. 4;
      t_sb       at 0 range 5 .. 7;
   end record;

   type Calibration_Data is record
      Dig_T1 : A0B.Types.Unsigned_16;
      Dig_T2 : A0B.Types.Integer_16;
      Dig_T3 : A0B.Types.Integer_16;
      --  Calibration coefficients for the temperature sensor.

      Dig_P1 : A0B.Types.Unsigned_16;
      Dig_P2 : A0B.Types.Integer_16;
      Dig_P3 : A0B.Types.Integer_16;
      Dig_P4 : A0B.Types.Integer_16;
      Dig_P5 : A0B.Types.Integer_16;
      Dig_P6 : A0B.Types.Integer_16;
      Dig_P7 : A0B.Types.Integer_16;
      Dig_P8 : A0B.Types.Integer_16;
      Dig_P9 : A0B.Types.Integer_16;
      --  Calibration coefficients for the pressure sensor.

      Dig_H1 : A0B.Types.Unsigned_8;
      Dig_H2 : A0B.Types.Integer_16;
      Dig_H3 : A0B.Types.Unsigned_8;
      Dig_H4 : A0B.Types.Integer_16;
      Dig_H5 : A0B.Types.Integer_16;
      Dig_H6 : A0B.Types.Integer_8;
      --  Calibration coefficients for the humidity sensor.
   end record;

   function Get_Chip_Id return A0B.Types.Unsigned_8;

   procedure Soft_Reset;

   function Get_Status return Status_Register;

   procedure Get_Calibration_Data;

   subtype CALIB00_CALIB25_Response is
     A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 25);

   subtype CALIB26_CALIB41_Response is
     A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 15);

   procedure Parse_Calibration_Data
     (T    : CALIB00_CALIB25_Response;
      H    : CALIB26_CALIB41_Response;
      Data : out Calibration_Data);

   subtype Measure_Data_Response is
     A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 7);

   procedure Parse_Measure_Data
     (Response : Measure_Data_Response;
      Data     : out Sensor_Data);

   Calib   : Calibration_Data;
   --  Calib_T : A0B.Types.Integer_32;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Mode                     : Power_Mode;
      Pressure_Oversampling    : Integer;
      Temperature_Oversampling : Integer;
      Humidity_Oversampling    : Integer)
   is
      function To_Oversamplig (Value : Integer) return A0B.Types.Unsigned_3;

      --------------------
      -- To_Oversamplig --
      --------------------

      function To_Oversamplig (Value : Integer) return A0B.Types.Unsigned_3 is
         use type A0B.Types.Integer_32;

      begin
         if Value = 0 then
            return 0;

         elsif Value >= 16 then
            return 4;

         else
            return
              A0B.Types.Unsigned_3
                (32 - A0B.Types.GCC_Builtins.clz
                        (A0B.Types.Unsigned_32 (Value)));
         end if;
      end To_Oversamplig;

      --  Ctrl_Hum        : Ctrl_Hum_Register :=
      --    (osrs_h => To_Oversamplig (Humidity_Oversampling), others => <>);
      Command  : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);
      Success  : Boolean := True;
      Await    : aliased SCD40_Sandbox.Await.Await;

   begin
      --  Humidity, must be configured before pressure/temperature.

      declare
         Ctrl_Hum : Ctrl_Hum_Register
           with Import, Address => Command (1)'Address;

      begin
         Command (0) := CTRL_HUM_Address;
         Ctrl_Hum    :=
           (osrs_h => To_Oversamplig (Humidity_Oversampling), others => <>);
      end;

      BME_Sensor_Slave.Write
        (Command,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      --  Pressure/temperature/mode.

      declare
         Ctrl_Meas : Ctrl_Meas_Register
           with Import, Address => Command (1)'Address;

      begin
         Command (0) := CTRL_MEAS_Address;
         Ctrl_Meas   :=
           (mode   => Mode,
            osrs_p => To_Oversamplig (Pressure_Oversampling),
            osrs_t => To_Oversamplig (Temperature_Oversampling));
      end;

      BME_Sensor_Slave.Write
        (Command,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      --  Inactive duration in normal mode, IIR filter.
      --
      --  XXX Hardcoded!!!

      declare
         Config : Config_Register
           with Import, Address => Command (1)'Address;

      begin
         Command (0) := CONFIG_Address;
         Config      :=
           (spi3w_en => False,
            filter   => 1,       --  filter is off
            t_sb     => 2#100#,  --  mesurement delay is 500 ms
            others   => <>);
      end;

      BME_Sensor_Slave.Write
        (Command,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Configure;

   --------------------------
   -- Get_Calibration_Data --
   --------------------------

   procedure Get_Calibration_Data is
      Command     : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 0);
      Response_00 : CALIB00_CALIB25_Response;
      Response_26 : CALIB26_CALIB41_Response;
      Success     : Boolean := True;
      Await       : aliased SCD40_Sandbox.Await.Await;

   begin
      Command (0) := CALIB00_Address;

      BME_Sensor_Slave.Write_Read
        (Command,
         Response_00,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      Command (0) := CALIB26_Address;

      BME_Sensor_Slave.Write_Read
        (Command,
         Response_26,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      Parse_Calibration_Data (Response_00, Response_26, Calib);
   end Get_Calibration_Data;

   -----------------
   -- Get_Chip_Id --
   -----------------

   function Get_Chip_Id return A0B.Types.Unsigned_8 is
      Command  : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 0);
      Response : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 0);
      Success  : Boolean := True;
      Await    : aliased SCD40_Sandbox.Await.Await;

   begin
      Command (0) := CHIP_ID_Address;

      BME_Sensor_Slave.Write_Read
        (Command,
         Response,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      return Response (0);
   end Get_Chip_Id;

   ---------------------
   -- Get_Compensated --
   ---------------------

   procedure Get_Compensated
     (Data        : Sensor_Data;
      Pressure    : out Interfaces.IEEE_Float_64;
      Temperature : out Interfaces.IEEE_Float_64;
      Humitidy    : out Interfaces.IEEE_Float_64)
   is
      use type Interfaces.IEEE_Float_64;

      T1  : constant Interfaces.IEEE_Float_64 :=
        Interfaces.IEEE_Float_64 (Data.temperature) / 16_384.0
          - Interfaces.IEEE_Float_64 (Calib.Dig_T1) / 1_024.0;
      T12 : constant Interfaces.IEEE_Float_64 :=
        T1 * Interfaces.IEEE_Float_64 (Calib.Dig_T2);
      T2  : constant Interfaces.IEEE_Float_64 :=
        Interfaces.IEEE_Float_64 (Data.temperature) / 131_072.0
          - Interfaces.IEEE_Float_64 (Calib.Dig_T1) / 8_192.0;
      T22 : constant Interfaces.IEEE_Float_64 :=
        (T2 * T2) * Interfaces.IEEE_Float_64 (Calib.Dig_T3);
      T   : constant Interfaces.IEEE_Float_64 := T12 + T22;
      TT  : constant A0B.Types.Integer_32 :=
        A0B.Types.Integer_32 (T);
      --  P1 : constant Interfaces.IEEE_Float_64 := T / 2.0 - 64_000.0;
      --  P2 : constant Interfaces.IEEE_Float_64 :=
      --    (P1 * P1) * Interfaces.IEEE_Float_64 (Calib.Dig_P6) / 32_768.0;
      --  P22 : constant Interfaces.IEEE_Float_64 :=
      --    P2 + P1 * Interfaces.IEEE_Float_64 (Calib.Dig_P5) * 2.0;
      --  P23 : constant Interfaces.IEEE_Float_64 :=
      --    P22 / 4.0 + Interfaces.IEEE_Float_64 (Calib.Dig_P4) * 65_536.0;
      --  P3  : constant Interfaces.IEEE_Float_64 :=
      --    Interfaces.IEEE_Float_64 (Calib.Dig_P3) * P1 * P1 / 524_288.0;
      --  P11 : constant Interfaces.IEEE_Float_64 :=
      --    (P3 + Interfaces.IEEE_Float_64 (Calib.Dig_P2) * P1) / 524_288.0;
      --  P12 : constant Interfaces.IEEE_Float_64 :=
      --    (1.0 + P11 / 32_768.0) * Interfaces.IEEE_Float_64 (Calib.Dig_P1);
      --  P4  : constant Interfaces.IEEE_Float_64 :=
      --    1_048_576.0 - Interfaces.IEEE_Float_64 (Data.pressure);
      --  P5  : constant Interfaces.IEEE_Float_64 :=
      --    (P4 - (P23 / 4_096.0)) * 6_250.0 / P12;
      --  P13 : constant Interfaces.IEEE_Float_64 :=
      --    Interfaces.IEEE_Float_64 (Calib.Dig_P9)
      --  * P5 * P5 / 2_147_483_648.0;
      --  P24 : constant Interfaces.IEEE_Float_64 :=
      --    P5 * Interfaces.IEEE_Float_64 (Calib.Dig_P8) / 32_768.0;

      H1 : constant Interfaces.IEEE_Float_64 := T - 76_800.0;
      H2 : constant Interfaces.IEEE_Float_64 :=
        Interfaces.IEEE_Float_64 (Calib.Dig_H4) * 64.0
          + ((Interfaces.IEEE_Float_64 (Calib.Dig_H5) / 16_384.0) * H1);
      H3 : constant Interfaces.IEEE_Float_64 :=
        Interfaces.IEEE_Float_64 (Data.humidity) - H2;
      H4 : constant Interfaces.IEEE_Float_64 :=
        Interfaces.IEEE_Float_64 (Calib.Dig_H2) / 65_536.0;
      H5 : constant Interfaces.IEEE_Float_64 :=
        1.0 + Interfaces.IEEE_Float_64 (Calib.Dig_H3) / 67_108_864.0 * H1;
      H6 : constant Interfaces.IEEE_Float_64 :=
        1.0 + Interfaces.IEEE_Float_64 (Calib.Dig_H6) / 67_108_864.0 * H1 * H5;
      H7 : constant Interfaces.IEEE_Float_64 :=
        H3 * H4 * (H5 * H6);

   begin
      --  Calib_T := A0B.Types.Integer_32 (T);
      Temperature := T / 5_120.0;
      --  Pressure :=
      --    P5  + (P13 + P24 + Interfaces.IEEE_Float_64 (Calib.Dig_P7)) / 16.0;
      Humitidy :=
        H7 * (1.0 - Interfaces.IEEE_Float_64 (Calib.Dig_H1) * H7 / 524_288.0);

--  double var1, var2, p;
--  var1 = ((double)t_fine/2.0) – 64000.0;
--  var2 = var1 * var1 * ((double)dig_P6) / 32768.0;
--  var2 = var2 + var1 * ((double)dig_P5) * 2.0;
--  var2 = (var2/4.0)+(((double)dig_P4) * 65536.0);
--  var1 = (((double)dig_P3) * var1 * var1 / 524288.0
      --  + ((double)dig_P2) * var1) / 524288.0;
--  var1 = (1.0 + var1 / 32768.0)*((double)dig_P1);
--  if (var1 == 0.0)
--  {
--  return 0; // avoid exception caused by division by zero
--  }
--  p = 1048576.0 – (double)adc_P;
--  p = (p – (var2 / 4096.0)) * 6250.0 / var1;
--  var1 = ((double)dig_P9) * p * p / 2147483648.0;
--  var2 = p * ((double)dig_P8) / 32768.0;
--  p = p + (var1 + var2 + ((double)dig_P7)) / 16.0;

      declare
         Var1, Var2, P : Interfaces.IEEE_Float_64;

      begin
         Var1 := (Interfaces.IEEE_Float_64 (TT) / 2.0) - 64_000.0;
         --  Var1 := (T / 2.0) - 64_000.0;
         Var2 :=
           Var1 * Var1 * Interfaces.IEEE_Float_64 (Calib.Dig_P6) / 32_768.0;
         Var2 := Var2 + Var1 * Interfaces.IEEE_Float_64 (Calib.Dig_P5) * 2.0;
         Var2 :=
           (Var2 / 4.0) + (Interfaces.IEEE_Float_64 (Calib.Dig_P4) * 65_536.0);
         Var1 :=
           (Interfaces.IEEE_Float_64 (Calib.Dig_P3) * Var1 * Var1 / 524_288.0
              + Interfaces.IEEE_Float_64 (Calib.Dig_P2) * Var1) / 524_288.0;
         Var1 :=
           (1.0 + Var1 / 32_768.0) * Interfaces.IEEE_Float_64 (Calib.Dig_P1);
--  if (var1 == 0.0)
--  {
--  return 0; // avoid exception caused by division by zero
--  }
         P    := 1_048_576.0 - Interfaces.IEEE_Float_64 (Data.pressure);
         P    := (P - (Var2 / 4_096.0)) * 6_250.0 / Var1;
         Var1 :=
           Interfaces.IEEE_Float_64 (Calib.Dig_P9) * P * P / 2_147_483_648.0;
         Var2 := P * Interfaces.IEEE_Float_64 (Calib.Dig_P8) / 32_768.0;
         P    :=
           P + (Var1 + Var2 + Interfaces.IEEE_Float_64 (Calib.Dig_P7)) / 16.0;

         Pressure := P;
      end;
   end Get_Compensated;

   ---------------------
   -- Get_Sensor_Data --
   ---------------------

   function Get_Sensor_Data return Sensor_Data is
      Command  : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 0);
      Response : Measure_Data_Response;
      Success  : Boolean := True;
      Await    : aliased SCD40_Sandbox.Await.Await;
      Result   : Sensor_Data;

   begin
      Command (0) := PRESS_MSB_Address;

      BME_Sensor_Slave.Write_Read
        (Command,
         Response,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      Parse_Measure_Data (Response, Result);

      return Result;
   end Get_Sensor_Data;

   ----------------
   -- Get_Status --
   ----------------

   function Get_Status return Status_Register is
      Command  : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 0);
      Response : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 0);
      Result   : Status_Register with Import, Address => Response (0)'Address;
      Success  : Boolean := True;
      Await    : aliased SCD40_Sandbox.Await.Await;

   begin
      Command (0) := STATUS_Address;

      BME_Sensor_Slave.Write_Read
        (Command,
         Response,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      return Result;
   end Get_Status;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use type A0B.Types.Unsigned_8;

   begin
      if Get_Chip_Id /= BME280_CHIP_ID then
         raise Program_Error;
      end if;

      Soft_Reset;
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (2));

      if Get_Status.im_update /= False then
         raise Program_Error;
      end if;

      Get_Calibration_Data;
   end Initialize;

   ------------------------
   -- Parse_Measure_Data --
   ------------------------

   procedure Parse_Measure_Data
     (Response : Measure_Data_Response;
      Data     : out Sensor_Data)
   is
      use type A0B.Types.Unsigned_32;

   begin
      Data.pressure :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_32 (Response (0)), 12)
          or A0B.Types.Shift_Left (A0B.Types.Unsigned_32 (Response (1)), 4)
          or A0B.Types.Shift_Right (A0B.Types.Unsigned_32 (Response (2)), 4);
      Data.temperature :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_32 (Response (3)), 12)
          or A0B.Types.Shift_Left (A0B.Types.Unsigned_32 (Response (4)), 4)
          or A0B.Types.Shift_Right (A0B.Types.Unsigned_32 (Response (5)), 4);
      Data.humidity :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_32 (Response (6)), 8)
          or A0B.Types.Unsigned_32 (Response (7));
   end Parse_Measure_Data;

   ----------------------------
   -- Parse_Calibration_Data --
   ----------------------------

   procedure Parse_Calibration_Data
     (T    : CALIB00_CALIB25_Response;
      H    : CALIB26_CALIB41_Response;
      Data : out Calibration_Data)
   is
      use type A0B.Types.Unsigned_16;

      function To_Integer_8 is
        new Ada.Unchecked_Conversion
              (A0B.Types.Unsigned_8, A0B.Types.Integer_8);

      function To_Integer_16
        (High : A0B.Types.Unsigned_8;
         Low  : A0B.Types.Unsigned_8) return A0B.Types.Integer_16;

      function To_Integer_16 is
        new Ada.Unchecked_Conversion
              (A0B.Types.Unsigned_16, A0B.Types.Integer_16);

      function To_Unsigned_16
        (High : A0B.Types.Unsigned_8;
         Low  : A0B.Types.Unsigned_8) return A0B.Types.Unsigned_16;

      -------------------
      -- To_Integer_16 --
      -------------------

      function To_Integer_16
        (High : A0B.Types.Unsigned_8;
         Low  : A0B.Types.Unsigned_8) return A0B.Types.Integer_16 is
      begin
         return To_Integer_16 (To_Unsigned_16 (High, Low));
      end To_Integer_16;

      --------------------
      -- To_Unsigned_16 --
      --------------------

      function To_Unsigned_16
        (High : A0B.Types.Unsigned_8;
         Low  : A0B.Types.Unsigned_8) return A0B.Types.Unsigned_16 is
      begin
         return
           A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (High), 8)
             or A0B.Types.Unsigned_16 (Low);
      end To_Unsigned_16;

   begin
      Data.Dig_T1 := To_Unsigned_16 (T (1), T (0));
      Data.Dig_T2 := To_Integer_16 (T (3), T (2));
      Data.Dig_T3 := To_Integer_16 (T (5), T (4));

      Data.Dig_P1 := To_Unsigned_16 (T (7), T (6));
      Data.Dig_P2 := To_Integer_16 (T (9), T (8));
      Data.Dig_P3 := To_Integer_16 (T (11), T (10));
      Data.Dig_P4 := To_Integer_16 (T (13), T (12));
      Data.Dig_P5 := To_Integer_16 (T (15), T (14));
      Data.Dig_P6 := To_Integer_16 (T (17), T (16));
      Data.Dig_P7 := To_Integer_16 (T (19), T (18));
      Data.Dig_P8 := To_Integer_16 (T (21), T (20));
      Data.Dig_P9 := To_Integer_16 (T (23), T (22));

      Data.Dig_H1 := T (25);

      Data.Dig_H2 := To_Integer_16 (H (1), H (0));
      Data.Dig_H3 := H (2);
      Data.Dig_H4 :=
        To_Integer_16
          (A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (H (3)), 4)
             or (A0B.Types.Unsigned_16 (H (4)) and 16#0F#));
      Data.Dig_H5 :=
        To_Integer_16
          (A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (H (5)), 4)
             or A0B.Types.Shift_Right (A0B.Types.Unsigned_16 (H (4)), 4));
      Data.Dig_H6 := To_Integer_8 (H (6));
   end Parse_Calibration_Data;

   ----------------
   -- Soft_Reset --
   ----------------

   procedure Soft_Reset is
      Command : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);
      Success  : Boolean := True;
      Await    : aliased SCD40_Sandbox.Await.Await;

   begin
      Command (0) := RESET_Address;
      Command (1) := RESET_KEY;

      BME_Sensor_Slave.Write
        (Command,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Soft_Reset;

end SCD40_Sandbox.BME280;
