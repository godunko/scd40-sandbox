--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

pragma Warnings
         (Off, """Ada.Real_Time.Conversions"" is an internal GNAT unit");
with Ada.Real_Time.Conversions;

with A0B.Awaits;
with A0B.I2C.SCD40;
with A0B.SCD40;
with A0B.Tasking;
with A0B.Types.Arrays;

with HAQC.Configuration.Board;
with HAQC.Configuration.Sensors;

package body HAQC.Sensors.SCD40 is

   use type Ada.Real_Time.Time_Span;
   use type A0B.Operation_Status;

   Sensor : A0B.I2C.SCD40.SCD40_Driver
     (Controller => HAQC.Configuration.Board.I2C'Access,
      Address    => HAQC.Configuration.Sensors.SCD40_I2C_Address);

   SCD40_TCB : aliased A0B.Tasking.Task_Control_Block;

   procedure Task_Subprogram;

   Retry_Delay : constant Ada.Real_Time.Time_Span :=
     Ada.Real_Time.Milliseconds (100);

   procedure Send_Command_Retry
     (Command     : A0B.I2C.SCD40.SCD40_Command;
      Status      : aliased out A0B.I2C.SCD40.Transaction_Status;
      Retry_Delay : Ada.Real_Time.Time_Span;
      Success     : in out Boolean);

   procedure Read_Retry
     (Command       : A0B.I2C.SCD40.SCD40_Command;
      Response      : out A0B.Types.Arrays.Unsigned_8_Array;
      Command_Delay : Ada.Real_Time.Time_Span;
      Status        : aliased out A0B.I2C.SCD40.Transaction_Status;
      Retry_Delay   : Ada.Real_Time.Time_Span;
      Success       : in out Boolean);

   procedure Get_Serial_Number (Success : in out Boolean; Reset : out Boolean);
   --  Reading out the serial number can be used to identify the chip and to
   --  verify the presence of the sensor. The get_serial_number command returns
   --  3 words, and every word is followed by an 8-bit CRC checksum. Together,
   --  the 3 words constitute a unique serial number with a length of 48 bits
   --  (big endian format).

   procedure Start_Periodic_Measurement (Success : in out Boolean);
   --  Start periodic measurement mode. The signal update interval is 5
   --  seconds.

   procedure Stop_Periodic_Measurement (Success : in out Boolean);
   --  Stop periodic measurement mode to change the sensor configuration or to
   --  save power.
   --
   --  Note that the sensor will only respond to other commands 500 ms after
   --  the stop_periodic_measurement command has been issued.

   procedure Read_Measurement (Success : in out Boolean);
   --  Read sensor output. The measurement data can only be read out once per
   --  signal update interval as the buffer is emptied upon read-out. If no
   --  data is available in the buffer, the sensor returns a NACK. To avoid
   --  a NACK response, the get_data_ready_status can be issued to check data
   --  status (see Section 3.8.2 for further details). The I2C master can abort
   --  the read transfer with a NACK followed by a STOP condition after any
   --  data byte if the user is not interested in subsequent data.

   --  procedure Reinit;
   --  The reinit command reinitializes the sensor by reloading user
   --  settings from EEPROM. Before sending the reinit command, the
   --  stop_periodic_measurement command must be issued. If the reinit command
   --  does not trigger the desired re- initialization, a power-cycle should be
   --  applied to the SCD4x.

   --  procedure Perform_Factory_Reset;
   --  The perform_factory_reset command resets all configuration settings
   --  stored in the EEPROM and erases the FRC and ASC algorithm history.

   RRC  : Natural := 0 with Export;
   SCRC : Natural := 0 with Export;

   CO2 : A0B.Types.Unsigned_16 := 0 with Volatile;
   T   : A0B.Types.Unsigned_16 := 0 with Volatile;
   RH  : A0B.Types.Unsigned_16 := 0 with Volatile;

   -------------
   -- Get_CO2 --
   -------------

   function Get_CO2 return Integer is
   begin
      return Integer (CO2);
   end Get_CO2;

   ---------------------------
   -- Get_Data_Ready_Status --
   ---------------------------

   function Get_Data_Ready_Status (Success : in out Boolean) return Boolean is
      Response : A0B.SCD40.Get_Data_Ready_Status_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;
      Ready    : Boolean;

   begin
      Read_Retry
        (Command       => A0B.SCD40.Get_Data_Ready_Status,
         Response      => Response,
         Command_Delay => Ada.Real_Time.Milliseconds (1),
         Status        => Status,
         Retry_Delay   => Retry_Delay,
         Success       => Success);

      if not Success then
         raise Program_Error;
      end if;

      if not (Status.State = A0B.Success) then
         raise Program_Error;
      end if;

      A0B.SCD40.Parse_Get_Data_Ready_Status_Response
        (Response, Ready, Success);

      --  if not Success then
      --     raise Program_Error;
      --  end if;

      return Ready;
   end Get_Data_Ready_Status;

   ------------
   -- Get_RH --
   ------------

   function Get_RH return Integer is
   begin
      return Integer (RH);
   end Get_RH;

   -----------
   -- Get_T --
   -----------

   function Get_T return Integer is
   begin
      return Integer (T);
   end Get_T;

   -----------------------
   -- Get_Serial_Number --
   -----------------------

   procedure Get_Serial_Number
     (Success : in out Boolean; Reset : out Boolean)
   is
      Serial   : A0B.SCD40.Serial_Number;
      Response : A0B.SCD40.Get_Serial_Number_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;

   begin
      Reset := False;

      if not Success then
         return;
      end if;

      Read_Retry
        (Command       => A0B.SCD40.Get_Serial_Number,
         Response      => Response,
         Command_Delay => Ada.Real_Time.Milliseconds (1),
         Status        => Status,
         Retry_Delay   => Retry_Delay,
         Success       => Success);
      --  Success := @ and then Status.State = A0B.Success;

      if not Success then
         raise Program_Error;
      end if;

      if not (Status.State = A0B.Success) then
         Success := False;
         Reset   := True;
      end if;

      A0B.SCD40.Parse_Get_Serial_Number_Response (Response, Serial, Success);
   end Get_Serial_Number;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement (Success : in out Boolean) is
      Response : A0B.SCD40.Read_Measurement_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;

   begin
      Read_Retry
        (Command       => A0B.SCD40.Read_Measurement,
         Response      => Response,
         Command_Delay => Ada.Real_Time.Milliseconds (1),
         Status        => Status,
         Retry_Delay   => Retry_Delay,
         Success       => Success);
      --  Success := @ and then Status.State = A0B.Success;

      if not Success then
         raise Program_Error;
      end if;

      if not (Status.State = A0B.Success) then
         raise Program_Error;
      end if;

      A0B.SCD40.Parse_Read_Measurement_Response
        (Response,
         CO2,
         T,
         RH,
         Success);

      if not Success then
         raise Program_Error;
      end if;
   end Read_Measurement;

   ----------------
   -- Read_Retry --
   ----------------

   procedure Read_Retry
     (Command       : A0B.I2C.SCD40.SCD40_Command;
      Response      : out A0B.Types.Arrays.Unsigned_8_Array;
      Command_Delay : Ada.Real_Time.Time_Span;
      Status        : aliased out A0B.I2C.SCD40.Transaction_Status;
      Retry_Delay   : Ada.Real_Time.Time_Span;
      Success       : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      if not Success then
         return;
      end if;

      for Retry in 0 .. 9 loop
         Sensor.Read
           (Command        => Command,
            Response       => Response,
            Delay_Interval =>
              Ada.Real_Time.Conversions.To_Time_Span (Command_Delay),
            Status         => Status,
            On_Completed   => A0B.Awaits.Create_Callback (Await),
            Success        => Success);
         A0B.Awaits.Suspend_Until_Callback (Await, Success);

         exit when Success;

         RRC := @ + 1;

         delay until Ada.Real_Time.Clock + Retry_Delay;
         Success := True;
      end loop;
   end Read_Retry;

   -------------------
   -- Register_Task --
   -------------------

   procedure Register_Task is
   begin
      A0B.Tasking.Register_Thread (SCD40_TCB, Task_Subprogram'Access, 16#400#);
   end Register_Task;

   ------------------------
   -- Send_Command_Retry --
   ------------------------

   procedure Send_Command_Retry
     (Command     : A0B.I2C.SCD40.SCD40_Command;
      Status      : aliased out A0B.I2C.SCD40.Transaction_Status;
      Retry_Delay : Ada.Real_Time.Time_Span;
      Success     : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      if not Success then
         return;
      end if;

      for Retry in 0 .. 4 loop
         Sensor.Send_Command
           (Command      => Command,
            Status       => Status,
            On_Completed => A0B.Awaits.Create_Callback (Await),
            Success       => Success);
         A0B.Awaits.Suspend_Until_Callback (Await, Success);

         exit when Success;

         SCRC := @ + 1;

         delay until Ada.Real_Time.Clock + Retry_Delay;
         Success := True;
      end loop;
   end Send_Command_Retry;

   --------------------------------
   -- Start_Periodic_Measurement --
   --------------------------------

   procedure Start_Periodic_Measurement (Success : in out Boolean) is
      Status : aliased A0B.I2C.SCD40.Transaction_Status;

   begin
      if not Success then
         return;
      end if;

      Send_Command_Retry
        (Command     => A0B.SCD40.Start_Periodic_Measurement,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);

      if not Success then
         raise Program_Error;
      end if;

      if not (Status.State = A0B.Success) then
         raise Program_Error;
      end if;

      delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (1);
   end Start_Periodic_Measurement;

   -------------------------------
   -- Stop_Periodic_Measurement --
   -------------------------------

   procedure Stop_Periodic_Measurement (Success : in out Boolean) is
      Status : aliased A0B.I2C.SCD40.Transaction_Status;

   begin
      if not Success then
         return;
      end if;

      Send_Command_Retry
        (Command     => A0B.SCD40.Stop_Periodic_Measurement,
         Status      => Status,
         Retry_Delay => Retry_Delay,
         Success     => Success);

      if not Success then
         raise Program_Error;
      end if;

      if not (Status.State = A0B.Success) then
         raise Program_Error;
         --  Success := False;
      end if;

      delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (500);
   end Stop_Periodic_Measurement;

   ---------------------
   -- Task_Subprogram --
   ---------------------

   procedure Task_Subprogram is
      Success : Boolean;
      Reset   : Boolean;
      Miss    : Natural;

   begin
      loop
         Success := True;

         --  Get sensor's serial number.

         Get_Serial_Number (Success, Reset);

         if Reset then
            --  Operation fails when sensor is in the periodic measurement
            --  mode, stop periodic measurement to be able to configure sensor.

            Success := True;
            Stop_Periodic_Measurement (Success);
         end if;

         --  Configure sensore.

         --  Start periodic measurement.

         Start_Periodic_Measurement (Success);

         Miss := 0;

         loop
            delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);

            if Get_Data_Ready_Status (Success) then
               Miss := 0;

               Read_Measurement (Success);

               exit when not Success;

            else
               exit when not Success;

               Miss := @ + 1;
            end if;

            if Miss > 10 then
               raise Program_Error;
            end if;
         end loop;

         delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
      end loop;
      --
      --  Console.Put_Line
      --    ("SCD40 S/N:" & A0B.SCD40.Serial_Number'Image (Serial));
      --
      --  --  Configure sensor.
      --
      --  Set_Sensor_Altitude (428);
      --
      --  Start_Periodic_Measurement;
      --
      --  loop
      --     Delay_For (A0B.Time.Seconds (1));
      --
      --     if Get_Data_Ready_Status then
      --        Miss := 0;
      --
      --        Read_Measurement;
      --
      --        Console.Put_Line
      --          ("T "
      --           & A0B.Types.Unsigned_16'Image (T)
      --           & "  RH "
      --           & A0B.Types.Unsigned_16'Image (RH)
      --           & "  CO2 "
      --           & A0B.Types.Unsigned_16'Image (CO2));
      --
      --     else
      --        Miss := @ + 1;
      --        Console.Put ('.');
      --     end if;
      --
      --     if Miss > 10 then
      --        --  Too many misses, attempt to restart sensor.
      --
      --        Init := @ + 1;
      --
      --        if Init < 5 then
      --           Miss := 0;
      --           Console.Put_Line (" ... reinit ...");
      --
      --           --  Stop periodic measurement to be able to configure sensor.
      --
      --           Success := True;
      --           Stop_Periodic_Measurement (Success);
      --
      --           if not Success then
      --              raise Program_Error;
      --           end if;
      --
      --           --  Reinit sensor
      --
      --           Reinit;
      --
      --        else
      --           Miss := 0;
      --           Init := 0;
      --           Console.Put_Line (" ... factory reset ...");
      --
      --           --  Stop periodic measurement to be able to configure sensor.
      --
      --           Success := True;
      --           Stop_Periodic_Measurement (Success);
      --
      --           if not Success then
      --              raise Program_Error;
      --           end if;
      --
      --           --  DO factory reset of the sensor.
      --
      --           Perform_Factory_Reset;
      --        end if;
      --
      --        --  Configure sensor.
      --
      --        Set_Sensor_Altitude (428);
      --
      --        Start_Periodic_Measurement;
      --     end if;
      --  end loop;
   end Task_Subprogram;

   -----------------
   -- Write_Retry --
   -----------------

   --  procedure Write_Retry
   --    (Address     : A0B.I2C.Device_Drivers_8.Register_Address;
   --     Buffer      : A0B.Types.Arrays.Unsigned_8_Array;
   --     Status      : aliased out A0B.I2C.Device_Drivers_8.Transaction_Status;
   --     Retry_Delay : Ada.Real_Time.Time_Span;
   --     Success     : in out Boolean)
   --  is
   --     Await : aliased A0B.Awaits.Await;
   --
   --  begin
   --     if not Success then
   --        return;
   --     end if;
   --
   --     for Retry in 0 .. 4 loop
   --        Sensor.Write
   --          (Address      => Address,
   --           Buffer       => Buffer,
   --           Status       => Status,
   --           On_Completed => A0B.Awaits.Create_Callback (Await),
   --           Success      => Success);
   --        A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --        if not Success or Status.State /= A0B.Success then
   --           raise Program_Error;
   --        end if;
   --
   --        exit when Success;
   --
   --        delay until Ada.Real_Time.Clock + Retry_Delay;
   --     end loop;
   --  end Write_Retry;
   --
end HAQC.Sensors.SCD40;
