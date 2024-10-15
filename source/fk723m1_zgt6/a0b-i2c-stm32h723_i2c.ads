--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Implementation of the I2C bus master for the STM32H723's I2C controller.

pragma Restrictions (No_Elaboration_Code);

with A0B.ARMv7M;
with A0B.STM32H723.SVD.I2C;
with A0B.STM32H723;

package A0B.I2C.STM32H723_I2C
  with Preelaborate
is

   type Master_Controller
     (Peripheral      : not null access A0B.STM32H723.SVD.I2C.I2C_Peripheral;
      Event_Interrupt : A0B.ARMv7M.External_Interrupt_Number;
      Error_Interrupt : A0B.ARMv7M.External_Interrupt_Number) is
        limited new I2C_Bus_Master with private
          with Preelaborable_Initialization;

   procedure Configure (Self : in out Master_Controller'Class);

   subtype I2C4_Controller is Master_Controller
     (Peripheral      => A0B.STM32H723.SVD.I2C.I2C4_Periph'Access,
      Event_Interrupt => A0B.STM32H723.I2C4_EV,
      Error_Interrupt => A0B.STM32H723.I2C4_ER);

private

   package Device_Locks is

      type Lock is limited private with Preelaborable_Initialization;

      procedure Acquire
        (Self    : in out Lock;
         Device  : not null I2C_Device_Driver_Access;
         Success : in out Boolean);

      procedure Release
        (Self    : in out Lock;
         Device  : not null I2C_Device_Driver_Access;
         Success : in out Boolean);

      function Device (Self : Lock) return I2C_Device_Driver_Access;

   private

      type Lock is limited record
         Device : I2C_Device_Driver_Access;
      end record;

      function Device (Self : Lock) return I2C_Device_Driver_Access is
        (Self.Device);

   end Device_Locks;

   --  type Controller_State is
   --    (Unused, Configured, Read, Write, Stop_Requested);

   type Master_Controller
     (Peripheral      : not null access A0B.STM32H723.SVD.I2C.I2C_Peripheral;
      Event_Interrupt : A0B.ARMv7M.External_Interrupt_Number;
      Error_Interrupt : A0B.ARMv7M.External_Interrupt_Number) is
   limited new I2C_Bus_Master with record
      Device_Lock : Device_Locks.Lock;
      --  State       : Controller_State := Unused;
      --  Buffer      : access Unsigned_8_Array;
      --  Status      : access Transfer_Status;
      Buffers     : access Buffer_Descriptor_Array;
      Active      : A0B.Types.Unsigned_32;
      Address     : System.Address;
      Stop        : Boolean;
   end record;

   overriding procedure Start
     (Self    : in out Master_Controller;
      Device  : not null I2C_Device_Driver_Access;
      Success : in out Boolean);

   overriding procedure Write
     (Self    : in out Master_Controller;
      Device  : not null I2C_Device_Driver_Access;
      Buffers : in out Buffer_Descriptor_Array;
      Stop    : Boolean;
      Success : in out Boolean);

   overriding procedure Read
     (Self    : in out Master_Controller;
      Device  : not null I2C_Device_Driver_Access;
      Buffers : in out Buffer_Descriptor_Array;
      Stop    : Boolean;
      Success : in out Boolean);

   overriding procedure Stop
     (Self    : in out Master_Controller;
      Device  : not null I2C_Device_Driver_Access;
      Success : in out Boolean);

   procedure On_Event_Interrupt (Self : in out Master_Controller'Class);

   procedure On_Error_Interrupt (Self : in out Master_Controller'Class);

end A0B.I2C.STM32H723_I2C;
