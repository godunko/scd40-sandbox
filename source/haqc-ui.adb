--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Awaits;
with A0B.I2C.SCD40;
with A0B.SCD40;
with A0B.STM32F401.USART;
with A0B.Time.Clock;
with A0B.Tasking;
with A0B.Types;

with HAQC.Configuration.Board;
with HAQC.Configuration.Sensors;

package body HAQC.UI is

   SCD40_Sensor : A0B.I2C.SCD40.SCD40_Driver
     (Controller => HAQC.Configuration.Board.I2C'Access,
      Address    => HAQC.Configuration.Sensors.SCD40_I2C_Address);

   TCB : aliased A0B.Tasking.Task_Control_Block;

   procedure Task_Subprogram;

   procedure Get_Serial_Number
     (Serial  : out A0B.SCD40.Serial_Number;
      Success : in out Boolean);
   --  Reading out the serial number can be used to identify the chip and to
   --  verify the presence of the sensor. The get_serial_number command returns
   --  3 words, and every word is followed by an 8-bit CRC checksum. Together,
   --  the 3 words constitute a unique serial number with a length of 48 bits
   --  (big endian format).

   procedure Start_Periodic_Measurement;
   --  Start periodic measurement mode. The signal update interval is 5
   --  seconds.

   procedure Stop_Periodic_Measurement (Success : in out Boolean);
   --  Stop periodic measurement mode to change the sensor configuration or to
   --  save power.
   --
   --  Note that the sensor will only respond to other commands 500 ms after
   --  the stop_periodic_measurement command has been issued.

   package Console is

      --  procedure Put (Item : Character);

      procedure Put (Item : String);

      procedure Put_Line (Item : String);

      procedure New_Line;

   end Console;

   procedure Delay_For (T : A0B.Time.Time_Span);

   CO2 : A0B.Types.Unsigned_16 := 0 with Volatile;
   T   : A0B.Types.Unsigned_16 := 0 with Volatile;
   RH  : A0B.Types.Unsigned_16 := 0 with Volatile;

   -------------
   -- Console --
   -------------

   package body Console is

      --------------
      -- New_Line --
      --------------

      procedure New_Line is
      begin
         Put (ASCII.CR & ASCII.LF);
      end New_Line;

      ---------
      -- Put --
      ---------

      --  procedure Put (Item : Character) is
      --     Buffer : String (1 .. 1);
      --
      --  begin
      --     Buffer (Buffer'First) := Item;
      --     Put (Buffer);
      --  end Put;

      ---------
      -- Put --
      ---------

      procedure Put (Item : String) is
         Buffers : A0B.STM32F401.USART.Buffer_Descriptor_Array (0 .. 0);
         Await   : aliased A0B.Awaits.Await;
         Success : Boolean := True;

      begin
         Buffers (0) :=
           (Address     => Item (Item'First)'Address,
            Size        => Item'Length,
            Transferred => <>,
            State       => <>);

         HAQC.Configuration.Board.UART.Transmit
           (Buffers  => Buffers,
            Finished => A0B.Awaits.Create_Callback (Await),
            Success  => Success);

         A0B.Awaits.Suspend_Until_Callback (Await, Success);
      end Put;

      --------------
      -- Put_Line --
      --------------

      procedure Put_Line (Item : String) is
      begin
         Put (Item);
         New_Line;
      end Put_Line;

   end Console;

   ---------------
   -- Delay_For --
   ---------------

   procedure Delay_For (T : A0B.Time.Time_Span) is
      use type A0B.Time.Time_Span;

   begin
      A0B.Tasking.Delay_Until (A0B.Time.Clock + T);
   end Delay_For;

   ---------------------------
   -- Get_Data_Ready_Status --
   ---------------------------

   function Get_Data_Ready_Status return Boolean is
      Response : A0B.SCD40.Get_Data_Ready_Status_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;
      Await    : aliased A0B.Awaits.Await;
      Success  : Boolean := True;
      Ready    : Boolean;

   begin
      SCD40_Sensor.Read
        (A0B.SCD40.Get_Data_Ready_Status,
         Response,
         A0B.Time.Milliseconds (1),
         Status,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      A0B.SCD40.Parse_Get_Data_Ready_Status_Response
        (Response, Ready, Success);

      if not Success then
         raise Program_Error;
      end if;

      return Ready;
   end Get_Data_Ready_Status;

   -----------------------
   -- Get_Serial_Number --
   -----------------------

   procedure Get_Serial_Number
     (Serial  : out A0B.SCD40.Serial_Number;
      Success : in out Boolean)
   is
      Response : A0B.SCD40.Get_Serial_Number_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;
      Await    : aliased A0B.Awaits.Await;

   begin
      if not Success then
         Serial := 0;

         return;
      end if;

      SCD40_Sensor.Read
        (A0B.SCD40.Get_Serial_Number,
         Response,
         A0B.Time.Milliseconds (1),
         Status,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      A0B.SCD40.Parse_Get_Serial_Number_Response (Response, Serial, Success);

      --  if not Success then
      --     raise Program_Error;
      --  end if;

      --  Delay_For (A0B.Time.Milliseconds (1));
   end Get_Serial_Number;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement is
      Response : A0B.SCD40.Read_Measurement_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;
      Await    : aliased A0B.Awaits.Await;
      Success  : Boolean := True;

   begin
      SCD40_Sensor.Read
        (A0B.SCD40.Read_Measurement,
         Response,
         A0B.Time.Milliseconds (1),
         Status,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      A0B.SCD40.Parse_Read_Measurement_Response
        (Response,
         CO2,
         T,
         RH,
         Success);

      if not Success then
         raise Program_Error;
      end if;

      Delay_For (A0B.Time.Milliseconds (1));
   end Read_Measurement;

   -------------------
   -- Register_Task --
   -------------------

   procedure Register_Task is
   begin
      A0B.Tasking.Register_Thread (TCB, Task_Subprogram'Access, 16#400#);
   end Register_Task;

   --------------------------
   -- Set_Ambient_Pressure --
   --------------------------

   --  procedure Set_Ambient_Pressure (To : A0B.Types.Unsigned_32) is
   --     Input   : A0B.SCD40.Set_Ambient_Pressure_Input;
   --     Status  : aliased A0B.I2C.SCD40.Transaction_Status;
   --     Await   : aliased A0B.Awaits.Await;
   --     Success : Boolean := True;
   --
   --  begin
   --     A0B.SCD40.Build_Set_Ambient_Pressure_Input (Input, To);
   --
   --     SCD40_Sensor.Write
   --       (A0B.SCD40.Set_Ambient_Pressure,
   --        Input,
   --        Status,
   --        A0B.Awaits.Create_Callback (Await),
   --        Success);
   --     A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --
   --     Delay_For (A0B.Time.Milliseconds (1));
   --  end Set_Ambient_Pressure;

   -------------------------
   -- Set_Sensor_Altitude --
   -------------------------

   procedure Set_Sensor_Altitude (To : A0B.Types.Unsigned_16) is
      Input   : A0B.SCD40.Set_Sensor_Altitude_Input;
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased A0B.Awaits.Await;
      Success : Boolean := True;

   begin
      A0B.SCD40.Build_Set_Sensor_Altitude_Input (Input, To);

      SCD40_Sensor.Write
        (A0B.SCD40.Set_Sensor_Altitude,
         Input,
         Status,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      if not Success then
         raise Program_Error;
      end if;

      Delay_For (A0B.Time.Milliseconds (1));
   end Set_Sensor_Altitude;

   --------------------------------
   -- Start_Periodic_Measurement --
   --------------------------------

   procedure Start_Periodic_Measurement is
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased A0B.Awaits.Await;
      Success : Boolean := True;

   begin
      SCD40_Sensor.Send_Command
        (A0B.SCD40.Start_Periodic_Measurement,
         Status,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      if not Success then
         raise Program_Error;
      end if;

      Delay_For (A0B.Time.Milliseconds (1));
   end Start_Periodic_Measurement;

   -------------------------------
   -- Stop_Periodic_Measurement --
   -------------------------------

   procedure Stop_Periodic_Measurement (Success : in out Boolean) is
      Status : aliased A0B.I2C.SCD40.Transaction_Status;
      Await  : aliased A0B.Awaits.Await;

   begin
      if not Success then
         return;
      end if;

      SCD40_Sensor.Send_Command
        (A0B.SCD40.Stop_Periodic_Measurement,
         Status,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      Delay_For (A0B.Time.Milliseconds (500));
   end Stop_Periodic_Measurement;

   ---------------------
   -- Task_Subprogram --
   ---------------------

   procedure Task_Subprogram is
      Serial  : A0B.SCD40.Serial_Number;
      Success : Boolean := True;

   begin
      Console.New_Line;
      Console.Put_Line ("Home Air Quality Controller");
      Console.New_Line;

      loop
         --  Get sensor's serial number.

         Success := True;
         Get_Serial_Number (Serial, Success);

         exit when Success;

         --  Operation fails when sensor is in the periodic measurement mode,
         --  stop periodic measurement to be able to configure sensor.

         Success := True;
         Stop_Periodic_Measurement (Success);

         if not Success then
            raise Program_Error;
         end if;
      end loop;

      Console.Put_Line
        ("SCD40 S/N:" & A0B.SCD40.Serial_Number'Image (Serial));

      --  Configure sensor.

      Set_Sensor_Altitude (428);

      Start_Periodic_Measurement;

      loop
         Delay_For (A0B.Time.Seconds (1));

         if Get_Data_Ready_Status then
            Read_Measurement;

            Console.Put_Line
              ("T "
               & A0B.Types.Unsigned_16'Image (T)
               & "  RH "
               & A0B.Types.Unsigned_16'Image (RH)
               & "  CO2 "
               & A0B.Types.Unsigned_16'Image (CO2));
         end if;
      end loop;
   end Task_Subprogram;

end HAQC.UI;
