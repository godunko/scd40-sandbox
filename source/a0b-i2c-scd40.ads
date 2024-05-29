--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Implementation of the I2C slave device driver for SCD40 sensor.
--
--  This sensor requires delay between write and read operations without close
--  of the bus transaction.

pragma Restrictions (No_Elaboration_Code);

with A0B.Time;
private with A0B.Timer;

package A0B.I2C.SCD40
  with Preelaborate
is

   type Transaction_Status is record
      Written_Octets : A0B.Types.Unsigned_32;
      Read_Octets    : A0B.Types.Unsigned_32;
      State          : Transfer_State;
   end record;

   type SCD40_Driver
     (Controller : not null access I2C_Bus_Master'Class;
      Address    : Device_Address) is
     limited new Abstract_I2C_Slave_Driver with private
       with Preelaborable_Initialization;

   procedure Write
     (Self         : in out SCD40_Driver'Class;
      Buffer       : Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean);

   procedure Write_Read
     (Self           : in out SCD40_Driver'Class;
      Write_Buffer   : Unsigned_8_Array;
      Delay_Interval : A0B.Time.Time_Span;
      Read_Buffer    : out Unsigned_8_Array;
      Status         : aliased out Transaction_Status;
      On_Completed   : A0B.Callbacks.Callback;
      Success        : in out Boolean);

private

   type Transfer_Descriptor is record
      Buffer : access Unsigned_8_Array;
      Status : aliased Transfer_Status;
   end record;

   subtype Active_Transfer is A0B.Types.Unsigned_32;

   type Transfer_Decsriptor_Array is
     array (Active_Transfer range 0 .. 1) of Transfer_Descriptor;

   type SCD40_Driver
     (Controller : not null access I2C_Bus_Master'Class;
      Address    : Device_Address) is
   limited new Abstract_I2C_Slave_Driver with record
      Delay_Interval : A0B.Time.Time_Span;
      Transfers      : Transfer_Decsriptor_Array;
      Current        : Active_Transfer;
      Transaction    : access Transaction_Status;
      On_Completed   : A0B.Callbacks.Callback;
      Timeout        : aliased A0B.Timer.Timeout_Control_Block;
   end record;

   overriding function Target_Address
     (Self : SCD40_Driver) return Device_Address is
       (Self.Address);

   overriding procedure On_Transfer_Completed (Self : in out SCD40_Driver);

   overriding procedure On_Transaction_Completed (Self : in out SCD40_Driver);

end A0B.I2C.SCD40;
