--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Warnings (Off, """System.Atomic_Primitives"" is an internal GNAT unit");
private with System.Atomic_Primitives;
private with System.Storage_Elements;

with A0B.ARMv7M;
with A0B.Callbacks;
with A0B.SVD.STM32H723.I2C;
private with A0B.Timer;
with A0B.Types;

package A0B.STM32H723.I2C
  with Preelaborate
is

   type Unsigned_8_Array is
     array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_8;

   subtype Address_7 is A0B.Types.Unsigned_7;

   subtype Address_10 is A0B.Types.Unsigned_10;

   type I2C_Controller
     (Peripheral      : not null access A0B.SVD.STM32H723.I2C.I2C_Peripheral;
      Event_Interrupt : A0B.ARMv7M.External_Interrupt_Number;
      Error_Interrupt : A0B.ARMv7M.External_Interrupt_Number) is
        tagged limited private with Preelaborable_Initialization;

   procedure Configure (Self : in out I2C_Controller'Class);

   type I2C_Slave_Device
     (Controller : not null access I2C_Controller'Class;
      Address    : Address_7) is tagged limited private
        with Preelaborable_Initialization;

   procedure Write
     (Self         : in out I2C_Slave_Device'Class;
      Write_Buffer : Unsigned_8_Array;
      Done         : A0B.Callbacks.Callback;
      Success      : in out Boolean);

   procedure Write_Read
     (Self         : in out I2C_Slave_Device'Class;
      Write_Buffer : Unsigned_8_Array;
      Read_Buffer  : out Unsigned_8_Array;
      Done         : A0B.Callbacks.Callback;
      Success      : in out Boolean);

   subtype I2C4_Controller is I2C_Controller
     (Peripheral      => A0B.SVD.STM32H723.I2C.I2C4_Periph'Access,
      Event_Interrupt => A0B.STM32H723.I2C4_EV,
      Error_Interrupt => A0B.STM32H723.I2C4_ER);

private

   type I2C_Slave_Device_Access is access all I2C_Slave_Device'Class;

   function Atomic_Compare_Exchange is
     new System.Atomic_Primitives.Atomic_Compare_Exchange
           (System.Storage_Elements.Integer_Address);

   type I2C_Controller
     (Peripheral      : not null access A0B.SVD.STM32H723.I2C.I2C_Peripheral;
      Event_Interrupt : A0B.ARMv7M.External_Interrupt_Number;
      Error_Interrupt : A0B.ARMv7M.External_Interrupt_Number) is
     tagged limited
   record
      Device : I2C_Slave_Device_Access;
   end record;

   procedure Select_Device
     (Self    : in out I2C_Controller'Class;
      Device  : aliased in out I2C_Slave_Device'Class;
      Success : in out Boolean);
   --  Selects given device to use bus for data transfer. When device is
   --  selected successfully it sets Success to True, otherwise Success is
   --  set to False.
   --
   --  Same device can be selected multiple times, operation fails only when
   --  another device occupy the bus.

   procedure Release_Device (Self : in out I2C_Controller'Class);

   procedure On_Event_Interrupt (Self : in out I2C_Controller'Class);

   procedure On_Error_Interrupt (Self : in out I2C_Controller'Class);

   type Bus_Operation is (Write, Read);

   type I2C_Transfer is record
      Operation : Bus_Operation;
      Buffer    : access Unsigned_8_Array;
      Index     : A0B.Types.Unsigned_32;
   end record;

   type I2C_Slave_Device
     (Controller : not null access I2C_Controller'Class;
      Address    : Address_7) is tagged limited
   record
      Transfer     : I2C_Transfer;
      Write_Buffer : access Unsigned_8_Array;
      Read_Buffer  : access Unsigned_8_Array;
      Done         : A0B.Callbacks.Callback;
      Timeout      : aliased A0B.Timer.Timeout_Control_Block;
      Busy         : Boolean := False with Volatile;
   end record;

   procedure On_Transfer_Complete (Self : in out I2C_Slave_Device'Class);
   --  Called when single transfer (write or read operation) is completed.

   procedure On_Transaction_Complete (Self : in out I2C_Slave_Device'Class);
   --  Called when transaction is completed (STOP condition is send) and
   --  bus is released.

end A0B.STM32H723.I2C;
