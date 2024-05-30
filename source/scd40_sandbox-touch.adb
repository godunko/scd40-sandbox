--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.SVD.STM32H723.GPIO; use A0B.SVD.STM32H723.GPIO;
with A0B.SVD.STM32H723.RCC;  use A0B.SVD.STM32H723.RCC;
with A0B.SVD.STM32H723.SPI;  use A0B.SVD.STM32H723.SPI;

package body SCD40_Sandbox.Touch is

   procedure Configure_GPIO is

      subtype Low_Line is Integer range 0 .. 7;
      subtype High_Line is Integer range 8 .. 15;

      -----------------
      -- Configure_H --
      -----------------

      procedure Configure_H
        (Peripheral  : in out GPIO_Peripheral;
         Line        : High_Line;
         Alternative : AFRH_AFSEL_Element) is
      begin
         Peripheral.OSPEEDR.Arr (Line) := 2#00#;      --  Low high speed
         Peripheral.OTYPER.OT.Arr (Line) := False;    --  Output push-pull
         Peripheral.PUPDR.Arr (Line) := 2#01#;        --  Pullup
         Peripheral.AFRH.Arr (Line) := Alternative;   --  Alternate function
         Peripheral.MODER.Arr (Line) := 2#10#;        --  Alternate function
      end Configure_H;

      -----------------
      -- Configure_L --
      -----------------

      procedure Configure_L
        (Peripheral  : in out GPIO_Peripheral;
         Line        : Low_Line;
         Alternative : AFRH_AFSEL_Element) is
      begin
         Peripheral.OSPEEDR.Arr (Line) := 2#00#;      --  Low high speed
         Peripheral.OTYPER.OT.Arr (Line) := False;    --  Output push-pull
         Peripheral.PUPDR.Arr (Line) := 2#01#;        --  Pullup
         Peripheral.AFRL.Arr (Line) := Alternative;   --  Alternate function
         Peripheral.MODER.Arr (Line) := 2#10#;        --  Alternate function
      end Configure_L;

   begin
      --  Enable clocks

      RCC_Periph.AHB4ENR.GPIOAEN := True;
      RCC_Periph.AHB4ENR.GPIOGEN := True;

      --  PG12 -> SPI6_MISO
      Configure_H (GPIOG_Periph, 12, 5);
      --  PA7  -> SPI6_MOSI
      Configure_L (GPIOA_Periph, 7, 8);
      --  PG13 -> SPI6_SCK
      Configure_H (GPIOG_Periph, 13, 5);
      --  PA0  -> SPI6_NSS
      Configure_L (GPIOC_Periph, 0, 5);
   end Configure_GPIO;

   -------------------
   -- Configure_SPI --
   -------------------

   procedure Configure_SPI is
   begin
      RCC_Periph.D3CCIPR.SPI6SEL := 2#000#;
      --  rcc_pclk4 clock selected as kernel peripheral clock
      RCC_Periph.APB4ENR.SPI6EN := True;
      --  SPI6 peripheral clocks enabled

      SPI6_Periph.CR1.SPE := False;
      --  Disable to be able to configure

      SPI6_Periph.CFG1 :=
        (DSIZE   => 7,       --  8 bits in frame, for experiment only
         FTHVL   => 0,       --  FIFO threshold level: 1-data
         UDRCFG  => <>,      --  if slave
         UDRDET  => <>,      --  if slave
         RXDMAEN => False,   --  Rx-DMA disabled
         TXDMAEN => False,   --  Tx DMA disabled
         CRCSIZE => <>,      --  if CRCEN
         CRCEN   => False,   --  CRC calculation disabled
         MBR     => 2#101#,  --  SPI master clock/64
         others  => <>);
      SPI6_Periph.CFG2 :=
        (MSSI    => 0,       --  (+1)
         MIDI    => 0,
         IOSWP   => False,   --  no swap
         COMM    => 2#00#,   --  full-duplex
         SP      => 2#000#,  --  SPI Motorola
         MASTER  => True,    --  SPI Master
         LSBFRST => False,   --  MSB transmitted first
         CPHA    => False,
         --  the first clock transition is the first data capture edge
         CPOL    => False,   --  SCK signal is at 0 when idle
         SSM     => False,   --  SS input value is determined by the SS PAD
         SSIOP   => False,   --  Low level is active for SS signal
         SSOE    => True,    --  SS output is enabled.
         SSOM    => False,
         --  SS is kept at active level till data transfer is completed, it
         --  becomes inactive with EOT flag
         AFCNTR  => True,
         --  The peripheral keeps always control of all associated GPIOs
         others  => <>);
      SPI6_Periph.I2SCFGR.I2SMOD := False;

      --  SPI6_Periph.CR2 :=
      --    (TSIZE : CR2_TSIZE_Field,
      --     TSER : CR2_TSER_Field);
      SPI6_Periph.CR1 :=
        (SPE      => False,  --  serial peripheral disabled
         MASRX    => True,
         --  SPI flow is suspended temporary on RxFIFO full condition, before
         --  reaching overrun condition.
         CSTART   => False,
         CSUSP    => False,
         HDDIR    => <>,     --  if half-duplex
         SSI      => <>,     --  if SSM
         CRC33_17 => <>,     --  if CRCEN
         RCRCI    => <>,     --  if CRCEN
         TCRCI    => <>,     --  if CRCEN
         IOLOCK   => False,  --  AF configuration is not locked
         others   => <>);
   end Configure_SPI;

   --  TIN : array (1 .. 2) of A0B.Types.Unsigned_16;

   ---------------
   -- Get_Touch --
   ---------------

   procedure Get_Touch is

      use type A0B.Types.Unsigned_8;

      -------------
      -- Convert --
      -------------

      function Convert
        (B2, B3 : A0B.Types.Unsigned_8) return A0B.Types.Unsigned_12
      is
         use type A0B.Types.Unsigned_16;

      begin
         return
           A0B.Types.Unsigned_12
             ((A0B.Types.Shift_Left (A0B.Types.Unsigned_16 (B2), 5)
                 or A0B.Types.Shift_Right (A0B.Types.Unsigned_16 (B3), 3))
               and 16#FFF#);
      end Convert;

   begin
      declare
         TXDR : A0B.Types.Unsigned_8
           with Import, Address => SPI6_Periph.TXDR'Address;
         RXDR : A0B.Types.Unsigned_8
           with Import, Address => SPI6_Periph.RXDR'Address;

      begin
         SPI6_Periph.CR1.SPE := True;
         SPI6_Periph.CR1.CSTART := True;

         for J in CMD'Range loop
            TXDR := CMD (J);

            while not SPI6_Periph.SR.RXP loop
               null;
            end loop;

            DAT (J) := RXDR;
         end loop;

         SPI6_Periph.CR1.SPE := False;

         if DAT (0) = 16#00#
           and DAT (3) = 16#00#
           and DAT (6) = 16#00#
           and DAT (9) = 16#00#
         then
            VAL.Z1 := Convert (DAT (1), DAT (2));
            VAL.Z2 := Convert (DAT (4), DAT (5));
            VAL.X  := Convert (DAT (7), DAT (8));
            VAL.Y  := Convert (DAT (10), DAT (11));
         end if;
      end;
   end Get_Touch;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Configure_SPI;
      Configure_GPIO;

      Get_Touch;
   end Initialize;

end SCD40_Sandbox.Touch;
