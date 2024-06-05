--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Delays;
with A0B.I2C.SCD40;
with A0B.I2C.STM32H723_I2C.I2C4;
with A0B.SCD40;
with A0B.Time;

with SCD40_Sandbox.Await;
with SCD40_Sandbox.Globals;

package body SCD40_Sandbox.SCD40 is

   SCD40_Sensor_Slave : A0B.I2C.SCD40.SCD40_Driver
                         (A0B.I2C.STM32H723_I2C.I2C4.I2C4'Access,
                          SCD40_I2C_Address);

   procedure Get_Serial_Number;

   procedure Set_Sensor_Altitude (To : A0B.Types.Unsigned_16);

   procedure Start_Periodic_Measurement;

   procedure Stop_Periodic_Measurement;

   ---------------
   -- Configure --
   ---------------

   procedure Configure is
   begin
      Get_Serial_Number;
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (1));

      Stop_Periodic_Measurement;
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (500));

      --  Perfom_Factory_Reset;
      --  A0B.Delays.Delay_For (A0B.Time.Milliseconds (1_200));

      Reinit;
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (30));

      Set_Sensor_Altitude (550);
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (1));

      --  Set_Temperature_Offset (4);
      --  A0B.Delays.Delay_For (A0B.Time.Milliseconds (1));

      Start_Periodic_Measurement;
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (1));
   end Configure;

   ---------------------------
   -- Get_Data_Ready_Status --
   ---------------------------

   procedure Get_Data_Ready_Status is
      Response : A0B.SCD40.Get_Data_Ready_Status_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;
      Await    : aliased SCD40_Sandbox.Await.Await;
      Success  : Boolean := True;

   begin
      SCD40_Sensor_Slave.Read
        (A0B.SCD40.Get_Data_Ready_Status,
         Response,
         A0B.Time.Milliseconds (3),
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      A0B.SCD40.Parse_Get_Data_Ready_Status_Response
        (Response, Globals.Ready, Success);

      --  if not Success then
      --     raise Program_Error;
      --  end if;
   end Get_Data_Ready_Status;

   -----------------------
   -- Get_Serial_Number --
   -----------------------

   procedure Get_Serial_Number is
      Response : A0B.SCD40.Get_Serial_Number_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;
      Await    : aliased SCD40_Sandbox.Await.Await;
      Success  : Boolean := True;

   begin
      SCD40_Sensor_Slave.Read
        (A0B.SCD40.Get_Serial_Number,
         Response,
         A0B.Time.Milliseconds (1),
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      A0B.SCD40.Parse_Get_Serial_Number_Response
        (Response, SCD40_Sandbox.Globals.Serial, Success);
   end Get_Serial_Number;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      null;
   end Initialize;

   --------------------------
   -- Perfom_Factory_Reset --
   --------------------------

   procedure Perfom_Factory_Reset is
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased SCD40_Sandbox.Await.Await;
      Success : Boolean := True;

   begin
      SCD40_Sensor_Slave.Send_Command
        (A0B.SCD40.Perform_Factory_Reset,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Perfom_Factory_Reset;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement is
      Response : A0B.SCD40.Read_Measurement_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;
      Await    : aliased SCD40_Sandbox.Await.Await;
      Success  : Boolean := True;

   begin
      SCD40_Sensor_Slave.Read
        (A0B.SCD40.Read_Measurement,
         Response,
         A0B.Time.Milliseconds (1),
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      A0B.SCD40.Parse_Read_Measurement_Response
        (Response,
         Globals.CO2,
         Globals.T,
         Globals.RH,
         Success);

      --  if not Success then
      --     raise Program_Error;
      --  end if;
   end Read_Measurement;

   ------------
   -- Reinit --
   ------------

   procedure Reinit is
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased SCD40_Sandbox.Await.Await;
      Success : Boolean := True;

   begin
      SCD40_Sensor_Slave.Send_Command
        (A0B.SCD40.Reinit,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Reinit;

   --------------------------
   -- Set_Ambient_Pressure --
   --------------------------

   procedure Set_Ambient_Pressure (To : A0B.Types.Unsigned_32) is
      Input   : A0B.SCD40.Set_Ambient_Pressure_Input;
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased SCD40_Sandbox.Await.Await;
      Success : Boolean := True;

   begin
      A0B.SCD40.Build_Set_Ambient_Pressure_Input (Input, To);

      SCD40_Sensor_Slave.Write
        (A0B.SCD40.Set_Ambient_Pressure,
         Input,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Set_Ambient_Pressure;

   -------------------------
   -- Set_Sensor_Altitude --
   -------------------------

   procedure Set_Sensor_Altitude (To : A0B.Types.Unsigned_16) is
      Input   : A0B.SCD40.Set_Sensor_Altitude_Input;
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased SCD40_Sandbox.Await.Await;
      Success : Boolean := True;

   begin
      A0B.SCD40.Build_Set_Sensor_Altitude_Input (Input, To);

      SCD40_Sensor_Slave.Write
        (A0B.SCD40.Set_Sensor_Altitude,
         Input,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Set_Sensor_Altitude;

   ----------------------------
   -- Set_Temperature_Offset --
   ----------------------------

   procedure Set_Temperature_Offset (To : A0B.Types.Unsigned_16) is
      Input   : A0B.SCD40.Set_Temperature_Offset_Input;
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased SCD40_Sandbox.Await.Await;
      Success : Boolean := True;

   begin
      A0B.SCD40.Build_Set_Temperature_Offset_Input (Input, To);

      SCD40_Sensor_Slave.Write
        (A0B.SCD40.Set_Temperature_Offset,
         Input,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Set_Temperature_Offset;

   --------------------------------
   -- Start_Periodic_Measurement --
   --------------------------------

   procedure Start_Periodic_Measurement is
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased SCD40_Sandbox.Await.Await;
      Success : Boolean := True;

   begin
      SCD40_Sensor_Slave.Send_Command
        (A0B.SCD40.Start_Periodic_Measurement,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Start_Periodic_Measurement;

   -------------------------------
   -- Stop_Periodic_Measurement --
   -------------------------------

   procedure Stop_Periodic_Measurement is
      Status  : aliased A0B.I2C.SCD40.Transaction_Status;
      Await   : aliased SCD40_Sandbox.Await.Await;
      Success : Boolean := True;

   begin
      SCD40_Sensor_Slave.Send_Command
        (A0B.SCD40.Stop_Periodic_Measurement,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Stop_Periodic_Measurement;

end SCD40_Sandbox.SCD40;
