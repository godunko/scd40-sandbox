--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

pragma Restrictions (No_Elaboration_Code);

package body GFX.Generic_Pixel_Buffers_24 is

   ------------
   -- Buffer --
   ------------

   procedure Buffer
     (Self    : Pixel_Buffer;
      Address : out System.Address;
      Size    : out GFX.GX_Unsigned) is
   begin
      Address := Self.Data'Address;
      Size    := Self.Width * Self.Height * 3;
   end Buffer;

   -----------
   -- Clear --
   -----------

   procedure Clear (Self : in out Pixel_Buffer) is
   begin
      Self.Data (0 .. Self.Width * Self.Height - 1) := [others => 0];
   end Clear;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Self   : in out Pixel_Buffer;
      X      : GFX.Rasteriser.Device_Pixel_Index;
      Y      : GFX.Rasteriser.Device_Pixel_Index;
      Width  : GFX.Rasteriser.Device_Pixel_Count;
      Height : GFX.Rasteriser.Device_Pixel_Count)
   is
      Max_Height : constant GFX.GX_Unsigned :=
        (Self.Capacity + 1) / GFX.GX_Unsigned (Width);

   begin
      if Max_Height = 0 or Max_Height < GFX.GX_Unsigned (Height) then
         raise Program_Error;
      end if;

      Self.X      := X;
      Self.Y      := Y;
      Self.Width  := GFX.GX_Unsigned (Width);
      Self.Height := GFX.GX_Unsigned (Height);
   end Configure;

   ------------
   -- Height --
   ------------

   function Height
     (Self : Pixel_Buffer) return GFX.Rasteriser.Device_Pixel_Count is
   begin
      return GFX.Rasteriser.Device_Pixel_Count (Self.Height);
   end Height;

   ---------
   -- Set --
   ---------

   procedure Set
     (Self  : in out Pixel_Buffer;
      X     : GFX.Rasteriser.Device_Pixel_Index;
      Y     : GFX.Rasteriser.Device_Pixel_Index;
      Value : Pixel) is
   begin
      if X in Self.X .. Self.X + GX_Integer (Self.Width) - 1
        and Y in Self.Y .. Self.Y + GX_Integer (Self.Width) - 1
      then
         declare
            Item : Pixel
              with Import,
                   Address =>
                     Self.Data
                       (GX_Unsigned (Y - Self.Y) * Self.Width
                          + GX_Unsigned (X - Self.X))'Address;

         begin
            Item := Value;
         end;
      end if;
   end Set;

   -----------
   -- Width --
   -----------

   function Width
     (Self : Pixel_Buffer) return GFX.Rasteriser.Device_Pixel_Count is
   begin
      return GFX.Rasteriser.Device_Pixel_Count (Self.Width);
   end Width;

   -------
   -- X --
   -------

   function X (Self : Pixel_Buffer) return GFX.Rasteriser.Device_Pixel_Index is
   begin
      return Self.X;
   end X;

   -------
   -- Y --
   -------

   function Y (Self : Pixel_Buffer) return GFX.Rasteriser.Device_Pixel_Index is
   begin
      return Self.Y;
   end Y;

end GFX.Generic_Pixel_Buffers_24;
