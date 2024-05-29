--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Callbacks;
with A0B.Types;

package A0B.I2C
  with Preelaborate
is

   type Unsigned_8_Array is
     array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_8;

   type Device_Address is mod 2**10;

   type Transfer_State is (Active, Success, Failure);
   --  Active, Success, Not_Acknowledged, Failure?

   type Transfer_Status is record
      Bytes : A0B.Types.Unsigned_32;
      State : Transfer_State;
   end record;

   type Abstract_I2C_Slave_Driver is tagged;

   type I2C_Slave_Driver_Access is
     access all Abstract_I2C_Slave_Driver'Class;

   type I2C_Bus_Master is limited interface;

   not overriding procedure Start
     (Self    : in out I2C_Bus_Master;
      Device  : not null I2C_Slave_Driver_Access;
      Success : in out Boolean) is abstract;
   --  Lock the bus to be used by the given slave device, and send START
   --  condition. When the bus is already locked, and slave device is the
   --  same with that locks the bus initially, ReSTART condition will be sent.
   --
   --  @param Self    Bus controller.
   --  @param Device  I2C device to do transfer.
   --  @param Success
   --    On input it specify whether operation should be processed.
   --    On output it returns whether operation has been initiated.

   not overriding procedure Write
     (Self    : in out I2C_Bus_Master;
      Device  : not null I2C_Slave_Driver_Access;
      Buffer  : Unsigned_8_Array;
      Status  : aliased out Transfer_Status;
      Stop    : Boolean;
      Success : in out Boolean) is abstract;
   --  Initiate write operation on the bus. Bus must be locked by the given
   --  device. When transfer direction changes, ReSTART condition is sent.
   --
   --  This operation is asynchronous. Associated slave device driver will be
   --  notified on completion of the data transfer.
   --
   --  @param Self    Bus controller.
   --  @param Device  I2C device to do transfer.
   --  @param Buffer  Buffer to load data to be transmitted to the device.
   --  @param Status  Operation status.
   --  @param Stop    Release bus after transfer completion.
   --  @param Success
   --    On input it specify whether operation should be processed.
   --    On output it returns whether operation has been initiated.

   not overriding procedure Read
     (Self    : in out I2C_Bus_Master;
      Device  : not null I2C_Slave_Driver_Access;
      Buffer  : out Unsigned_8_Array;
      Status  : aliased out Transfer_Status;
      Stop    : Boolean;
      Success : in out Boolean) is abstract;
   --  Initiate read operation on the bus. Bus must be locked by the locked by
   --  the given device. When transfer direction changes, ReSTART condition is
   --  sent.
   --
   --  This operation is asynchronous. Associated slave device driver will be
   --  notified on completion of the data transfer.
   --
   --  @param Self    Bus controller.
   --  @param Device  I2C device to do transfer.
   --  @param Buffer  Buffer to store data received from the device.
   --  @param Status  Operation status.
   --  @param Stop    Release bus after transfer completion.
   --  @param Success
   --    On input it specify whether operation should be processed.
   --    On output it returns whether operation has been initiated.

   not overriding procedure Stop
     (Self    : in out I2C_Bus_Master;
      Device  : not null I2C_Slave_Driver_Access;
      Success : in out Boolean) is abstract;
   --  Request release of the bus locked by the given device and to send STOP
   --  condition. Slave must be equal to value provided to Start procedure.
   --
   --  This operation is asynchronous. Associated slave device driver will be
   --  notified on completion of the transaction.
   --
   --  It can be called immediately after the call of Read/Write to request
   --  end of transaction when current operation has been completed.
   --  Associated slave device driver will be notified on both completion
   --  of the transfer and completion of the transaction.
   --
   --  @param Self    Bus controller.
   --  @param Device  I2C device to do transfer.
   --  @param Success
   --    On input it specify whether operation should be processed.
   --    On output it returns whether operation has been initiated.

   type Abstract_I2C_Slave_Driver is abstract tagged limited private;

   not overriding function Target_Address
     (Self : Abstract_I2C_Slave_Driver) return Device_Address is abstract;

   type I2C_Slave_Device is limited interface;

   not overriding procedure Write
     (Self         : in out I2C_Slave_Device;
      Write_Buffer : Unsigned_8_Array;
      Status       : out Transfer_Status;
      Done         : A0B.Callbacks.Callback;
      Success      : in out Boolean) is abstract;

   not overriding procedure Write_Read
     (Self         : in out I2C_Slave_Device;
      Write_Buffer : Unsigned_8_Array;
      Read_Buffer  : out Unsigned_8_Array;
      Status       : out Transfer_Status;
      Done         : A0B.Callbacks.Callback;
      Success      : in out Boolean) is abstract;

   not overriding procedure Read
     (Self        : in out I2C_Slave_Device;
      Read_Buffer : out Unsigned_8_Array;
      Status      : out Transfer_Status;
      Done        : A0B.Callbacks.Callback;
      Success     : in out Boolean) is abstract;

   not overriding procedure On_Not_Acknowledge
     (Self : in out I2C_Slave_Device) is abstract;
   --  ???

private

   type Abstract_I2C_Slave_Driver is
     abstract tagged limited null record;

   not overriding procedure On_Transfer_Completed
     (Self : in out Abstract_I2C_Slave_Driver) is null;

   not overriding procedure On_Transaction_Completed
     (Self : in out Abstract_I2C_Slave_Driver) is null;

end A0B.I2C;
