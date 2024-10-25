--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Generic pixel buffer for 24-bit per pixel

pragma Restrictions (No_Elaboration_Code);

with System;

with GFX.Rasteriser;

generic
   type Pixel is private;

package GFX.Generic_Pixel_Buffers_24
  with Preelaborate
is

   type Pixel_Buffer (Capacity : GFX.GX_Unsigned) is limited private;
   --  @component Capacity  Number of pixel to be reserved minus one.

   procedure Clear (Self : in out Pixel_Buffer);

   procedure Configure
     (Self   : in out Pixel_Buffer;
      X      : GFX.Rasteriser.Device_Pixel_Index;
      Y      : GFX.Rasteriser.Device_Pixel_Index;
      Width  : GFX.Rasteriser.Device_Pixel_Count;
      Height : GFX.Rasteriser.Device_Pixel_Count)
     with Pre =>
       Width >= 1
         and Height >= 1
         and GX_Unsigned (Width) * GX_Unsigned (Height) <= Self.Capacity + 1;

   procedure Buffer
     (Self    : Pixel_Buffer;
      Address : out System.Address;
      Size    : out GFX.GX_Unsigned);

   procedure Set
     (Self  : in out Pixel_Buffer;
      X     : GFX.Rasteriser.Device_Pixel_Index;
      Y     : GFX.Rasteriser.Device_Pixel_Index;
      Value : Pixel);

   function X (Self : Pixel_Buffer) return GFX.Rasteriser.Device_Pixel_Index;

   function Y (Self : Pixel_Buffer) return GFX.Rasteriser.Device_Pixel_Index;

   function Width
     (Self : Pixel_Buffer) return GFX.Rasteriser.Device_Pixel_Count;

   function Height
     (Self : Pixel_Buffer) return GFX.Rasteriser.Device_Pixel_Count;

private

   type Item is mod 2 ** 24 with Size => 24;

   pragma Assert (Pixel'Size = Item'Size);

   type Item_Array is array (GFX.GX_Unsigned range <>) of Item
     with Component_Size => 24;

   type Pixel_Buffer (Capacity : GFX.GX_Unsigned) is limited record
      Data   : Item_Array (0 .. Capacity);
      X      : GFX.GX_Integer;
      Y      : GFX.GX_Integer;
      Width  : GFX.GX_Unsigned;
      Height : GFX.GX_Unsigned;
   end record;

end GFX.Generic_Pixel_Buffers_24;
