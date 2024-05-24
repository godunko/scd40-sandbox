--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with System.Address_To_Access_Conversions;

with A0B.ARMv7M.NVIC_Utilities;
with A0B.Callbacks.Generic_Non_Dispatching;
with A0B.Time;

package body SCD40_Sandbox.I2C is

   procedure On_Transfer_Delay (Self : in out I2C_Slave_Device'Class);

   package On_Transfer_Delay_Callbacks is
     new A0B.Callbacks.Generic_Non_Dispatching
           (I2C_Slave_Device, On_Transfer_Delay);

   ---------------
   -- Configure --
   ---------------

   procedure Configure (Self : in out I2C_Controller'Class) is
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
         Val.ERRIE     := False;    --  Error interrupt disabled
         Val.TCIE      := True;     --  Transfer Complete interrupt enabled
         Val.STOPIE    := True;
         --  Stop detection (STOPF) interrupt enabled
         Val.NACKIE    := True;
         --  Not acknowledge (NACKF) received interrupts disabled
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
         Val.PRESC  := 0;
         Val.SCLDEL := 16#C#;
         Val.SDADEL := 0;
         Val.SCLH   := 16#45#;
         Val.SCLL   := 16#ED#;

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

   ------------------------
   -- On_Event_Interrupt --
   ------------------------

   procedure On_Event_Interrupt (Self : in out I2C_Controller'Class) is
      use type A0B.Types.Unsigned_32;

      Status : constant A0B.SVD.STM32H723.I2C.ISR_Register :=
        Self.Peripheral.ISR;
      Mask   : constant A0B.SVD.STM32H723.I2C.CR1_Register :=
        Self.Peripheral.CR1;

   begin
      if Status.TXIS then
         Self.Peripheral.TXDR.TXDATA :=
           Self.Device.Transfer.Buffer (Self.Device.Transfer.Index);
         Self.Device.Transfer.Index := @ + 1;
      end if;

      if Status.RXNE then
         Self.Device.Transfer.Buffer (Self.Device.Transfer.Index) :=
           Self.Peripheral.RXDR.RXDATA;
         Self.Device.Transfer.Index := @ + 1;
      end if;

      if Status.TC and Mask.TCIE then
         Self.Peripheral.CR1.TCIE := False;
         --  Disable TC interrupt, it is active till master sends START/STOP
         --  condition. Device driver need to be notified only once, and
         --  there is nothing to do till ball is on device driver's side.
         --
         --  This supports case when driver can't release controller or
         --  initiate next transfer immidiately.

         Self.Device.On_Transfer_Complete;
      end if;

      -----------------------------------------------------------------------

      if Status.TCR then
         raise Program_Error;
      end if;

      if Status.STOPF then
         declare
            Device : constant I2C_Slave_Device_Access := Self.Device;

         begin
            Self.Peripheral.ICR.STOPCF := True;
            Self.Device := null;
            Device.On_Transaction_Complete;
         end;
      end if;

      if Status.NACKF then
         Self.Peripheral.ICR.NACKCF := True;

         raise Program_Error;
      end if;

      --  if Self.Peripheral.ISR.ADDR then
      --     raise Program_Error;
      --  end if;

   end On_Event_Interrupt;

   ------------------------
   -- On_Error_Interrupt --
   ------------------------

   procedure On_Error_Interrupt (Self : in out I2C_Controller'Class) is
   begin
      null;
   end On_Error_Interrupt;

   -----------------------------
   -- On_Transaction_Complete --
   -----------------------------

   procedure On_Transaction_Complete (Self : in out I2C_Slave_Device'Class) is
      Callback : constant A0B.Callbacks.Callback := Self.Done;

   begin
      Self.Busy := False;
      A0B.Callbacks.Unset (Self.Done);
      A0B.Callbacks.Emit (Callback);
   end On_Transaction_Complete;

   --------------------------
   -- On_Transfer_Complete --
   --------------------------

   procedure On_Transfer_Complete (Self : in out I2C_Slave_Device'Class) is
   begin
      if Self.Read_Buffer = null then
         Self.Controller.Release_Device;
         --  Self.Busy := False;

         return;
      end if;

      if Self.Transfer.Operation = Read then
         Self.Controller.Release_Device;
         --  Self.Busy := False;

         return;
      end if;

      A0B.Timer.Enqueue
        (Self.Timeout,
         On_Transfer_Delay_Callbacks.Create_Callback (Self),
         A0B.Time.Microseconds (2));
   end On_Transfer_Complete;

   -----------------------
   -- On_Transfer_Delay --
   -----------------------

   procedure On_Transfer_Delay (Self : in out I2C_Slave_Device'Class) is
   begin
      Self.Transfer :=
        (Operation => Read,
         Buffer    => Self.Read_Buffer,
         Index     => 0);

      --  Self.Controller.Peripheral.CR1.TCIE := True;

      --  Prepare to read and send ReSTART condition

      declare
         Val : A0B.SVD.STM32H723.I2C.CR2_Register :=
           Self.Controller.Peripheral.CR2;

      begin
         Val.RD_WRN  := True;  --  Master requests a read transfer.
         Val.NBYTES  := Self.Transfer.Buffer'Length;

         Val.AUTOEND := False;
         Val.RELOAD  := False;

         Val.START   := True;

         Self.Controller.Peripheral.CR2 := Val;
      end;

      Self.Controller.Peripheral.CR1.TCIE := True;
   end On_Transfer_Delay;

   --------------------
   -- Release_Device --
   --------------------

   procedure Release_Device (Self : in out I2C_Controller'Class) is
   begin
      --  Send STOP condition

      Self.Peripheral.CR2.STOP := True;
      Self.Peripheral.CR1.TCIE := True;
   end Release_Device;

   -------------------
   -- Select_Device --
   -------------------

   procedure Select_Device
     (Self    : in out I2C_Controller'Class;
      Device  : aliased in out I2C_Slave_Device'Class;
      Success : in out Boolean)
   is
      package Conversions is
        new System.Address_To_Access_Conversions (I2C_Slave_Device'Class);

      Aux : System.Storage_Elements.Integer_Address :=
        System.Storage_Elements.To_Integer (System.Null_Address);

   begin
      if not Success then
         return;
      end if;

      if Self.Device /= null
        and then Self.Device = Device'Unchecked_Access
      then
         return;
      end if;

      if not Atomic_Compare_Exchange
        (Ptr      => Self.Device'Address,
         Expected => Aux'Address,
         Desired  =>
           System.Storage_Elements.To_Integer
             (Conversions.To_Address (Device'Unchecked_Access)))
      then
         Success := False;

         return;
      end if;

      --  Set device address and addressing mode to do its only once.

      declare
         Val : A0B.SVD.STM32H723.I2C.CR2_Register := Self.Peripheral.CR2;

      begin
         Val.ADD10    := False;
         Val.SADD.Val :=
           A0B.Types.Unsigned_10
             (A0B.Types.Shift_Left (A0B.Types.Unsigned_8 (Device.Address), 1));
         --  In 7-bit addressing mode device address should be written to
         --  SADD[7:1], so shift it left by one bit.

         Self.Peripheral.CR2 := Val;
      end;
   end Select_Device;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self         : in out I2C_Slave_Device'Class;
      Write_Buffer : Unsigned_8_Array;
      Done         : A0B.Callbacks.Callback;
      Success      : in out Boolean)
   is
      --  use type A0B.Types.Unsigned_8;
      use type A0B.Types.Unsigned_32;

   begin
      Self.Controller.Select_Device (Self, Success);

      if not Success then
         return;
      end if;

      Self.Write_Buffer :=
        (if Write_Buffer'Length = 0
         then null
         else Write_Buffer'Unrestricted_Access);
      Self.Read_Buffer  := null;
      Self.Done         := Done;
      Self.Busy         := True;

      Self.Transfer :=
        (Operation => Write,
         Buffer    => Self.Write_Buffer,
         Index     => 0);

      --  Set transfer parameters.

      declare
         Val : A0B.SVD.STM32H723.I2C.CR2_Register :=
           Self.Controller.Peripheral.CR2;

      begin
         Val.RD_WRN  := False;  --  Master requests a write transfer.
         Val.NBYTES  :=
           (if Self.Transfer.Buffer = null
              then 0 else Self.Transfer.Buffer'Length);
           --  (if Self.Write_Buffer = null
           --     or else Self.Write_Buffer'Length = 1
           --   then 0 else Self.Write_Buffer'Length - 1);

         Val.AUTOEND := False;
         Val.RELOAD  := False;

         Self.Controller.Peripheral.CR2 := Val;
      end;

      --  Apply workaround.
      --
      --  [ES0491] 2.16.4 Transmission stalled after first byte transfer
      --
      --  "Write the first data in I2C_TXDR before the transmission starts."

      if Self.Transfer.Buffer /= null then
         Self.Controller.Peripheral.TXDR.TXDATA :=
           Self.Transfer.Buffer (Self.Transfer.Index);
         Self.Transfer.Index := @ + 1;
      end if;

      --  Send START condition

      Self.Controller.Peripheral.CR2.START := True;
      --  Self.Controller.Peripheral.CR1.TCIE := True;

      --  Wait till done

      while Self.Busy loop
         null;
      end loop;
      --  while Self.Controller.Peripheral.ISR.BUSY loop
      --     null;
      --  end loop;
   end Write;

   -----------
   -- Write --
   -----------

   --  procedure Write
   --    (Peripheral : in out A0B.SVD.STM32H723.I2C.I2C_Peripheral;
   --     Device     : A0B.Types.Unsigned_7;
   --     Write_Data : Unsigned_8_Array)
   --  is
   --     use type A0B.Types.Unsigned_32;
   --
   --     Write_Index : A0B.Types.Unsigned_32 := Write_Data'First;
   --
   --  begin
   --     --  Initiate communication (address phase)
   --
   --     declare
   --        Val : A0B.SVD.STM32H723.I2C.CR2_Register := Peripheral.CR2;
   --
   --     begin
   --        Val.ADD10    := False;
   --        Val.SADD.Val :=
   --          A0B.Types.Unsigned_10
   --            (A0B.Types.Shift_Left (A0B.Types.Unsigned_8 (Device), 1));
   --        --  In 7-bit addressing mode device address should be written to
   --        --  SADD[7:1], so shift it left by one bit.
   --
   --        Val.RD_WRN   := False;  --  Master requests a write transfer.
   --        Val.NBYTES   := Write_Data'Length;
   --
   --        Val.AUTOEND  := True;
   --        Val.RELOAD   := False;
   --
   --        Peripheral.CR2 := Val;
   --     end;
   --
   --     --  Apply workaround.
   --     --
   --     --  [ES0491] 2.16.4 Transmission stalled after first byte transfer
   --     --
   --     --  "Write the first data in I2C_TXDR before the transmission
   --  starts."
   --
   --     if Write_Data'Length /= 0 then
   --        Peripheral.TXDR.TXDATA := Write_Data (Write_Index);
   --        Write_Index            := @ + 1;
   --     end if;
   --
   --     --  Send START condition
   --
   --     Peripheral.CR2.START := True;
   --
   --     --  Transmit data
   --
   --     while Write_Index <= Write_Data'Last loop
   --        while not Peripheral.ISR.TXIS loop
   --           null;
   --        end loop;
   --
   --        Peripheral.TXDR.TXDATA := Write_Data (Write_Index);
   --        Write_Index := @ + 1;
   --     end loop;
   --  end Write;

   ----------------
   -- Write_Read --
   ----------------

   procedure Write_Read
     (Self         : in out I2C_Slave_Device'Class;
      Write_Buffer : Unsigned_8_Array;
      Read_Buffer  : out Unsigned_8_Array;
      Done         : A0B.Callbacks.Callback;
      Success      : in out Boolean)
   is
      --  use type A0B.Types.Unsigned_8;
      use type A0B.Types.Unsigned_32;

   begin
      Self.Controller.Select_Device (Self, Success);

      if not Success then
         return;
      end if;

      Self.Write_Buffer :=
        (if Write_Buffer'Length = 0
           then null else Write_Buffer'Unrestricted_Access);
      Self.Read_Buffer  :=
        (if Read_Buffer'Length = 0
           then null else Read_Buffer'Unrestricted_Access);
      Self.Done         := Done;
      Self.Busy         := True;

      Self.Transfer :=
        (Operation => Write,
         Buffer    => Self.Write_Buffer,
         Index     => 0);

      --  Set transfer parameters.

      declare
         Val : A0B.SVD.STM32H723.I2C.CR2_Register :=
           Self.Controller.Peripheral.CR2;

      begin
         Val.RD_WRN  := False;  --  Master requests a write transfer.
         Val.NBYTES  :=
           (if Self.Transfer.Buffer = null
              then 0 else Self.Transfer.Buffer'Length);
           --  (if Self.Write_Buffer = null
           --     or else Self.Write_Buffer'Length = 1
           --   then 0 else Self.Write_Buffer'Length - 1);

         Val.AUTOEND := False;
         Val.RELOAD  := False;

         Self.Controller.Peripheral.CR2 := Val;
      end;

      --  Apply workaround.
      --
      --  [ES0491] 2.16.4 Transmission stalled after first byte transfer
      --
      --  "Write the first data in I2C_TXDR before the transmission starts."

      if Self.Transfer.Buffer /= null then
         Self.Controller.Peripheral.TXDR.TXDATA :=
           Self.Transfer.Buffer (Self.Transfer.Index);
         Self.Transfer.Index := @ + 1;
      end if;

      --  Send START condition

      Self.Controller.Peripheral.CR2.START := True;
      --  Self.Controller.Peripheral.CR1.TCIE := True;

      --  Wait till done

      while Self.Busy loop
         null;
      end loop;
      --  for J in 1 .. 100_000 loop
      --     null;
      --  end loop;
      --
      --  while Self.Controller.Peripheral.ISR.BUSY loop
      --     null;
      --  end loop;
   end Write_Read;

   ----------------
   -- Write_Read --
   ----------------

   --  procedure Write_Read
   --    (Peripheral : in out A0B.SVD.STM32H723.I2C.I2C_Peripheral;
   --     Device     : A0B.Types.Unsigned_7;
   --     Write_Data : Unsigned_8_Array;
   --     Read_Data  : out Unsigned_8_Array)
   --  is
   --     use type A0B.Types.Unsigned_32;
   --
   --     Write_Index : A0B.Types.Unsigned_32 := Write_Data'First;
   --     Read_Index  : A0B.Types.Unsigned_32 := Read_Data'First;
   --
   --  begin
   --     --  Initiate communication (address phase)
   --
   --     declare
   --        Val : A0B.SVD.STM32H723.I2C.CR2_Register := Peripheral.CR2;
   --
   --     begin
   --        Val.ADD10    := False;
   --        Val.SADD.Val :=
   --          A0B.Types.Unsigned_10
   --            (A0B.Types.Shift_Left (A0B.Types.Unsigned_8 (Device), 1));
   --        --  In 7-bit addressing mode device address should be written to
   --        --  SADD[7:1], so shift it left by one bit.
   --
   --        Val.RD_WRN   := False;  --  Master requests a write transfer.
   --        Val.NBYTES   := Write_Data'Length;
   --
   --        Val.AUTOEND  := False;
   --        Val.RELOAD   := False;
   --
   --        Peripheral.CR2 := Val;
   --     end;
   --
   --     --  Apply workaround.
   --     --
   --     --  [ES0491] 2.16.4 Transmission stalled after first byte transfer
   --     --
   --     --  "Write the first data in I2C_TXDR before the transmission
   --  starts."
   --
   --     if Write_Data'Length /= 0 then
   --        Peripheral.TXDR.TXDATA := Write_Data (Write_Index);
   --        Write_Index            := @ + 1;
   --     end if;
   --
   --     --  Send START condition
   --
   --     Peripheral.CR2.START := True;
   --
   --     --  Transmit data
   --
   --     while Write_Index <= Write_Data'Last loop
   --        while not Peripheral.ISR.TXIS loop
   --           null;
   --        end loop;
   --
   --        Peripheral.TXDR.TXDATA := Write_Data (Write_Index);
   --        Write_Index := @ + 1;
   --     end loop;
   --
   --     --  Wait till end of the trasfer
   --
   --     while not Peripheral.ISR.TC loop
   --        null;
   --     end loop;
   --
   --     for J in 0 .. 500_000 loop
   --        null;
   --     end loop;
   --
   --     --  Prepare to read and send ReSTART condition
   --
   --     declare
   --        Val : A0B.SVD.STM32H723.I2C.CR2_Register := Peripheral.CR2;
   --
   --     begin
   --        Val.RD_WRN  := True;  --  Master requests a write transfer.
   --        Val.NBYTES  := Read_Data'Length;
   --
   --        Val.AUTOEND := True;
   --        Val.RELOAD  := False;
   --
   --        Val.START   := True;
   --
   --        Peripheral.CR2 := Val;
   --     end;
   --
   --     --  Receive data
   --
   --     while Read_Index <= Read_Data'Last loop
   --        while not Peripheral.ISR.RXNE loop
   --           null;
   --        end loop;
   --
   --        Read_Data (Read_Index) := Peripheral.RXDR.RXDATA;
   --        Read_Index := @ + 1;
   --     end loop;
   --  end Write_Read;

end SCD40_Sandbox.I2C;
