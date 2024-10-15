--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Awaits;
with A0B.I2C.SCD40;
with A0B.SCD40;
with A0B.STM32F401.USART;
with A0B.Time;
with A0B.Tasking;

with HAQC.Configuration.Board;
with HAQC.Configuration.Sensors;

package body HAQC.UI is

   SCD40_Sensor : A0B.I2C.SCD40.SCD40_Driver
     (Controller => HAQC.Configuration.Board.I2C'Access,
      Address    => HAQC.Configuration.Sensors.SCD40_I2C_Address);

   TCB : aliased A0B.Tasking.Task_Control_Block;

   procedure Task_Subprogram;

   function Get_Serial_Number return A0B.SCD40.Serial_Number;

   package Console is

      procedure Put (Item : Character);

      procedure Put (Item : String);

      procedure Put_Line (Item : String);

      procedure New_Line;

   end Console;

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

   -----------------------
   -- Get_Serial_Number --
   -----------------------

   function Get_Serial_Number return A0B.SCD40.Serial_Number is
      Response : A0B.SCD40.Get_Serial_Number_Response;
      Status   : aliased A0B.I2C.SCD40.Transaction_Status;
      Await    : aliased A0B.Awaits.Await;
      Success  : Boolean := True;
      Serial   : A0B.SCD40.Serial_Number;

   begin
      SCD40_Sensor.Read
        (A0B.SCD40.Get_Serial_Number,
         Response,
         A0B.Time.Milliseconds (1),
         Status,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      A0B.SCD40.Parse_Get_Serial_Number_Response (Response, Serial, Success);

      if not Success then
         raise Program_Error;
      end if;

      return Serial;
   end Get_Serial_Number;

   -------------------
   -- Register_Task --
   -------------------

   procedure Register_Task is
   begin
      A0B.Tasking.Register_Thread (TCB, Task_Subprogram'Access, 16#400#);
   end Register_Task;

   ---------------------
   -- Task_Subprogram --
   ---------------------

   procedure Task_Subprogram is
   begin
      Console.New_Line;
      Console.Put_Line ("Home Air Quality Controller");
      Console.New_Line;

      Console.Put_Line
        ("SCD40 S/N:" & A0B.SCD40.Serial_Number'Image (Get_Serial_Number));

      loop
         null;
      end loop;
   end Task_Subprogram;

end HAQC.UI;
