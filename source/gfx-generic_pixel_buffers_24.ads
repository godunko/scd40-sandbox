--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Generic pixel buffer for 24-bit per pixel

pragma Restrictions (No_Elaboration_Code);

with System;

private with GFX.Clip_Rectangles;
with GFX.Points;
with GFX.Rasteriser;

generic
   type Pixel is private;

package GFX.Generic_Pixel_Buffers_24
  with Preelaborate
is

   type Pixel_Buffer (Capacity : GFX.GX_Unsigned) is limited private;
   --  @component Capacity  Number of pixel to be reserved minus one.

   procedure Fill
     (Self : in out Pixel_Buffer;
      To   : Pixel);

   procedure Configure
     (Self         : in out Pixel_Buffer;
      Top_Left     : GFX.Points.GI_Point;
      Bottom_Right : GFX.Points.GI_Point);

   procedure Buffer
     (Self    : Pixel_Buffer;
      Address : out System.Address;
      Size    : out GFX.GX_Unsigned);

   procedure Set
     (Self : in out Pixel_Buffer;
      X    : GFX.Rasteriser.Device_Pixel_Index;
      Y    : GFX.Rasteriser.Device_Pixel_Index;
      To   : Pixel);

   function Top (Self : Pixel_Buffer) return GFX.GX_Integer;

   function Left (Self : Pixel_Buffer) return GFX.GX_Integer;

   function Right (Self : Pixel_Buffer) return GFX.GX_Integer;

   function Bottom (Self : Pixel_Buffer) return GFX.GX_Integer;

   function Columns (Self : Pixel_Buffer) return GFX.GX_Unsigned;

   function Rows (Self : Pixel_Buffer) return GFX.GX_Unsigned;

private

   type Item is mod 2 ** 24 with Size => 24;

   pragma Assert (Pixel'Size = Item'Size);

   type Item_Array is array (GFX.GX_Unsigned range <>) of Item
     with Component_Size => 24;

   type Pixel_Buffer (Capacity : GFX.GX_Unsigned) is limited record
      Data    : Item_Array (0 .. Capacity);
      Clip    : GFX.Clip_Rectangles.GI_Clip_Rectangle;
      Columns : GFX.GX_Unsigned;
      Rows    : GFX.GX_Unsigned;
   end record;

end GFX.Generic_Pixel_Buffers_24;
