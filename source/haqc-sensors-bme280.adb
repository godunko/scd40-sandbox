--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Real_Time;

with A0B.Awaits;
with A0B.I2C.Device_Drivers_8;
with A0B.Tasking;
with A0B.Types.Arrays;

--  with BME280;
with BME280.Raw;

with HAQC.Configuration.Board;
with HAQC.Configuration.Sensors;

package body HAQC.Sensors.BME280 is

   use type Ada.Real_Time.Time;
   use type A0B.Operation_Status;

   --  BEGIN Code to discuss

   CALIB00_Address   : constant := 16#88#;

   RESET_KEY         : constant := 16#B6#;

   ID_Address        : constant := 16#D0#;
   RESET_Address     : constant := 16#E0#;
   CALIB26_Address   : constant := 16#E1#;

   CTRL_HUM_Address  : constant := 16#F2#;
   --  STATUS_Address    : constant := 16#F3#;
   CTRL_MEAS_Address : constant := 16#F4#;
   CONFIG_Address    : constant := 16#F5#;

   PRESS_MSB_Address : constant := 16#F7#;

   --  subtype Id_Register is A0B.Types.Unsigned_8;
   subtype ID_Buffer is A0B.Types.Arrays.Unsigned_8_Array (0 .. 0);

   subtype RESET_Buffer is A0B.Types.Arrays.Unsigned_8_Array (0 .. 0);

   subtype CALIB00_CALIB25_Buffer is
     A0B.Types.Arrays.Unsigned_8_Array (0 .. 25);
   subtype CALIB26_CALIB41_Buffer is
     A0B.Types.Arrays.Unsigned_8_Array (0 .. 15);

   --  subtype CTRL_HUM_STATUS_CTRL_MEAS_Buffer is
   --    A0B.Types.Arrays.Unsigned_8_Array (0 .. 0);

   --  END Code to discuss

   Retry_Delay : constant Ada.Real_Time.Time_Span :=
     Ada.Real_Time.Milliseconds (100);

   procedure Task_Subprogram;

   BME280_TCB : aliased A0B.Tasking.Task_Control_Block;

   procedure Read_Retry
     (Address     : A0B.I2C.Device_Drivers_8.Register_Address;
      Buffer      : out A0B.Types.Arrays.Unsigned_8_Array;
      Status      : aliased out A0B.I2C.Device_Drivers_8.Transaction_Status;
      Retry_Delay : Ada.Real_Time.Time_Span;
      Success     : in out Boolean);

   procedure Write_Retry
     (Address     : A0B.I2C.Device_Drivers_8.Register_Address;
      Buffer      : A0B.Types.Arrays.Unsigned_8_Array;
      Status      : aliased out A0B.I2C.Device_Drivers_8.Transaction_Status;
      Retry_Delay : Ada.Real_Time.Time_Span;
      Success     : in out Boolean);

   Sensor      : A0B.I2C.Device_Drivers_8.I2C_Device_Driver
     (Controller => HAQC.Configuration.Board.I2C'Access,
      Address    => HAQC.Configuration.Sensors.BME280_I2C_Address);
   Calibration : Standard.BME280.Calibration_Constants;

   type Measurement_Record is record
      Temperature       : Standard.BME280.Deci_Celsius;
      Relative_Humidity : Standard.BME280.Relative_Humidity;
      Pressure          : Standard.BME280.Pressure_Pa;
   end record;

   Measurement : Measurement_Record;

   -----------------
   -- Temperature --
   -----------------

   function Temperature return Temperature_Type is
   begin
      return Temperature_Type (Measurement.Temperature / 10.0);
   end Temperature;

   -----------------------
   -- Relative_Humidity --
   -----------------------

   function Relative_Humidity return Relative_Humidity_Type is
   begin
      return Relative_Humidity_Type (Measurement.Relative_Humidity);
   end Relative_Humidity;

   --------------
   -- Pressure --
   --------------

   function Pressure return Pressure_Type is
   begin
      return Pressure_Type (Measurement.Pressure);
   end Pressure;

   -------------------
   -- Check_Chip_Id --
   -------------------

   procedure Check_Chip_Id
     (Success : in out Boolean)
   is
      use type A0B.Types.Unsigned_8;

      Buffer : ID_Buffer;
      Status : aliased A0B.I2C.Device_Drivers_8.Transaction_Status;

   begin
      if not Success then
         return;
      end if;

      Read_Retry
        (Address     => ID_Address,
         Buffer      => Buffer,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);

      Success :=
        @
          and then Status.State = A0B.Success
          and then Buffer (Buffer'First) = Standard.BME280.Chip_Id;

      if not Success then
         raise Program_Error;
      end if;
   end Check_Chip_Id;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (
     --  (Mode                     : Power_Mode;
     --   Pressure_Oversampling    : Integer;
     --   Temperature_Oversampling : Integer;
     --   Humidity_Oversampling    : Integer)
      Success : in out Boolean)
   is
   --     Buffer  : A0B.Types.Arrays.Unsigned_8_Array (0 .. 0);
   --     Status  : aliased A0B.I2C.Device_Drivers_8.Transaction_Status;
   --     Await   : aliased SCD40_Sandbox.Await.Await;
      Mode_Raw_1 : constant Standard.BME280.Raw.Mode_Data :=
        Standard.BME280.Raw.Set_Mode
          (Mode        => Standard.BME280.Sleep,
           Humidity    => Standard.BME280.X1,
           Pressure    => Standard.BME280.X1,
           Temperature => Standard.BME280.X1);
      Mode_Raw_2 : constant Standard.BME280.Raw.Mode_Data :=
        Standard.BME280.Raw.Set_Mode
          (Mode        => Standard.BME280.Normal,
           Humidity    => Standard.BME280.X1,
           Pressure    => Standard.BME280.X1,
           Temperature => Standard.BME280.X1);
      CONFIG_Raw : constant Standard.BME280.Raw.Configuration_Data :=
        Standard.BME280.Raw.Set_Configuration
          (Standby    => 1_000.0,
           Filter     => Standard.BME280.Off,
           SPI_3_Wire => False);

      Buffer : A0B.Types.Arrays.Unsigned_8_Array (0 .. 0);
      Status : aliased A0B.I2C.Device_Drivers_8.Transaction_Status;

   begin
      if not Success then
         return;
      end if;

      --  Humidity, must be configured before pressure/temperature.

      Buffer (0) := Mode_Raw_1 (Mode_Raw_1'First);
      Write_Retry
        (Address     => CTRL_HUM_Address,
         Buffer      => Buffer,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);
      Success := @ and then Status.State = A0B.Success;

      --  Pressure/temperature, mode should be set to sleep till configuration
      --  has been done.

      Buffer (0) := Mode_Raw_1 (Mode_Raw_1'Last);
      Write_Retry
        (Address     => CTRL_MEAS_Address,
         Buffer      => Buffer,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);
      Success := @ and then Status.State = A0B.Success;

      --  Inactive duration in normal mode, IIR filter.

      Buffer (0) := CONFIG_Raw (CONFIG_Raw'Last);
      Write_Retry
        (Address     => CONFIG_Address,
         Buffer      => Buffer,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);
      Success := @ and then Status.State = A0B.Success;

      --  Mode

      Buffer (0) := Mode_Raw_2 (Mode_Raw_2'Last);
      Write_Retry
        (Address     => CTRL_MEAS_Address,
         Buffer      => Buffer,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);
      Success := @ and then Status.State = A0B.Success;
   end Configure;

   --------------------------
   -- Get_Calibration_Data --
   --------------------------

   procedure Get_Calibration_Data (Success : in out Boolean) is
      Buffer_00 : CALIB00_CALIB25_Buffer;
      Buffer_26 : CALIB26_CALIB41_Buffer;
      Status    : aliased A0B.I2C.Device_Drivers_8.Transaction_Status;

   begin
      Read_Retry
        (Address     => CALIB00_Address,
         Buffer      => Buffer_00,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);
      Success := @ and then Status.State = A0B.Success;

      Read_Retry
        (Address     => CALIB26_Address,
         Buffer      => Buffer_26,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);
      Success := @ and then Status.State = A0B.Success;

      if not Success then
         return;
      end if;

      declare
         Constants : constant Standard.BME280.Raw.Calibration_Constants_Data :=
           (Data_1 => Standard.BME280.Byte_Array (Buffer_00),
            Data_2 => Standard.BME280.Byte_Array (Buffer_26 (0 .. 6)));

      begin
         Calibration :=
           Standard.BME280.Raw.Get_Calibration_Constants (Constants);
      end;
   end Get_Calibration_Data;

   --------------
   -- Get_Data --
   --------------

   procedure Get_Data (Success : in out Boolean) is
      Buffer      : Standard.BME280.Raw.Measurement_Data;
      Status      : aliased A0B.I2C.Device_Drivers_8.Transaction_Status;
      Measurement : Standard.BME280.Measurement;

   begin
   --     --  begin
   --     --     declare
   --     --        Command  : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);
   --     --        Ctrl_Meas : Ctrl_Meas_Register
   --     --          with Import, Address => Command (1)'Address;
   --     --
   --     --     begin
   --     --        Command (0) := CTRL_MEAS_Address;
   --     --        Ctrl_Meas   :=
   --     --          (mode   => Forced,
   --     --           --  (mode   => Mode,
   --     --           osrs_p => 5,
   --     --           osrs_t => 5);
   --     --
   --     --        BME_Sensor_Slave.Write
   --     --          (Command,
   --     --           SCD40_Sandbox.Await.Create_Callback (Await),
   --     --           Success);
   --     --
   --     --        SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   --     --
   --     --        A0B.Delays.Delay_For (A0B.Time.Microseconds (2));
   --     --     end;
   --     --  end;

      Read_Retry
        (Address     => PRESS_MSB_Address,
         Buffer      => A0B.Types.Arrays.Unsigned_8_Array (Buffer),
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);
      Success := @ and then Status.State = A0B.Success;

      if not Success then
         return;
      end if;

      Measurement := Standard.BME280.Raw.Get_Measurement (Buffer);

      BME280.Measurement.Temperature       :=
        Standard.BME280.Temperature (Measurement, Calibration);
      BME280.Measurement.Relative_Humidity :=
        Standard.BME280.Humidity
          (Measurement, BME280.Measurement.Temperature, Calibration);
      BME280.Measurement.Pressure          :=
        Standard.BME280.Pressure
          (Measurement, BME280.Measurement.Temperature, Calibration);
   end Get_Data;

   ----------------
   -- Read_Retry --
   ----------------

   procedure Read_Retry
     (Address     : A0B.I2C.Device_Drivers_8.Register_Address;
      Buffer      : out A0B.Types.Arrays.Unsigned_8_Array;
      Status      : aliased out A0B.I2C.Device_Drivers_8.Transaction_Status;
      Retry_Delay : Ada.Real_Time.Time_Span;
      Success     : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      if not Success then
         return;
      end if;

      for Retry in 0 .. 4 loop
         Sensor.Read
           (Address      => Address,
            Buffer       => Buffer,
            Status       => Status,
            On_Completed => A0B.Awaits.Create_Callback (Await),
            Success      => Success);
         A0B.Awaits.Suspend_Until_Callback (Await, Success);

         --  if not Success then
         --     if Status.State /= A0B.Success then
         --        raise Program_Error;
         --     end if;
         --
         --     --  raise Program_Error;
         --  end if;

         exit when Success;

         delay until Ada.Real_Time.Clock + Retry_Delay;
      end loop;
   end Read_Retry;

   -------------------
   -- Register_Task --
   -------------------

   procedure Register_Task is
   begin
      A0B.Tasking.Register_Thread
        (BME280_TCB, Task_Subprogram'Access, 16#400#);
   end Register_Task;

   ----------------
   -- Soft_Reset --
   ----------------

   procedure Soft_Reset (Success : in out Boolean) is
      Buffer : RESET_Buffer;
      Status : aliased A0B.I2C.Device_Drivers_8.Transaction_Status;

   begin
      Buffer (Buffer'First) := RESET_KEY;

      Write_Retry
        (Address     => RESET_Address,
         Buffer      => Buffer,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);
      Success := @ and then Status.State = A0B.Success;
   end Soft_Reset;

   ---------------------
   -- Task_Subprogram --
   ---------------------

   procedure Task_Subprogram is
      Success : Boolean;

   begin
      loop
         Success := True;

         --  Check sensor's availability.

         Check_Chip_Id (Success);

         --  Do soft reset of the sensor, and wait till it is completed.

         Soft_Reset (Success);
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (2);

      --  if Get_Status.im_update /= False then
      --     raise Program_Error;
      --  end if;

         --  Get calibration constants

         Get_Calibration_Data (Success);

         --  Configure sensor.

         Configure (Success);

         loop
            Get_Data (Success);

            exit when not Success;

            delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
         end loop;

         delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
      end loop;
   end Task_Subprogram;

   -----------------
   -- Write_Retry --
   -----------------

   procedure Write_Retry
     (Address     : A0B.I2C.Device_Drivers_8.Register_Address;
      Buffer      : A0B.Types.Arrays.Unsigned_8_Array;
      Status      : aliased out A0B.I2C.Device_Drivers_8.Transaction_Status;
      Retry_Delay : Ada.Real_Time.Time_Span;
      Success     : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      if not Success then
         return;
      end if;

      for Retry in 0 .. 4 loop
         Sensor.Write
           (Address      => Address,
            Buffer       => Buffer,
            Status       => Status,
            On_Completed => A0B.Awaits.Create_Callback (Await),
            Success      => Success);
         A0B.Awaits.Suspend_Until_Callback (Await, Success);

         if not Success or Status.State /= A0B.Success then
            raise Program_Error;
         end if;

         exit when Success;

         delay until Ada.Real_Time.Clock + Retry_Delay;
      end loop;
   end Write_Retry;

end HAQC.Sensors.BME280;
