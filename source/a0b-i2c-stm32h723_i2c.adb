--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);
pragma Ada_2022;

--  with Ada.Unchecked_Conversion;
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

   ------------------------------
   -- Configure_Target_Address --
   ------------------------------

   procedure Configure_Target_Address
     (Self : in out Master_Controller'Class)
   is
      Target_Address : constant Device_Address :=
        Device_Locks.Device (Self.Device_Lock).Target_Address;

   begin
      if Self.State = Unused then
         --  Set device address and addressing mode to do its only once.

         declare
            Val : A0B.SVD.STM32H723.I2C.CR2_Register := Self.Peripheral.CR2;

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
               Val.SADD.Val :=
                 A0B.Types.Unsigned_10 (Target_Address);
                 --    (A0B.Types.Shift_Left
                 --       (A0B.Types.Unsigned_8 (Device.Address), 1));
               --  In 7-bit addressing mode device address should be written to
               --  SADD[7:1], so shift it left by one bit.
            end if;

            Self.Peripheral.CR2 := Val;
         end;

         Self.State := Configured;
      end if;
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
         Val : A0B.SVD.STM32H723.I2C.CR1_Register := Self.Peripheral.CR1;

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
         Val : A0B.SVD.STM32H723.I2C.TIMINGR_Register :=
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
              (Abstract_I2C_Slave_Driver'Class);

      -------------
      -- Acquire --
      -------------

      procedure Acquire
        (Self    : in out Lock;
         Device  : not null I2C_Slave_Driver_Access;
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
         Device  : not null I2C_Slave_Driver_Access;
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

      use type A0B.Types.Unsigned_32;

      --  function Pending_Interrupts
      --    (Status : A0B.SVD.STM32H723.I2C.ISR_Register;
      --     Mask   : A0B.SVD.STM32H723.I2C.CR1_Register)
      --     return A0B.SVD.STM32H723.I2C.ISR_Register;
      --
      --  ------------------------
      --  -- Pending_Interrupts --
      --  ------------------------
      --
      --  function Pending_Interrupts
      --    (Status : A0B.SVD.STM32H723.I2C.ISR_Register;
      --     Mask   : A0B.SVD.STM32H723.I2C.CR1_Register)
      --     return A0B.SVD.STM32H723.I2C.ISR_Register
      --  is
      --     function To_Unsigned_32 is
      --       new Ada.Unchecked_Conversion
      --             (A0B.SVD.STM32H723.I2C.ISR_Register, A0B.Types.Unsigned_32);
      --
      --     function To_Unsigned_32 is
      --       new Ada.Unchecked_Conversion
      --             (A0B.SVD.STM32H723.I2C.CR1_Register, A0B.Types.Unsigned_32);
      --
      --     function To_ISR_Register is
      --       new Ada.Unchecked_Conversion
      --         (A0B.Types.Unsigned_32, A0B.SVD.STM32H723.I2C.ISR_Register);
      --
      --  begin
      --     return
      --       To_ISR_Register
      --         (To_Unsigned_32 (Status) and To_Unsigned_32 (Mask));
      --  end Pending_Interrupts;

      Status  : constant A0B.SVD.STM32H723.I2C.ISR_Register :=
        Self.Peripheral.ISR;
      Mask    : constant A0B.SVD.STM32H723.I2C.CR1_Register :=
        Self.Peripheral.CR1;
      --  Pending : constant A0B.SVD.STM32H723.I2C.ISR_Register :=
      --    Pending_Interrupts (Status, Mask);

   begin
      --  if Status.TXIS and Mask.TXIE then
      --  if Status.TXIS and not Self.Peripheral.CR2.RD_WRN then
      if Status.TXIS then
         --  raise Program_Error;
         Self.Peripheral.TXDR.TXDATA := Self.Buffer (Self.Status.Bytes);
         Self.Status.Bytes           := @ + 1;
      end if;

      if Status.RXNE then
         Self.Buffer (Self.Status.Bytes) := Self.Peripheral.RXDR.RXDATA;
         Self.Status.Bytes               := @ + 1;
      end if;

      if Status.TC and Mask.TCIE then
         Self.Peripheral.CR1.TCIE := False;
         --  Disable TCR and TC interrupts, software should write to NBYTES
         --  to clear this flag. It will be re-enabled after this write by
         --  Write/Read procedure.

         --  --  Disable TC interrupt, it is active till master sends START/STOP
         --  --  condition. Device driver need to be notified only once, and
         --  --  there is nothing to do till ball is on device driver's side.
         --  --
         --  --  This supports case when driver can't release controller or
         --  --  initiate next transfer immidiately.

         --  raise Program_Error;
         Self.Status.State := Success;
         Device_Locks.Device (Self.Device_Lock).On_Transfer_Completed;
      end if;

      if Status.NACKF then
         --  raise Program_Error;
         Self.Peripheral.ICR.NACKCF := True;

         if not Status.TXE then
            --  Byte was not transmitted, decrement counter and flush transmit
            --  data regitser.

            Self.Status.Bytes := @ - 1;
            Self.Peripheral.ISR.TXE := True;
         end if;

         --  Self.Status.State := Success;  --  ???
         Self.Status.State := Failure;  --  ???
         Device_Locks.Device (Self.Device_Lock).On_Transfer_Completed;
   --        Self.Release_Device;
   --        --  Self.Busy := False;
   --        --  raise Program_Error;
      end if;
   --
      if Status.STOPF then
         Self.Peripheral.ICR.STOPCF := True;
         --  Clear STOPF interrupt status

         declare
            Device  : constant I2C_Slave_Driver_Access :=
              Device_Locks.Device (Self.Device_Lock);
            Success : Boolean := True;

         begin
            Device_Locks.Release (Self.Device_Lock, Device, Success);
            Self.State := Unused;

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

   --     --  if Self.Peripheral.ISR.ADDR then
   --     --     raise Program_Error;
   --     --  end if;
   --
--  begin
      --  null;
      --  raise Program_Error;
   end On_Event_Interrupt;

   ----------
   -- Read --
   ----------

   overriding procedure Read
     (Self    : in out Master_Controller;
      Device  : not null I2C_Slave_Driver_Access;
      Buffer  : out Unsigned_8_Array;
      Status  : aliased out Transfer_Status;
      Stop    : Boolean;
      Success : in out Boolean) is
   begin
      Device_Locks.Acquire (Self.Device_Lock, Device, Success);

      Self.Configure_Target_Address;

      Self.Buffer :=
        (if Buffer'Length = 0 then null else Buffer'Unrestricted_Access);
      Self.Status := Status'Unchecked_Access;
      Self.State  := Read;

      Self.Status.all := (Bytes => 0, State => Active);

      A0B.ARMv7M.NVIC_Utilities.Disable_Interrupt (Self.Event_Interrupt);
      --  Disable event interrup from the peripheral controller to prevent
      --  undesired TC interrupt (it will be cleared by send of the START
      --  condition).

      Self.Peripheral.CR1.TCIE := True;
      --  Enable TC and TCE interrupts.

      --  Set transfer parameters and send (Re)START condition.

      declare
         Val : A0B.SVD.STM32H723.I2C.CR2_Register := Self.Peripheral.CR2;

      begin
         Val.RD_WRN  := True;           --  Master requests a read transfer.
         Val.NBYTES  := Buffer'Length;  --  Number of bytes to be transfered.

         Val.AUTOEND := False;
         Val.RELOAD  := False;
         Val.START   := True;
         --  Val.RELOAD  := True;
         --  Val.START   := Self.State /= Read;
         --  if Self.State /= Read then

         --
         --     --  Send (Re)START condition
         --
         --     Val.START := True;
         --  end if;

         Self.Peripheral.CR2 := Val;
      end;

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Event_Interrupt);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Event_Interrupt);
      --  Clear pending interrupt status and enable interrupt.

      --  Self.Peripheral.CR1.TCIE := True;

      --  Self.Transfer :=
      --    (Operation => Read,
      --     Buffer    => Self.Read_Buffer,
      --     Index     => 0);
      --
      --  --  Self.Controller.Peripheral.CR1.TCIE := True;
      --
      --  --  Prepare to read and send ReSTART condition
      --
      --  declare
      --     Val : A0B.SVD.STM32H723.I2C.CR2_Register :=
      --       Self.Controller.Peripheral.CR2;
      --
      --  begin
      --     Val.RD_WRN  := True;  --  Master requests a read transfer.
      --     Val.NBYTES  := Self.Transfer.Buffer'Length;
      --
      --     Val.AUTOEND := False;
      --     Val.RELOAD  := False;
      --
      --     Val.START   := True;
      --
      --     Self.Controller.Peripheral.CR2 := Val;
      --  end;
      --
      --  Self.Controller.Peripheral.CR1.TCIE := True;
   end Read;

   ----------
   -- Stop --
   ----------

   overriding procedure Stop
     (Self    : in out Master_Controller;
      Device  : not null I2C_Slave_Driver_Access;
      Success : in out Boolean) is
   begin

      A0B.ARMv7M.NVIC_Utilities.Disable_Interrupt (Self.Event_Interrupt);
      --  Disable event interrup from the peripheral controller to prevent
      --  undesired TC interrupt (it will be cleared by send of the START
      --  condition).

      Self.Peripheral.CR1.TCIE := True;
      --  Enable TC and TCE interrupts.

      --  Send STOP condition.

      Self.Peripheral.CR2.STOP := True;

      --  declare
      --     Val : A0B.SVD.STM32H723.I2C.CR2_Register := Self.Peripheral.CR2;
      --
      --  begin
      --     Val.RD_WRN  := True;           --  Master requests a read transfer.
      --     Val.NBYTES  := Buffer'Length;  --  Number of bytes to be transfered.
      --
      --     Val.AUTOEND := False;
      --     Val.RELOAD  := False;
      --     Val.START   := True;
      --     --  Val.RELOAD  := True;
      --     --  Val.START   := Self.State /= Read;
      --     --  if Self.State /= Read then
      --
      --     --
      --     --     --  Send (Re)START condition
      --     --
      --     --     Val.START := True;
      --     --  end if;
      --
      --     Self.Peripheral.CR2 := Val;
      --  end;

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Event_Interrupt);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Event_Interrupt);
      --  Clear pending interrupt status and enable interrupt.

      --  null;
      --  raise Program_Error;
   end Stop;

   -----------
   -- Start --
   -----------

   overriding procedure Start
     (Self    : in out Master_Controller;
      Device  : not null I2C_Slave_Driver_Access;
      Success : in out Boolean) is
   begin
      Device_Locks.Acquire (Self.Device_Lock, Device, Success);

      if not Success then
         return;
      end if;

      Self.Configure_Target_Address;
   end Start;

   -----------
   -- Write --
   -----------

   overriding procedure Write
     (Self    : in out Master_Controller;
      Device  : not null I2C_Slave_Driver_Access;
      Buffer  : Unsigned_8_Array;
      Status  : aliased out Transfer_Status;
      Stop    : Boolean;
      Success : in out Boolean)
   is
      use type A0B.Types.Unsigned_32;

   begin
      Device_Locks.Acquire (Self.Device_Lock, Device, Success);

      Self.Configure_Target_Address;

      Self.Buffer :=
        (if Buffer'Length = 0 then null else Buffer'Unrestricted_Access);
      Self.Status := Status'Unchecked_Access;

      Self.Status.all := (Bytes => 0, State => Active);
      Self.State := Write;

      --  Self.Write_Buffer :=
      --    (if Write_Buffer'Length = 0
      --     then null
      --     else Write_Buffer'Unrestricted_Access);
      --  Self.Read_Buffer  := null;
      --  Self.Done         := Done;
      --  Self.Busy         := True;
      --
      --  Self.Transfer :=
      --    (Operation => Write,
      --     Buffer    => Self.Write_Buffer,
      --     Index     => 0);

      A0B.ARMv7M.NVIC_Utilities.Disable_Interrupt (Self.Event_Interrupt);
      --  Disable event interrup from the peripheral controller to prevent
      --  undesired TC interrupt (it will be cleared by send of the START
      --  condition).

      Self.Peripheral.CR1.TCIE := True;
      --  Enable TC and TCE interrupts.

      --  Apply workaround.
      --
      --  [ES0491] 2.16.4 Transmission stalled after first byte transfer
      --
      --  "Write the first data in I2C_TXDR before the transmission
      --  starts."

      if Self.Buffer /= null then
         Self.Peripheral.TXDR.TXDATA := Self.Buffer (Self.Status.Bytes);
         Self.Status.Bytes := @ + 1;
      end if;

      --  Set transfer parameters and send (Re)START condition.

      declare
         Val : A0B.SVD.STM32H723.I2C.CR2_Register := Self.Peripheral.CR2;

      begin
         Val.RD_WRN  := False;          --  Master requests a write transfer.
         Val.NBYTES  := Buffer'Length;  --  Number of bytes to be transfered.

         Val.AUTOEND := False;
         Val.RELOAD  := False;
         Val.START   := True;

         Self.Peripheral.CR2 := Val;
      end;

      --  if Self.State /= Write then
      --  end if;

      --  Self.Peripheral.CR2.START := True;
      --  --  Send (Re)START condition

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (Self.Event_Interrupt);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (Self.Event_Interrupt);
      --  Clear pending interrupt status and enable interrupt.

      --  Self.Peripheral.CR1.TCIE := True;
      --  --  Wait till done
      --
      --  while Self.Busy loop
      --     null;
      --  end loop;
      --  --  while Self.Controller.Peripheral.ISR.BUSY loop
      --  --     null;
      --  --  end loop;
      null;
      --  raise Program_Error;
   end Write;

end A0B.I2C.STM32H723_I2C;
