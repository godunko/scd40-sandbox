--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.I2C.Device_Drivers;
with A0B.I2C.STM32H723_I2C.I2C4;

with SCD40_Sandbox.Await;

package body SCD40_Sandbox.BH1750 is

   BH_Sensor_Slave :
     A0B.I2C.Device_Drivers.I2C_Device_Driver
       (A0B.I2C.STM32H723_I2C.I2C4.I2C4'Access,
        BH1750_I2C_Address);

   ---------------------
   -- Get_Light_Value --
   ---------------------

   function Get_Light_Value return A0B.Types.Unsigned_16 is

      use type A0B.Types.Unsigned_16;

      Response : A0B.I2C.Unsigned_8_Array (0 .. 1);
      Success  : Boolean := True;
      Status   : aliased A0B.I2C.Device_Drivers.Transaction_Status;
      Await    : aliased SCD40_Sandbox.Await.Await;

   begin
      BH_Sensor_Slave.Read
        (Response,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      return
        A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (Response (0)), 8)
          or A0B.Types.Unsigned_16 (Response (1));
   end Get_Light_Value;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      Command : A0B.I2C.Unsigned_8_Array (0 .. 0);
      Success : Boolean := True;
      Status  : aliased A0B.I2C.Device_Drivers.Transaction_Status;
      Await   : aliased SCD40_Sandbox.Await.Await;

   begin
      --  Power On

      Command (0) := 2#0000_0001#;

      BH_Sensor_Slave.Write
        (Command,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      --  Start measument in high resolution mode

      Command (0) := 2#0001_0000#;

      BH_Sensor_Slave.Write
        (Command,
         Status,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);
      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Initialize;

end SCD40_Sandbox.BH1750;
