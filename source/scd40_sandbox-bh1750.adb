--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32H723.I2C.I2C4;

with SCD40_Sandbox.Await;

package body SCD40_Sandbox.BH1750 is

   BH_Sensor_Slave :
     A0B.STM32H723.I2C.I2C_Slave_Device
       (A0B.STM32H723.I2C.I2C4.I2C4'Access, BH1750_I2C_Address);

   ---------------------
   -- Get_Light_Value --
   ---------------------

   function Get_Light_Value return A0B.Types.Unsigned_16 is

      use type A0B.Types.Unsigned_16;

      Command  : A0B.STM32H723.I2C.Unsigned_8_Array (1 .. 0);
      Response : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 1);
      Success  : Boolean := True;
      Await    : aliased SCD40_Sandbox.Await.Await;

   begin
      BH_Sensor_Slave.Write_Read
        (Command,
         Response,
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
      Command : A0B.STM32H723.I2C.Unsigned_8_Array (0 .. 0);
      Success : Boolean := True;
      Await   : aliased SCD40_Sandbox.Await.Await;

   begin
      --  Power On

      Command (0) := 2#0000_0001#;

      BH_Sensor_Slave.Write
        (Command,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);

      --  Start measument in high resolution mode

      Command (0) := 2#0001_0000#;

      BH_Sensor_Slave.Write
        (Command,
         SCD40_Sandbox.Await.Create_Callback (Await),
         Success);

      SCD40_Sandbox.Await.Suspend_Till_Callback (Await);
   end Initialize;

end SCD40_Sandbox.BH1750;
