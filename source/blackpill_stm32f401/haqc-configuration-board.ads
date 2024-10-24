--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.DMA.DMA1.Stream0;
with A0B.STM32F401.DMA.DMA1.Stream6;
with A0B.STM32F401.DMA.DMA2.Stream2;
with A0B.STM32F401.DMA.DMA2.Stream3;
with A0B.STM32F401.DMA.DMA2.Stream5;
with A0B.STM32F401.I2C.Generic_I2C1;
with A0B.STM32F401.GPIO.PIOA;
with A0B.STM32F401.GPIO.PIOB;
with A0B.STM32F401.SPI.Generic_SPI1;
with A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous;

package HAQC.Configuration.Board is

   --  pragma Preelaborate;

   package UART1 is
     new A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous
     (Receive_Stream => A0B.STM32F401.DMA.DMA2.Stream5.DMA2_Stream5'Access,
      TX_Pin         => A0B.STM32F401.GPIO.PIOA.PA9'Access,
      RX_Pin         => A0B.STM32F401.GPIO.PIOA.PA10'Access);

   package I2C1 is
     new A0B.STM32F401.I2C.Generic_I2C1
       (Transmit_Stream => A0B.STM32F401.DMA.DMA1.Stream6.DMA1_Stream6'Access,
        Receive_Stream  => A0B.STM32F401.DMA.DMA1.Stream0.DMA1_Stream0'Access,
        SCL_Pin         => A0B.STM32F401.GPIO.PIOB.PB8'Access,
        SDA_Pin         => A0B.STM32F401.GPIO.PIOB.PB9'Access);

   package SPI1 is
     new A0B.STM32F401.SPI.Generic_SPI1
       (Transmit_Stream => A0B.STM32F401.DMA.DMA2.Stream3.DMA2_Stream3'Access,
        Receive_Stream  => A0B.STM32F401.DMA.DMA2.Stream2.DMA2_Stream2'Access,
        MOSI_Pin        => A0B.STM32F401.GPIO.PIOA.PA7'Access,
        MISO_Pin        => A0B.STM32F401.GPIO.PIOA.PA6'Access,
        SCK_Pin         => A0B.STM32F401.GPIO.PIOA.PA5'Access,
        NSS_Pin         => A0B.STM32F401.GPIO.PIOA.PA4'Access);

   UART : A0B.STM32F401.USART.USART_Asynchronous_Device
     renames UART1.USART1_Asynchronous;
   I2C  : A0B.I2C.I2C_Bus_Master'Class
     renames A0B.I2C.I2C_Bus_Master'Class (I2C1.I2C1);
   SPI  : A0B.STM32F401.SPI.Master_Controller
     renames SPI1.SPI1;

   --  IMU_INT_Pin : A0B.STM32F401.GPIO.GPIO_Line
   --    renames A0B.STM32F401.GPIO.PIOB.PB15;

   LCD_LED_Pin    : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB2;
   LCD_DC_Pin     : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB1;
   LCD_RESET_Pin  : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB0;

   procedure Initialize;

end HAQC.Configuration.Board;
