--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Generic framebuffer for 18-bit color format for ILI9488 display
--
--  RRRRRR.. GGGGGG.. BBBBBB..
--
--  bits marked by '.' are ignored by the display, thus used to store 6 bit
--  alpha value.

pragma Restrictions (No_Elaboration_Code);

with System;

with GFX.Pixels.ILI9488_18;
with GFX.Rasteriser;

package GFX.Framebuffers is

   type Framebuffer (Capacity : GFX.GX_Unsigned) is limited private;
   --  @component Capacity  Number of pixel to be reserved minus one.

   procedure Clear (Self : in out Framebuffer);

   procedure Configure
     (Self   : in out Framebuffer;
      X      : GFX.Rasteriser.Device_Pixel_Index;
      Y      : GFX.Rasteriser.Device_Pixel_Index;
      Width  : GFX.Rasteriser.Device_Pixel_Count;
      Height : GFX.Rasteriser.Device_Pixel_Count)
     with Pre =>
       Width >= 1
         and Height >= 1
         and GX_Unsigned (Width) * GX_Unsigned (Height) <= Self.Capacity + 1;

   procedure Buffer
     (Self    : Framebuffer;
      Address : out System.Address;
      Size    : out GFX.GX_Unsigned);

   procedure Set
     (Self  : in out Framebuffer;
      X     : GFX.Rasteriser.Device_Pixel_Index;
      Y     : GFX.Rasteriser.Device_Pixel_Index;
      Value : GFX.Pixels.ILI9488_18.Pixel);

   function X (Self : Framebuffer) return GFX.Rasteriser.Device_Pixel_Index;

   function Y (Self : Framebuffer) return GFX.Rasteriser.Device_Pixel_Index;

   function Width
     (Self : Framebuffer) return GFX.Rasteriser.Device_Pixel_Count;

   function Height
     (Self : Framebuffer) return GFX.Rasteriser.Device_Pixel_Count;

private

   type Pixel_Array is
     array (GFX.GX_Unsigned range <>) of GFX.Pixels.ILI9488_18.Pixel
       with Pack;

   type Framebuffer (Capacity : GFX.GX_Unsigned) is limited record
      Data   : Pixel_Array (0 .. Capacity);
      X      : GFX.GX_Integer;
      Y      : GFX.GX_Integer;
      Width  : GFX.GX_Unsigned;
      Height : GFX.GX_Unsigned;
   end record;

end GFX.Framebuffers;
