--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);
pragma Ada_2022;

with System.Address_To_Access_Conversions;
pragma Warnings (Off, """System.Atomic_Primitives"" is an internal GNAT unit");
with System.Atomic_Primitives;
with System.Storage_Elements;

with A0B.ARMv7M.NVIC_Utilities;

package body A0B.I2C.STM32H723_I2C
  with Preelaborate
is

   procedure Configure_Target_Address
     (Self : in out Master_Controller'Class);
   --  Configure target address.

   procedure Load_Into_TX (Self : in out Master_Controller'Class);
   --  Write next byte into the TX register, switch buffer when necessary.

   procedure Store_From_RX (Self : in out Master_Controller'Class);
   --  Read next byte from the RX register, switch buffer when necessary.

   ------------------------------
   -- Configure_Target_Address --
   ------------------------------

   procedure Configure_Target_Address
     (Self : in out Master_Controller'Class)
   is
      Target_Address : constant Device_Address :=
        Device_Locks.Device (Self.Device_Lock).Target_Address;

   begin
      --  if Self.State = Initial then
         --  Set device address and addressing mode to do its only once.

         declare
            Val : A0B.STM32H723.SVD.I2C.CR2_Register := Self.Peripheral.CR2;

         begin
            if Target_Address <= 16#7F# then
               Val.ADD10    := False;
               Val.SADD.Val :=
                 A0B.Types.Unsigned_10
                   (A0B.Types.Shift_Left
                      (A0B.Types.Unsigned_32 (Target_Address), 1));
               --  In 7-bit addressing mode device address should be written
               --  to SADD[7:1], so shift it left by one bit.

            else
               Val.ADD10    := True;
               Val.SADD.Val := A0B.Types.Unsigned_10 (Target_Address);
               --  In 7-bit addressing mode device address should be written
               --  to SADD[7:1], so shift it left by one bit.
            end if;

            Self.Peripheral.CR2 := Val;
         end;
      --  end if;
   end Configure_Target_Address;

   ---------------
   -- Configure --
   ---------------

   procedure Configure (Self : in out Master_Controller'Class) is
   begin
      --  Software reset I2C
      --
      --  [RM0468] 52.4.6 Software reset
      --
      --  "PE must be kept low during at least 3 APB clock cycles in order to
      --  perform the software reset. This is ensured by writing the following
      --  software sequence:
      --   - Write PE=0
      --   - Check PE=0
      --   - Write PE=1."
      --
      --  Note, I2C must be disabled to be able to configure some parameters
      --  (ANFOF, DNF, TIMING), so write PE=1 is not needed. This register will
      --  be read to preserve state of the reserved bits later, thus nothing to
      --  do here.

      Self.Peripheral.CR1.PE := False;

      --  Configure control register 1

      declare
         Val : A0B.STM32H723.SVD.I2C.CR1_Register := Self.Peripheral.CR1;

      begin
         Val.PECEN     := False;
         Val.ALERTEN   := False;
         Val.SMBDEN    := False;
         --  Device default address disabled (I2C mode)
         Val.SMBHEN    := False;    --  Host address disabled (I2C mode)
         Val.GCEN      := False;
         Val.WUPEN     := False;
         Val.NOSTRETCH := False;    --  Must be kept cleared in master mode
         Val.SBC       := False;
         Val.RXDMAEN   := False;    --  RX DMA disabled
         Val.TXDMAEN   := False;    --  TX DMA disabled
         Val.ANFOFF    := False;    --  Analog filter enabled
         Val.DNF       := 2#0000#;  --  Digital filter disabled
         Val.ERRIE     := True;     --  Error interrupt enabled
         Val.TCIE      := True;     --  Transfer Complete interrupt enabled
         Val.STOPIE    := True;
         --  Stop detection (STOPF) interrupt enabled
         Val.NACKIE    := True;
         --  Not acknowledge (NACKF) received interrupts enabled
         Val.ADDRIE    := False;
         --  Address match (ADDR) interrupts disabled
         Val.RXIE      := True;     --  Receive (RXNE) interrupt enabled
         Val.TXIE      := True;     --  Transmit (TXIS) interrupt enabled

         Self.Peripheral.CR1 := Val;
      end;

      --  Configure timing register (Fast Mode)

      declare
         Val : A0B.STM32H723.SVD.I2C.TIMINGR_Register :=
           Self.Peripheral.TIMINGR;

      begin
         --  Standard Mode

         Val.PRESC  := 16#2#;
         Val.SCLDEL := 16#A#;
         Val.SDADEL := 16#0#;
         Val.SCLH   := 16#AC#;
         Val.SCLL   := 16#FE#;

         --  Fast Mode
         --  Val.PRESC  := 0;
         --  Val.SCLDEL := 16#C#;
         --  Val.SDADEL := 0;
         --  Val.SCLH   := 16#45#;
         --  Val.SCLL   := 16#ED#;

         Self.Peripheral.TIMINGR := Val;
      end;

      --  Enable I2C

      Self.Peripheral.CR1.PE := True;

      --  Clear pending and enable NVIC interrupts

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Event_Interrupt);
      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Error_Interrupt);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Event_Interrupt);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Error_Interrupt);
   end Configure;

   ------------------
   -- Device_Locks --
   ------------------

   package body Device_Locks is

      function Atomic_Compare_Exchange is
        new System.Atomic_Primitives.Atomic_Compare_Exchange
              (System.Storage_Elements.Integer_Address);

      package Conversions is
        new System.Address_To_Access_Conversions
              (Abstract_I2C_Device_Driver'Class);

      -------------
      -- Acquire --
      -------------

      procedure Acquire
        (Self    : in out Lock;
         Device  : not null I2C_Device_Driver_Access;
         Success : in out Boolean)
      is
         Aux : System.Storage_Elements.Integer_Address :=
           System.Storage_Elements.To_Integer (System.Null_Address);

      begin
         if not Success
           or else (Self.Device /= null and Self.Device /= Device)
         then
            Success := False;

            return;
         end if;

         if Self.Device /= null then
            return;
         end if;

         if not Atomic_Compare_Exchange
           (Ptr      => Self.Device'Address,
            Expected => Aux'Address,
            Desired  =>
              System.Storage_Elements.To_Integer
                (Conversions.To_Address
                   (Conversions.Object_Pointer (Device))))
         then
            Success := False;

            return;
         end if;

      end Acquire;

      -------------
      -- Release --
      -------------

      procedure Release
        (Self    : in out Lock;
         Device  : not null I2C_Device_Driver_Access;
         Success : in out Boolean) is
      begin
         if not Success
           or else Self.Device /= Device
         then
            Success := False;

            return;
         end if;

         Self.Device := null;
      end Release;

   end Device_Locks;

   ------------------
   -- Load_Into_TX --
   ------------------

   procedure Load_Into_TX (Self : in out Master_Controller'Class) is
      use type A0B.Types.Unsigned_32;
      use type System.Address;
      use type System.Storage_Elements.Storage_Offset;

   begin
      if Self.Address = System.Null_Address then
         --  Start of the transfer

         Self.Address := Self.Buffers (Self.Active).Address;
      end if;

      loop
         exit when
           Self.Buffers (Self.Active).Size
             /= Self.Buffers (Self.Active).Transferred;

         Self.Buffers (Self.Active).State := Success;

         Self.Active  := @ + 1;
         Self.Address := Self.Buffers (Self.Active).Address;
      end loop;

      declare
         Data : constant A0B.Types.Unsigned_8
           with Import, Address => Self.Address;

      begin
         Self.Peripheral.TXDR.TXDATA := Data;

         Self.Address                           := @ + 1;
         Self.Buffers (Self.Active).Transferred := @ + 1;
      end;
   end Load_Into_TX;

   ------------------------
   -- On_Error_Interrupt --
   ------------------------

   procedure On_Error_Interrupt (Self : in out Master_Controller'Class) is
   begin
      raise Program_Error;
   end On_Error_Interrupt;

   ------------------------
   -- On_Event_Interrupt --
   ------------------------

   procedure On_Event_Interrupt (Self : in out Master_Controller'Class) is
      Status  : constant A0B.STM32H723.SVD.I2C.ISR_Register :=
        Self.Peripheral.ISR;
      Mask    : constant A0B.STM32H723.SVD.I2C.CR1_Register :=
        Self.Peripheral.CR1;

   begin
      if Status.TXIS then
         Self.Load_Into_TX;
      end if;

      if Status.RXNE then
         Self.Store_From_RX;
      end if;

      if Status.TC and Mask.TCIE then
         Self.Peripheral.CR1.TCIE := False;
         --  Disable TC (and TCR) interrupt, it is active till master sends
         --  START/STOP condition. Device driver need to be notified only
         --  once, and there is nothing to do till ball is on device driver's
         --  side.

         if Self.Stop then
            Self.Peripheral.CR2.STOP := True;
         end if;

         Device_Locks.Device (Self.Device_Lock).On_Transfer_Completed;
      end if;

      if Status.NACKF then
         Self.Peripheral.ICR.NACKCF := True;

         for J in Self.Active .. Self.Buffers'Last loop
            Self.Buffers (Self.Active).State := Failure;
         end loop;
      end if;

      if Status.STOPF then
         Self.Peripheral.ICR.STOPCF := True;
         --  Clear STOPF interrupt status

         --  if Self.  ???? Set status of the buffer ???

         declare
            Device  : constant I2C_Device_Driver_Access :=
              Device_Locks.Device (Self.Device_Lock);
            Success : Boolean := True;

         begin
            Device_Locks.Release (Self.Device_Lock, Device, Success);

            Device.On_Transaction_Completed;
         end;
      end if;

      -----------------------------------------------------------------------

      if Status.TCR and Mask.TCIE then
         raise Program_Error;
         --  Self.Peripheral.CR1.TCIE := False;
         --  --  Disable TCR and TC interrupts, software should write to NBYTES
         --  --  to clear this flag. It will be re-enabled after this write by
         --  --  Write/Read procedure.
         --
         --  Self.Status.State := Success;
         --  Device_Locks.Device (Self.Device_Lock).On_Transfer_Completed;
      end if;

      if Self.Peripheral.ISR.ADDR then
         raise Program_Error;
      end if;
   end On_Event_Interrupt;

   ----------
   -- Read --
   ----------

   overriding procedure Read
     (Self    : in out Master_Controller;
      Device  : not null I2C_Device_Driver_Access;
      Buffers : in out Buffer_Descriptor_Array;
      Stop    : Boolean;
      Success : in out Boolean)
   is
      use type A0B.Types.Unsigned_32;

      Size : A0B.Types.Unsigned_32 := 0;

   begin
      Device_Locks.Acquire (Self.Device_Lock, Device, Success);

      if not Success then
         return;
      end if;

      for Buffer of Buffers loop
         Size := @ + Buffer.Size;

         Buffer.Transferred  := 0;
         Buffer.State        := Active;
         Buffer.Acknowledged := False;
      end loop;

      Self.Buffers := Buffers'Unrestricted_Access;
      Self.Active  := 0;
      Self.Address := System.Null_Address;
      Self.Stop    := Stop;

      Self.Configure_Target_Address;

      --  A0B.ARMv7M.NVIC_Utilities.Disable_Interrupt (Self.Event_Interrupt);
      --  --  Disable event interrup from the peripheral controller to prevent
      --  --  undesired TC interrupt (it will be cleared by send of the START
      --  --  condition).

      --  Set transfer parameters and send (Re)START condition.

      declare
         Val : A0B.STM32H723.SVD.I2C.CR2_Register := Self.Peripheral.CR2;

      begin
         Val.RD_WRN  := True;           --  Master requests a read transfer.
         Val.NBYTES  := A0B.Types.Unsigned_8 (Size);
         --  Number of bytes to be transfered.

         Val.AUTOEND := False;
         Val.RELOAD  := False;
         Val.START   := True;
         --  Val.RELOAD  := True;

         Self.Peripheral.CR2 := Val;
      end;

      Self.Peripheral.CR1.TCIE := True;
      --  Enable TC and TCE interrupts.

      --  A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Event_Interrupt);
      --  A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Event_Interrupt);
      --  --  Clear pending interrupt status and enable interrupt.
   end Read;

   ----------
   -- Stop --
   ----------

   overriding procedure Stop
     (Self    : in out Master_Controller;
      Device  : not null I2C_Device_Driver_Access;
      Success : in out Boolean) is
   begin
      --
      --  A0B.ARMv7M.NVIC_Utilities.Disable_Interrupt (Self.Event_Interrupt);
      --  --  Disable event interrup from the peripheral controller to prevent
      --  --  undesired TC interrupt (it will be cleared by send of the START
      --  --  condition).
      --
      --  Self.Peripheral.CR1.TCIE := True;
      --  --  Enable TC and TCE interrupts.
      --
      --  --  Send STOP condition.
      --
      --  Self.Peripheral.CR2.STOP := True;
      --
      --  --  declare
      --  --     Val : A0B.SVD.STM32H723.I2C.CR2_Register := Self.Peripheral.CR2;
      --  --
      --  --  begin
      --  --     Val.RD_WRN  := True;           --  Master requests a read transfer.
      --  --     Val.NBYTES  := Buffer'Length;  --  Number of bytes to be transfered.
      --  --
      --  --     Val.AUTOEND := False;
      --  --     Val.RELOAD  := False;
      --  --     Val.START   := True;
      --  --     --  Val.RELOAD  := True;
      --  --     --  Val.START   := Self.State /= Read;
      --  --     --  if Self.State /= Read then
      --  --
      --  --     --
      --  --     --     --  Send (Re)START condition
      --  --     --
      --  --     --     Val.START := True;
      --  --     --  end if;
      --  --
      --  --     Self.Peripheral.CR2 := Val;
      --  --  end;
      --
      --  A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Event_Interrupt);
      --  A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Event_Interrupt);
      --  --  Clear pending interrupt status and enable interrupt.
      --
      --  --  null;
      raise Program_Error;
   end Stop;

   -----------
   -- Start --
   -----------

   overriding procedure Start
     (Self    : in out Master_Controller;
      Device  : not null I2C_Device_Driver_Access;
      Success : in out Boolean) is
   begin
      Device_Locks.Acquire (Self.Device_Lock, Device, Success);

      if not Success then
         return;
      end if;

      Self.Configure_Target_Address;
   end Start;

   -------------------
   -- Store_From_RX --
   -------------------

   procedure Store_From_RX (Self : in out Master_Controller'Class) is
      use type A0B.Types.Unsigned_32;
      use type System.Address;
      use type System.Storage_Elements.Storage_Offset;

   begin
      if Self.Address = System.Null_Address then
         --  Start of the transfer

         Self.Address := Self.Buffers (Self.Active).Address;
      end if;

      loop
         exit when
           Self.Buffers (Self.Active).Size
             /= Self.Buffers (Self.Active).Transferred;

         Self.Active  := @ + 1;
         Self.Address := Self.Buffers (Self.Active).Address;
      end loop;

      declare
         Data : A0B.Types.Unsigned_8
           with Import, Address => Self.Address;

      begin
         Data := Self.Peripheral.RXDR.RXDATA;

         Self.Address                           := @ + 1;
         Self.Buffers (Self.Active).Transferred := @ + 1;
      end;
   end Store_From_RX;

   -----------
   -- Write --
   -----------

   overriding procedure Write
     (Self    : in out Master_Controller;
      Device  : not null I2C_Device_Driver_Access;
      Buffers : in out Buffer_Descriptor_Array;
      Stop    : Boolean;
      Success : in out Boolean)
   is
      use type A0B.Types.Unsigned_32;

      Size : A0B.Types.Unsigned_32 := 0;

   begin
      Device_Locks.Acquire (Self.Device_Lock, Device, Success);

      if not Success then
         return;
      end if;

      for Buffer of Buffers loop
         Size := @ + Buffer.Size;

         Buffer.Transferred  := 0;
         Buffer.State        := Active;
         Buffer.Acknowledged := False;
      end loop;

      Self.Buffers := Buffers'Unrestricted_Access;
      Self.Active  := 0;
      Self.Address := System.Null_Address;
      Self.Stop    := Stop;

      Self.Configure_Target_Address;

      --  A0B.ARMv7M.NVIC_Utilities.Disable_Interrupt (Self.Event_Interrupt);
      --  --  Disable event interrup from the peripheral controller to prevent
      --  --  undesired TC interrupt (it will be cleared by send of the START
      --  --  condition).

      --  Apply workaround.
      --
      --  [ES0491] 2.16.4 Transmission stalled after first byte transfer
      --
      --  "Write the first data in I2C_TXDR before the transmission
      --  starts."

      if Size /= 0 then
         Self.Load_Into_TX;
      end if;

      --  Set transfer parameters and send (Re)START condition.

      declare
         Val : A0B.STM32H723.SVD.I2C.CR2_Register := Self.Peripheral.CR2;

      begin
         Val.RD_WRN  := False;  --  Master requests a write transfer.
         Val.NBYTES  := A0B.Types.Unsigned_8 (Size);
         --  Number of bytes to be transfered.

         Val.AUTOEND := False;
         Val.RELOAD  := False;
         Val.START   := True;

         Self.Peripheral.CR2 := Val;
      end;

      Self.Peripheral.CR1.TCIE := True;
      --  Enable TC and TCE interrupts.

      --  A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Event_Interrupt);
      --  A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Event_Interrupt);
      --  --  Clear pending interrupt status and enable interrupt.
   end Write;

end A0B.I2C.STM32H723_I2C;
