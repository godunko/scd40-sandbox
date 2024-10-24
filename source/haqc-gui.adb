--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Real_Time;

with A0B.Awaits;
--  with A0B.Callbacks;
with A0B.ILI9488;
with A0B.ARMv7M.Profiling_Utilities;
with A0B.SPI;
--  with A0B.Time.Clock;
with A0B.Tasking;
with A0B.Types.Arrays;

with GFX.Framebuffers;
with GFX.Rasteriser.Bitmap_Fonts;

with HAQC.Configuration.Board;
--  with HAQC.Configuration.Sensors;
with SCD40_Sandbox.Fonts.DejaVuSansCondensed_32;

package body HAQC.GUI is

   --  SCD40_Sensor : A0B.I2C.SCD40.SCD40_Driver
   --    (Controller => HAQC.Configuration.Board.I2C'Access,
   --     Address    => HAQC.Configuration.Sensors.SCD40_I2C_Address);

   TCB : aliased A0B.Tasking.Task_Control_Block;

   procedure Task_Subprogram;

   --  package Console is
   --
   --     --  procedure Put (Item : Character);
   --
   --     procedure Put (Item : String);
   --
   --     procedure Put_Line (Item : String);
   --
   --     procedure New_Line;
   --
   --  end Console;
   --
   --  procedure Delay_For (T : A0B.Time.Time_Span);
   --
   --  CO2 : A0B.Types.Unsigned_16 := 0 with Volatile;
   --  T   : A0B.Types.Unsigned_16 := 0 with Volatile;
   --  RH  : A0B.Types.Unsigned_16 := 0 with Volatile;
   --
   --  -------------
   --  -- Console --
   --  -------------
   --
   --  package body Console is
   --
   --     --------------
   --     -- New_Line --
   --     --------------
   --
   --     procedure New_Line is
   --     begin
   --        Put (ASCII.CR & ASCII.LF);
   --     end New_Line;
   --
   --     ---------
   --     -- Put --
   --     ---------
   --
   --     --  procedure Put (Item : Character) is
   --     --     Buffer : String (1 .. 1);
   --     --
   --     --  begin
   --     --     Buffer (Buffer'First) := Item;
   --     --     Put (Buffer);
   --     --  end Put;
   --
   --     ---------
   --     -- Put --
   --     ---------
   --
   --     procedure Put (Item : String) is
   --        Buffers : A0B.STM32F401.USART.Buffer_Descriptor_Array (0 .. 0);
   --        Await   : aliased A0B.Awaits.Await;
   --        Success : Boolean := True;
   --
   --     begin
   --        Buffers (0) :=
   --          (Address     => Item (Item'First)'Address,
   --           Size        => Item'Length,
   --           Transferred => <>,
   --           State       => <>);
   --
   --        HAQC.Configuration.Board.UART.Transmit
   --          (Buffers  => Buffers,
   --           Finished => A0B.Awaits.Create_Callback (Await),
   --           Success  => Success);
   --
   --        A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --     end Put;
   --
   --     --------------
   --     -- Put_Line --
   --     --------------
   --
   --     procedure Put_Line (Item : String) is
   --     begin
   --        Put (Item);
   --        New_Line;
   --     end Put_Line;
   --
   --  end Console;
   --
   --  ---------------
   --  -- Delay_For --
   --  ---------------
   --
   --  procedure Delay_For (T : A0B.Time.Time_Span) is
   --     use type A0B.Time.Time_Span;
   --
   --  begin
   --     A0B.Tasking.Delay_Until (A0B.Time.Clock + T);
   --  end Delay_For;

   -------------------
   -- Register_Task --
   -------------------

   procedure Register_Task is
   begin
      A0B.Tasking.Register_Thread (TCB, Task_Subprogram'Access, 16#400#);
   end Register_Task;

   --  --------------------------
   --  -- Set_Ambient_Pressure --
   --  --------------------------
   --
   --  --  procedure Set_Ambient_Pressure (To : A0B.Types.Unsigned_32) is
   --  --     Input   : A0B.SCD40.Set_Ambient_Pressure_Input;
   --  --     Status  : aliased A0B.I2C.SCD40.Transaction_Status;
   --  --     Await   : aliased A0B.Awaits.Await;
   --  --     Success : Boolean := True;
   --  --
   --  --  begin
   --  --     A0B.SCD40.Build_Set_Ambient_Pressure_Input (Input, To);
   --  --
   --  --     SCD40_Sensor.Write
   --  --       (A0B.SCD40.Set_Ambient_Pressure,
   --  --        Input,
   --  --        Status,
   --  --        A0B.Awaits.Create_Callback (Await),
   --  --        Success);
   --  --     A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --  --
   --  --     if not Success then
   --  --        raise Program_Error;
   --  --     end if;
   --  --
   --  --     Delay_For (A0B.Time.Milliseconds (1));
   --  --  end Set_Ambient_Pressure;
   --
   --  -------------------------
   --  -- Set_Sensor_Altitude --
   --  -------------------------
   --
   --  procedure Set_Sensor_Altitude (To : A0B.Types.Unsigned_16) is
   --     Input   : A0B.SCD40.Set_Sensor_Altitude_Input;
   --     Status  : aliased A0B.I2C.SCD40.Transaction_Status;
   --     Await   : aliased A0B.Awaits.Await;
   --     Success : Boolean := True;
   --
   --  begin
   --     A0B.SCD40.Build_Set_Sensor_Altitude_Input (Input, To);
   --
   --     SCD40_Sensor.Write
   --       (A0B.SCD40.Set_Sensor_Altitude,
   --        Input,
   --        Status,
   --        A0B.Awaits.Create_Callback (Await),
   --        Success);
   --     A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --
   --     Delay_For (A0B.Time.Milliseconds (1));
   --  end Set_Sensor_Altitude;
   --
   --  --------------------------------
   --  -- Start_Periodic_Measurement --
   --  --------------------------------
   --
   --  procedure Start_Periodic_Measurement is
   --     Status  : aliased A0B.I2C.SCD40.Transaction_Status;
   --     Await   : aliased A0B.Awaits.Await;
   --     Success : Boolean := True;
   --
   --  begin
   --     SCD40_Sensor.Send_Command
   --       (A0B.SCD40.Start_Periodic_Measurement,
   --        Status,
   --        A0B.Awaits.Create_Callback (Await),
   --        Success);
   --     A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --
   --     Delay_For (A0B.Time.Milliseconds (1));
   --  end Start_Periodic_Measurement;
   --
   --  -------------------------------
   --  -- Stop_Periodic_Measurement --
   --  -------------------------------
   --
   --  procedure Stop_Periodic_Measurement (Success : in out Boolean) is
   --     Status : aliased A0B.I2C.SCD40.Transaction_Status;
   --     Await  : aliased A0B.Awaits.Await;
   --
   --  begin
   --     if not Success then
   --        return;
   --     end if;
   --
   --     SCD40_Sensor.Send_Command
   --       (A0B.SCD40.Stop_Periodic_Measurement,
   --        Status,
   --        A0B.Awaits.Create_Callback (Await),
   --        Success);
   --     A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --     Delay_For (A0B.Time.Milliseconds (500));
   --  end Stop_Periodic_Measurement;

   --  use type A0B.Types.Unsigned_32;

   Await            : aliased A0B.Awaits.Await;
   Command_Buffer   : A0B.Types.Arrays.Unsigned_8_Array (0 .. 0);
   Parameter_Buffer : A0B.Types.Arrays.Unsigned_8_Array (0 .. 3);
   --  Data_Buffer    : A0B.Types.Arrays.Unsigned_8_Array (0 .. 7) :=
   --    [others => 0];
   --  Color_Buffer   : A0B.Types.Arrays.Unsigned_8_Array (0 .. 2) :=
   --    [16#70#, 16#00#, 16#00#];
   --  Colors_Buffer  : A0B.Types.Arrays.Unsigned_8_Array (0 .. 320 * 3 - 1);
   Buffers        : A0B.SPI.Buffer_Descriptor_Array (0 .. 0);

   procedure Send_Command (Command : A0B.Types.Unsigned_8);

   procedure Send_Command
     (Command   : A0B.Types.Unsigned_8;
      Parameter : A0B.Types.Unsigned_8);

   procedure Send_Command
     (Command     : A0B.Types.Unsigned_8;
      Parameter_1 : A0B.Types.Unsigned_8;
      Parameter_2 : A0B.Types.Unsigned_8;
      Parameter_3 : A0B.Types.Unsigned_8;
      Parameter_4 : A0B.Types.Unsigned_8);

   Cyc_Initiate : A0B.Types.Unsigned_32 with Export;
   Cyc_Transfer : A0B.Types.Unsigned_32 with Export;

   use type GFX.GX_Unsigned;

   FB1 : GFX.Framebuffers.Framebuffer (480 - 1);
   FB2 : GFX.Framebuffers.Framebuffer (480 - 1);

   ------------------
   -- Send_Command --
   ------------------

   procedure Send_Command (Command : A0B.Types.Unsigned_8) is
      Success : Boolean := True;

      From  : A0B.ARMv7M.Profiling_Utilities.Stamp;
      To    : A0B.ARMv7M.Profiling_Utilities.Stamp;
      --  Callback : A0B.Callbacks.Callback;

   begin
      Command_Buffer (0) := Command;

      Buffers (0) :=
        (Address => Command_Buffer'Address,
         Size    => Command_Buffer'Length,
         others  => <>);

      HAQC.Configuration.Board.LCD_DC_Pin.Set (False);

      --  Callback := A0B.Awaits.Create_Callback (Await);

      From := A0B.ARMv7M.Profiling_Utilities.Get;

      HAQC.Configuration.Board.SPI.Transmit
        (Transmit_Buffers => Buffers,
         --  On_Finished      => Callback,
         On_Finished      => A0B.Awaits.Create_Callback (Await),
         Success          => Success);

      To := A0B.ARMv7M.Profiling_Utilities.Get;
      Cyc_Initiate := A0B.ARMv7M.Profiling_Utilities.Cycles (From, To);

      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      To := A0B.ARMv7M.Profiling_Utilities.Get;
      Cyc_Transfer := A0B.ARMv7M.Profiling_Utilities.Cycles (From, To);

      if not Success then
         raise Program_Error;
      end if;

      HAQC.Configuration.Board.SPI.Release_Device;
   end Send_Command;

   ------------------
   -- Send_Command --
   ------------------

   procedure Send_Command
     (Command   : A0B.Types.Unsigned_8;
      Parameter : A0B.Types.Unsigned_8)
   is
      Success : Boolean := True;

   begin
      Command_Buffer (0) := Command;

      Buffers (0) :=
        (Address => Command_Buffer'Address,
         Size    => Command_Buffer'Length,
         others  => <>);

      HAQC.Configuration.Board.LCD_DC_Pin.Set (False);

      HAQC.Configuration.Board.SPI.Transmit
        (Transmit_Buffers => Buffers,
         On_Finished      => A0B.Awaits.Create_Callback (Await),
         Success          => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      if not Success then
         raise Program_Error;
      end if;

      Parameter_Buffer (0) := Parameter;

      Buffers (0) :=
        (Address => Parameter_Buffer'Address,
         Size    => 1,
         others  => <>);

      HAQC.Configuration.Board.LCD_DC_Pin.Set (True);

      HAQC.Configuration.Board.SPI.Transmit
        (Transmit_Buffers => Buffers,
         On_Finished      => A0B.Awaits.Create_Callback (Await),
         Success          => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      if not Success then
         raise Program_Error;
      end if;

      HAQC.Configuration.Board.SPI.Release_Device;
   end Send_Command;

   ------------------
   -- Send_Command --
   ------------------

   procedure Send_Command
     (Command     : A0B.Types.Unsigned_8;
      Parameter_1 : A0B.Types.Unsigned_8;
      Parameter_2 : A0B.Types.Unsigned_8;
      Parameter_3 : A0B.Types.Unsigned_8;
      Parameter_4 : A0B.Types.Unsigned_8)
   is
      Success : Boolean := True;

   begin
      Command_Buffer (0) := Command;

      Buffers (0) :=
        (Address => Command_Buffer'Address,
         Size    => Command_Buffer'Length,
         others  => <>);

      HAQC.Configuration.Board.LCD_DC_Pin.Set (False);

      HAQC.Configuration.Board.SPI.Transmit
        (Transmit_Buffers => Buffers,
         On_Finished      => A0B.Awaits.Create_Callback (Await),
         Success          => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      if not Success then
         raise Program_Error;
      end if;

      Parameter_Buffer (0) := Parameter_1;
      Parameter_Buffer (1) := Parameter_2;
      Parameter_Buffer (2) := Parameter_3;
      Parameter_Buffer (3) := Parameter_4;

      Buffers (0) :=
        (Address => Parameter_Buffer'Address,
         Size    => 4,
         others  => <>);

      HAQC.Configuration.Board.LCD_DC_Pin.Set (True);

      HAQC.Configuration.Board.SPI.Transmit
        (Transmit_Buffers => Buffers,
         On_Finished      => A0B.Awaits.Create_Callback (Await),
         Success          => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      if not Success then
         raise Program_Error;
      end if;

      HAQC.Configuration.Board.SPI.Release_Device;
   end Send_Command;

   ----------------------
   -- Send_Framebuffer --
   ----------------------

   procedure Send_Framebuffer
     (Framebuffer : GFX.Framebuffers.Framebuffer;
      X           : GFX.Rasteriser.Device_Pixel_Index;
      Y           : GFX.Rasteriser.Device_Pixel_Index)
   is
      use type A0B.Types.Unsigned_16;
      use type GFX.GX_Integer;

      SC : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (X);
      EC : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (X + GFX.Framebuffers.Width (Framebuffer) - 1);
      SP : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (Y);
      EP : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (Y + GFX.Framebuffers.Height (Framebuffer) - 1);

      Success : Boolean := True;

   begin
      Send_Command
        (A0B.ILI9488.CASET,
         A0B.Types.Unsigned_8 (SC / 256),
         A0B.Types.Unsigned_8 (SC mod 256),
         A0B.Types.Unsigned_8 (EC / 256),
         A0B.Types.Unsigned_8 (EC mod 256));
      Send_Command
        (A0B.ILI9488.PASET,
         A0B.Types.Unsigned_8 (SP / 256),
         A0B.Types.Unsigned_8 (SP mod 256),
         A0B.Types.Unsigned_8 (EP / 256),
         A0B.Types.Unsigned_8 (EP mod 256));

      --  Send data

      Command_Buffer (0) := A0B.ILI9488.RAMWR;

      Buffers (0) :=
        (Address => Command_Buffer'Address,
         Size    => Command_Buffer'Length,
         others  => <>);

      HAQC.Configuration.Board.LCD_DC_Pin.Set (False);
      HAQC.Configuration.Board.SPI.Transmit
        (Transmit_Buffers => Buffers,
         On_Finished      => A0B.Awaits.Create_Callback (Await),
         Success          => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      if not Success then
         raise Program_Error;
      end if;

      GFX.Framebuffers.Buffer
        (Self    => Framebuffer,
         Address => Buffers (0).Address,
         Size    => GFX.GX_Unsigned (Buffers (0).Size));

      HAQC.Configuration.Board.LCD_DC_Pin.Set (True);
      HAQC.Configuration.Board.SPI.Transmit
        (Transmit_Buffers => Buffers,
         On_Finished      => A0B.Awaits.Create_Callback (Await),
         Success          => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      if not Success then
         raise Program_Error;
      end if;

      HAQC.Configuration.Board.SPI.Release_Device;
   end Send_Framebuffer;

   ---------------------
   -- Task_Subprogram --
   ---------------------

   Cyc_Fill : A0B.Types.Unsigned_32 with Export;

   procedure Task_Subprogram is
      use type Ada.Real_Time.Time;

      From  : A0B.ARMv7M.Profiling_Utilities.Stamp;
      To    : A0B.ARMv7M.Profiling_Utilities.Stamp;
   --     Serial  : A0B.SCD40.Serial_Number;
   --     Success : Boolean := True;
   --

   begin
      GFX.Framebuffers.Configure (FB1, 480, 1);
      GFX.Framebuffers.Configure (FB2, 480, 1);

      GFX.Framebuffers.Clear (FB1);
      GFX.Framebuffers.Clear (FB2);

      A0B.ARMv7M.Profiling_Utilities.Initialize;

      --  for J in 0 ..
      --  A0B.Types.Unsigned_32 (Colors_Buffer'Length / 3) - 1 loop
      --     Colors_Buffer (J * 3 .. J * 3 + 2) :=
      --       [16#F0#, 16#00#, 16#00#];
      --  end loop;

      HAQC.Configuration.Board.LCD_LED_Pin.Set (True);

      HAQC.Configuration.Board.LCD_RESET_Pin.Set (False);
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Microseconds (10);
      HAQC.Configuration.Board.LCD_RESET_Pin.Set (True);
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (120);

      Send_Command (A0B.ILI9488.SLPOUT);
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (120);

      Send_Command (A0B.ILI9488.DISON);
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (120);

      Send_Command (A0B.ILI9488.COLMOD, 2#0110_0110#);  --  18bit
      Send_Command (A0B.ILI9488.MADCTL, 2#1110_0000#);
      --  D7: MY  - Row Address Order
      --  D6: MX  - Column Address Order
      --  D5: MV  - Row/Column Exchange
      --  D4: ML  - Vertical Refresh Order
      --  D3: BGR - RGB-BGR Order
      --  D2: MH  - Horizontal Refresh ORDER

   --     raise Program_Error;
   --     --     Console.New_Line;
   --  --     Console.Put_Line ("Home Air Quality Controller");
   --  --     Console.New_Line;
   --     declare
   --        Success : Boolean := True;
   --
   --     begin
   --        --  Command_Buffer (0) := RDDIDIF;
   --        Command_Buffer (0) := A0B.ILI9488.RDDST;
   --
   --        Buffers (0) :=
   --          (Address => Command_Buffer'Address,
   --           Size    => Command_Buffer'Length,
   --           others  => <>);
   --
   --        HAQC.Configuration.Board.LCD_DC_Pin.Set (False);
   --        HAQC.Configuration.Board.SPI.Transmit
   --          (Transmit_Buffers => Buffers,
   --           On_Finished      => A0B.Awaits.Create_Callback (Await),
   --           Success          => Success);
   --        A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --        if not Success then
   --           raise Program_Error;
   --        end if;
   --
   --        Buffers (0) :=
   --          (Address => Data_Buffer'Address,
   --           Size    => Data_Buffer'Length,
   --           others  => <>);
   --
   --        HAQC.Configuration.Board.LCD_DC_Pin.Set (True);
   --        HAQC.Configuration.Board.SPI.Receive
   --          (Receive_Buffers => Buffers,
   --           On_Finished     => A0B.Awaits.Create_Callback (Await),
   --           Success         => Success);
   --        A0B.Awaits.Suspend_Until_Callback (Await, Success);
   --
   --        if not Success then
   --           raise Program_Error;
   --        end if;
   --
   --        HAQC.Configuration.Board.SPI.Release_Device;
   --     end;

      Send_Command (A0B.ILI9488.CASET, 16#00#, 16#00#, 16#01#, 16#DF#);
      Send_Command (A0B.ILI9488.PASET, 16#00#, 16#00#, 16#01#, 16#3F#);

      From := A0B.ARMv7M.Profiling_Utilities.Get;

      --  declare
      --     Success : Boolean := True;
      --
      --  begin
      --     Command_Buffer (0) := A0B.ILI9488.RAMWR;
      --
      --     Buffers (0) :=
      --       (Address => Command_Buffer'Address,
      --        Size    => Command_Buffer'Length,
      --        others  => <>);
      --
      --     HAQC.Configuration.Board.LCD_DC_Pin.Set (False);
      --     HAQC.Configuration.Board.SPI.Transmit
      --       (Transmit_Buffers => Buffers,
      --        On_Finished      => A0B.Awaits.Create_Callback (Await),
      --        Success          => Success);
      --     A0B.Awaits.Suspend_Until_Callback (Await, Success);
      --
      --     if not Success then
      --        raise Program_Error;
      --     end if;
      --
      --     GFX.Framebuffers.Buffer
      --       (Self    => FB1,
      --        Address => Buffers (0).Address,
      --        Size    => GFX.GX_Unsigned (Buffers (0).Size));
      --
      --     for J in 1 .. 320 loop
      --     --  for J in 1 .. 480 * 320 / (Colors_Buffer'Length / 3) loop
      --        --  Buffers (0) :=
      --        --    (Address => Color_Buffer'Address,
      --        --     Size    => Color_Buffer'Length,
      --        --     others  => <>);
      --        --  Buffers (0) :=
      --        --    (Address => Colors_Buffer'Address,
      --        --     Size    => Colors_Buffer'Length,
      --        --     others  => <>);
      --
      --        HAQC.Configuration.Board.LCD_DC_Pin.Set (True);
      --        HAQC.Configuration.Board.SPI.Transmit
      --          (Transmit_Buffers => Buffers,
      --           On_Finished      => A0B.Awaits.Create_Callback (Await),
      --           Success          => Success);
      --        A0B.Awaits.Suspend_Until_Callback (Await, Success);
      --
      --        if not Success then
      --           raise Program_Error;
      --        end if;
      --     end loop;
      --
      --     HAQC.Configuration.Board.SPI.Release_Device;
      --  end;

      for Y in 0 .. GFX.Rasteriser.Device_Pixel_Count (320 - 1) loop
         Send_Framebuffer
           (Framebuffer => FB1,
            X           => 0,
            Y           => Y);
      end loop;

      To := A0B.ARMv7M.Profiling_Utilities.Get;
      Cyc_Fill := A0B.ARMv7M.Profiling_Utilities.Cycles (From, To);

      GFX.Framebuffers.Configure (FB2, 20, 20);

      for J in 0 .. GFX.Rasteriser.Device_Pixel_Count (10) loop
         GFX.Framebuffers.Set
           (FB2, J, J, GFX.Framebuffers.From_RGB (0, 255, 0));
      end loop;

      Send_Framebuffer
        (Framebuffer => FB2,
         X           => 100,
         Y           => 100);

      GFX.Rasteriser.Bitmap_Fonts.Draw_Text
        (Framebuffer => FB2,
         Font        => SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font,
         Color       => GFX.Framebuffers.From_RGB (0, 255, 0),
         X           => 100,
         Y           => 100,
         Text        => "Hello, SCD40!");

      loop
         null;
   --        --  Get sensor's serial number.
   --
   --        Success := True;
   --        Get_Serial_Number (Serial, Success);
   --
   --        exit when Success;
   --
   --     --  Operation fails when sensor is in the periodic measurement mode,
   --        --  stop periodic measurement to be able to configure sensor.
   --
   --        Success := True;
   --        Stop_Periodic_Measurement (Success);
   --
   --        if not Success then
   --           raise Program_Error;
   --        end if;
   --     end loop;
   --
   --     Console.Put_Line
   --       ("SCD40 S/N:" & A0B.SCD40.Serial_Number'Image (Serial));
   --
   --     --  Configure sensor.
   --
   --     Set_Sensor_Altitude (428);
   --
   --     Start_Periodic_Measurement;
   --
   --     loop
   --        Delay_For (A0B.Time.Seconds (1));
   --
   --        if Get_Data_Ready_Status then
   --           Read_Measurement;
   --
   --           Console.Put_Line
   --             ("T "
   --              & A0B.Types.Unsigned_16'Image (T)
   --              & "  RH "
   --              & A0B.Types.Unsigned_16'Image (RH)
   --              & "  CO2 "
   --              & A0B.Types.Unsigned_16'Image (CO2));
   --        end if;
      end loop;
   end Task_Subprogram;

end HAQC.GUI;
