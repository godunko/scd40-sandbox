--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Implementation of the I2C slave device driver for SCD40 sensor.
--
--  This sensor requires delay between write and read operations without close
--  of the bus transaction.
--
--  Names of subprograms corresponds to SCD40 documentation.

pragma Restrictions (No_Elaboration_Code);

with A0B.Callbacks;
with A0B.Time;
private with A0B.Timer;

package A0B.I2C.SCD40
  with Preelaborate
is

   type SCD40_Command is mod 2**16;

   type Transaction_Status is record
      Written_Octets : A0B.Types.Unsigned_32;
      Read_Octets    : A0B.Types.Unsigned_32;
      State          : Transfer_State;
   end record;

   type SCD40_Driver
     (Controller : not null access I2C_Bus_Master'Class;
      Address    : Device_Address) is
     limited new Abstract_I2C_Device_Driver with private
       with Preelaborable_Initialization;

   procedure Send_Command
     (Self         : in out SCD40_Driver'Class;
      Command      : SCD40_Command;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean);

   procedure Write
     (Self         : in out SCD40_Driver'Class;
      Command      : SCD40_Command;
      Input        : Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean);

   procedure Read
     (Self           : in out SCD40_Driver'Class;
      Command        : SCD40_Command;
      Response       : out Unsigned_8_Array;
      Delay_Interval : A0B.Time.Time_Span;
      Status         : aliased out Transaction_Status;
      On_Completed   : A0B.Callbacks.Callback;
      Success        : in out Boolean);

   procedure Send_Command_And_Fetch_Result
     (Self           : in out SCD40_Driver'Class;
      Command        : SCD40_Command;
      Input          : Unsigned_8_Array;
      Delay_Interval : A0B.Time.Time_Span;
      Response       : out Unsigned_8_Array;
      Status         : aliased out Transaction_Status;
      On_Completed   : A0B.Callbacks.Callback;
      Success        : in out Boolean);

private

   type State is
     (Initial,
      Command,       --  write command
      Command_Read,  --  write command, read response
      Write,         --  write command and data
      Write_Read,    --  write command and data, read response
      Read);         --  read response

   type SCD40_Driver
     (Controller : not null access I2C_Bus_Master'Class;
      Address    : Device_Address) is
   limited new Abstract_I2C_Device_Driver with record
      State          : SCD40.State := Initial;
      Delay_Interval : A0B.Time.Time_Span;
      On_Completed   : A0B.Callbacks.Callback;
      Transaction    : access Transaction_Status;

      Command_Buffer : A0B.I2C.Unsigned_8_Array (0 .. 1);
      Write_Buffers  : A0B.I2C.Buffer_Descriptor_Array (0 .. 1);
      Read_Buffers   : A0B.I2C.Buffer_Descriptor_Array (0 .. 0);
      Timeout        : aliased A0B.Timer.Timeout_Control_Block;
   end record;

   overriding function Target_Address
     (Self : SCD40_Driver) return Device_Address is
       (Self.Address);

   overriding procedure On_Transfer_Completed (Self : in out SCD40_Driver);

   overriding procedure On_Transaction_Completed (Self : in out SCD40_Driver);

end A0B.I2C.SCD40;
