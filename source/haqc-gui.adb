--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Real_Time;

with A0B.Awaits;
with A0B.ILI9488;
with A0B.ARMv7M.Profiling_Utilities;
with A0B.SPI;
with A0B.Tasking;
with A0B.Types.Arrays;

with GFX.Pixel_Buffers;
with GFX.Pixels.ILI9488_18;
with GFX.Rasteriser.Bitmap_Fonts;

with HAQC.Configuration.Board;
with HAQC.UI;
with HAQC.Sensors.BME280;
--  with HAQC.Configuration.Sensors;
with SCD40_Sandbox.Fonts.DejaVuSansCondensed_32;

package body HAQC.GUI is

   TCB : aliased A0B.Tasking.Task_Control_Block;

   procedure Task_Subprogram;

   Await            : aliased A0B.Awaits.Await;
   Command_Buffer   : A0B.Types.Arrays.Unsigned_8_Array (0 .. 0);
   Parameter_Buffer : A0B.Types.Arrays.Unsigned_8_Array (0 .. 3);
   Buffers          : A0B.SPI.Buffer_Descriptor_Array (0 .. 0);

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

   FB1 : GFX.Pixel_Buffers.Pixel_Buffer (480 * 20 - 1);
   FB2 : GFX.Pixel_Buffers.Pixel_Buffer (480 * 20 - 1);
   --  FB2 : GFX.Pixel_Buffers.Pixel_Buffer (8_192 - 1);

   -------------------
   -- Register_Task --
   -------------------

   procedure Register_Task is
   begin
      A0B.Tasking.Register_Thread (TCB, Task_Subprogram'Access, 16#400#);
   end Register_Task;

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
     (Framebuffer : GFX.Pixel_Buffers.Pixel_Buffer)
   is
      use type A0B.Types.Unsigned_16;

      SC : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (GFX.Pixel_Buffers.Left (Framebuffer));
      EC : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (GFX.Pixel_Buffers.Right (Framebuffer));
      SP : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (GFX.Pixel_Buffers.Top (Framebuffer));
      EP : constant A0B.Types.Unsigned_16 :=
        A0B.Types.Unsigned_16 (GFX.Pixel_Buffers.Bottom (Framebuffer));

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

      GFX.Pixel_Buffers.Buffer
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
      use type GFX.GX_Integer;

      From  : A0B.ARMv7M.Profiling_Utilities.Stamp;
      To    : A0B.ARMv7M.Profiling_Utilities.Stamp;

      Background : constant GFX.Pixels.ILI9488_18.Pixel :=
        GFX.Pixels.ILI9488_18.From_RGB (16#12#, 16#12#, 16#12#);
      Surface    : constant GFX.Pixels.ILI9488_18.Pixel :=
        GFX.Pixels.ILI9488_18.From_RGB (16#2C#, 16#2C#, 16#2C#);
      Text       : constant GFX.Pixels.ILI9488_18.Pixel :=
        GFX.Pixels.ILI9488_18.From_RGB (16#E3#, 16#E3#, 16#E3#);

   begin
      GFX.Pixel_Buffers.Configure (FB1, (0, 0), (479, 0));
      GFX.Pixel_Buffers.Configure (FB2, (0, 0), (479, 0));

      GFX.Pixel_Buffers.Fill (FB1, Background);
      GFX.Pixel_Buffers.Fill (FB2, Background);

      A0B.ARMv7M.Profiling_Utilities.Initialize;

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

      From := A0B.ARMv7M.Profiling_Utilities.Get;

      for Y in 0 .. GFX.Rasteriser.Device_Pixel_Count (320 - 1) loop
         GFX.Pixel_Buffers.Configure (FB1, (0, Y), (479, Y));
         GFX.Pixel_Buffers.Fill (FB1, Background);
         Send_Framebuffer (FB1);
      end loop;

      To := A0B.ARMv7M.Profiling_Utilities.Get;
      Cyc_Fill := A0B.ARMv7M.Profiling_Utilities.Cycles (From, To);

      --  Draw gree line

      GFX.Pixel_Buffers.Configure (FB2, (100, 100), (119, 119));

      for J in 100 .. GFX.Rasteriser.Device_Pixel_Count (120) loop
         GFX.Pixel_Buffers.Set
           (FB2, J, J, GFX.Pixels.ILI9488_18.From_RGB (0, 255, 0));
      end loop;

      Send_Framebuffer (FB2);

      --  Draw text

      declare
         X : constant := 240;
         Y : constant := 50;

      begin
         GFX.Pixel_Buffers.Configure (FB2, (X, Y - 35), (X + 199, Y + 5));
         GFX.Pixel_Buffers.Fill (FB2, Surface);
         GFX.Rasteriser.Bitmap_Fonts.Draw_Text
           (Framebuffer => FB2,
            Font        => SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font,
            Color       => Text,
            X           => X,
            Y           => Y,
            Text        => "Hello, SCD40!");

         Send_Framebuffer (FB2);
      end;

      loop
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);

         declare
            Image : constant Wide_String :=
              Integer'Wide_Image (HAQC.UI.Get_T);
            X : constant := 240;
            Y : constant := 50;

         begin
            GFX.Pixel_Buffers.Configure (FB2, (X, Y - 35), (X + 199, Y + 5));
            GFX.Pixel_Buffers.Fill (FB2, Surface);
            GFX.Rasteriser.Bitmap_Fonts.Draw_Text
              (Framebuffer => FB2,
               Font        => SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font,
               Color       => Text,
               X           => X,
               Y           => Y,
               Text        => Image);

            Send_Framebuffer (FB2);
         end;

         declare
            Image : constant Wide_String :=
              Integer'Wide_Image (HAQC.UI.Get_RH);
            X : constant := 240;
            Y : constant := 100;

         begin
            GFX.Pixel_Buffers.Configure (FB2, (X, Y - 35), (X + 199, Y + 5));
            GFX.Pixel_Buffers.Fill (FB2, Surface);
            GFX.Rasteriser.Bitmap_Fonts.Draw_Text
              (Framebuffer => FB2,
               Font        => SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font,
               Color       => Text,
               X           => X,
               Y           => Y,
               Text        => Image);

            Send_Framebuffer (FB2);
         end;

         declare
            Image : constant Wide_String :=
              Integer'Wide_Image (HAQC.UI.Get_CO2);
            X : constant := 240;
            Y : constant := 200;

         begin
            GFX.Pixel_Buffers.Configure (FB2, (X, Y - 35), (X + 199, Y + 5));
            GFX.Pixel_Buffers.Fill (FB2, Surface);
            GFX.Rasteriser.Bitmap_Fonts.Draw_Text
              (Framebuffer => FB2,
               Font        => SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font,
               Color       => Text,
               X           => X,
               Y           => Y,
               Text        => Image);

            Send_Framebuffer (FB2);
         end;

         declare
            Image : constant Wide_String :=
              HAQC.Sensors.BME280.Temperature_Type'Wide_Image
                (HAQC.Sensors.BME280.Temperature);
            X : constant := 20;
            Y : constant := 50;

         begin
            GFX.Pixel_Buffers.Configure (FB2, (X, Y - 35), (X + 199, Y + 5));
            GFX.Pixel_Buffers.Fill (FB2, Surface);
            GFX.Rasteriser.Bitmap_Fonts.Draw_Text
              (Framebuffer => FB2,
               Font        => SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font,
               Color       => Text,
               X           => X,
               Y           => Y,
               Text        => Image);

            Send_Framebuffer (FB2);
         end;

         declare
            Image : constant Wide_String :=
              HAQC.Sensors.BME280.Relative_Humidity_Type'Wide_Image
                (HAQC.Sensors.BME280.Relative_Humidity);
            X : constant := 20;
            Y : constant := 100;

         begin
            GFX.Pixel_Buffers.Configure (FB2, (X, Y - 35), (X + 199, Y + 5));
            GFX.Pixel_Buffers.Fill (FB2, Surface);
            GFX.Rasteriser.Bitmap_Fonts.Draw_Text
              (Framebuffer => FB2,
               Font        => SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font,
               Color       => Text,
               X           => X,
               Y           => Y,
               Text        => Image);

            Send_Framebuffer (FB2);
         end;

         declare
            Image : constant Wide_String :=
              HAQC.Sensors.BME280.Pressure_Type'Wide_Image
                (HAQC.Sensors.BME280.Pressure);
            X : constant := 20;
            Y : constant := 150;

         begin
            GFX.Pixel_Buffers.Configure (FB2, (X, Y - 35), (X + 199, Y + 5));
            GFX.Pixel_Buffers.Fill (FB2, Surface);
            GFX.Rasteriser.Bitmap_Fonts.Draw_Text
              (Framebuffer => FB2,
               Font        => SCD40_Sandbox.Fonts.DejaVuSansCondensed_32.Font,
               Color       => Text,
               X           => X,
               Y           => Y,
               Text        => Image);

            Send_Framebuffer (FB2);
         end;
      end loop;
   end Task_Subprogram;

end HAQC.GUI;
