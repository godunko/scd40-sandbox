--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.Awaits;
with A0B.STM32F401.USART;
with A0B.Time.Clock;
with A0B.Tasking;

with HAQC.Configuration.Board;
--  with HAQC.Configuration.Sensors;
with HAQC.Sensors.SCD40;

package body HAQC.UI is

   TCB : aliased A0B.Tasking.Task_Control_Block;

   procedure Task_Subprogram;

   package Console is

      procedure Put (Item : Character);

      procedure Put (Item : String);

      procedure Put_Line (Item : String);

      procedure New_Line;

   end Console;

   procedure Delay_For (T : A0B.Time.Time_Span);

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

      procedure Put (Item : Character) is
         Buffer : String (1 .. 1);

      begin
         Buffer (Buffer'First) := Item;
         Put (Buffer);
      end Put;

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
   -- Perform_Factory_Reset --
   ---------------------------

   --  procedure Perform_Factory_Reset is
   --     Status  : aliased A0B.I2C.SCD40.Transaction_Status;
   --     Await   : aliased A0B.Awaits.Await;
   --     Success : Boolean := True;
   --
   --  begin
   --     SCD40_Sensor.Send_Command
   --       (A0B.SCD40.Perform_Factory_Reset,
   --        Status,
   --        A0B.Awaits.Create_Callback (Await),
   --        Success);
   --     A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --
   --     Delay_For (A0B.Time.Milliseconds (1_200));
   --  end Perform_Factory_Reset;

   -------------------
   -- Register_Task --
   -------------------

   procedure Register_Task is
   begin
      A0B.Tasking.Register_Thread (TCB, Task_Subprogram'Access, 16#400#);
   end Register_Task;

   ------------
   -- Reinit --
   ------------

   --  procedure Reinit is
   --     Status  : aliased A0B.I2C.SCD40.Transaction_Status;
   --     Await   : aliased A0B.Awaits.Await;
   --     Success : Boolean := True;
   --
   --  begin
   --     SCD40_Sensor.Send_Command
   --       (A0B.SCD40.Reinit,
   --        Status,
   --        A0B.Awaits.Create_Callback (Await),
   --        Success);
   --     A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --
   --     Delay_For (A0B.Time.Milliseconds (30));
   --  end Reinit;

   -------------------------
   -- Set_Sensor_Altitude --
   -------------------------

   --  procedure Set_Sensor_Altitude (To : A0B.Types.Unsigned_16) is
   --     Input   : A0B.SCD40.Set_Sensor_Altitude_Input;
   --     Status  : aliased A0B.I2C.SCD40.Transaction_Status;
   --     Await   : aliased A0B.Awaits.Await;
   --     Success : Boolean := True;
   --
   --  begin
   --     A0B.SCD40.Build_Set_Sensor_Altitude_Input (Input, To);
   --
   --     SCD40_Sensor.Write
   --       (A0B.SCD40.Set_Sensor_Altitude,
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
   --  end Set_Sensor_Altitude;

   ---------------------
   -- Task_Subprogram --
   ---------------------

   procedure Task_Subprogram is
      --  Serial  : A0B.SCD40.Serial_Number;
      --  Success : Boolean := True;
      --  Miss    : Natural := 0;
      --  Init    : Natural := 0;

   begin
      Console.New_Line;
      Console.Put_Line ("Home Air Quality Controller");
      Console.New_Line;

      --  loop
      --     --  Get sensor's serial number.
      --
      --     Success := True;
      --     Get_Serial_Number (Serial, Success);
      --
      --     exit when Success;
      --
      --     --  Operation fails when sensor is in the periodic measurement mode,
      --     --  stop periodic measurement to be able to configure sensor.
      --
      --     Success := True;
      --     Stop_Periodic_Measurement (Success);
      --
      --     --  if not Success then
      --     --     raise Program_Error;
      --     --  end if;
      --  end loop;
      --
      --  Console.Put_Line
      --    ("SCD40 S/N:" & A0B.SCD40.Serial_Number'Image (Serial));
      --
      --  --  Configure sensor.
      --
      --  Set_Sensor_Altitude (428);
      --
      --  Start_Periodic_Measurement;

      loop
         Delay_For (A0B.Time.Seconds (1));

         --  if Get_Data_Ready_Status then
         --     Miss := 0;
         --
         --     Read_Measurement;

            Console.Put_Line
              ("T:"
               & Integer'Image (HAQC.Sensors.SCD40.Get_T)
               & "  RH:"
               & Integer'Image (HAQC.Sensors.SCD40.Get_RH)
               & "  CO2:"
               & Integer'Image (HAQC.Sensors.SCD40.Get_CO2));

         --  else
         --     Miss := @ + 1;
         --     Console.Put ('.');
         --  end if;
         --
         --  if Miss > 10 then
         --     --  Too many misses, attempt to restart sensor.
         --
         --     Init := @ + 1;
         --
         --     if Init < 5 then
         --        Miss := 0;
         --        Console.Put_Line (" ... reinit ...");
         --
         --        --  Stop periodic measurement to be able to configure sensor.
         --
         --        Success := True;
         --        Stop_Periodic_Measurement (Success);
         --
         --        if not Success then
         --           raise Program_Error;
         --        end if;
         --
         --        --  Reinit sensor
         --
         --        Reinit;
         --
         --     else
         --        Miss := 0;
         --        Init := 0;
         --        Console.Put_Line (" ... factory reset ...");
         --
         --        --  Stop periodic measurement to be able to configure sensor.
         --
         --        Success := True;
         --        Stop_Periodic_Measurement (Success);
         --
         --        if not Success then
         --           raise Program_Error;
         --        end if;
         --
         --        --  DO factory reset of the sensor.
         --
         --        Perform_Factory_Reset;
         --     end if;
         --
         --     --  Configure sensor.
         --
         --     Set_Sensor_Altitude (428);
         --
         --     Start_Periodic_Measurement;
         --  end if;
      end loop;
   end Task_Subprogram;

end HAQC.UI;
