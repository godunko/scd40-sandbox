--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

pragma Restrictions (No_Elaboration_Code);

package body GFX.Framebuffers is

   ------------
   -- Buffer --
   ------------

   procedure Buffer
     (Self    : Framebuffer;
      Address : out System.Address;
      Size    : out GFX.GX_Unsigned) is
   begin
      Address := Self.Data'Address;
      Size    := Self.Width * Self.Height * 3;
   end Buffer;

   -----------
   -- Clear --
   -----------

   procedure Clear (Self : in out Framebuffer) is
   begin
      Self.Data (0 .. Self.Width * Self.Height - 1) := [others => 0];
   end Clear;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Self   : in out Framebuffer;
      Width  : GFX.Rasteriser.Device_Pixel_Count;
      Height : GFX.Rasteriser.Device_Pixel_Count)
   is
      Max_Height : constant GFX.GX_Unsigned :=
        (Self.Capacity + 1) / GFX.GX_Unsigned (Width);

   begin
      if Max_Height = 0 or Max_Height < GFX.GX_Unsigned (Height) then
         raise Program_Error;
      end if;

      Self.Width  := GFX.GX_Unsigned (Width);
      Self.Height := GFX.GX_Unsigned (Height);
   end Configure;

   --------------
   -- From_RGB --
   --------------

   function From_RGB
     (R : Interfaces.Unsigned_8;
      G : Interfaces.Unsigned_8;
      B : Interfaces.Unsigned_8) return Pixel is
   begin
      return
        Pixel
          (GX_Unsigned (R) * 2 ** 16
           or GX_Unsigned (G) * 2 ** 8
           or GX_Unsigned (B));
   end From_RGB;

   ------------
   -- Height --
   ------------

   function Height
     (Self : Framebuffer) return GFX.Rasteriser.Device_Pixel_Index is
   begin
      return GFX.Rasteriser.Device_Pixel_Index (Self.Height);
   end Height;

   ---------
   -- Set --
   ---------

   procedure Set
     (Self  : in out Framebuffer;
      X     : GFX.Rasteriser.Device_Pixel_Index;
      Y     : GFX.Rasteriser.Device_Pixel_Index;
      Value : Pixel) is
   begin
      Self.Data (GX_Unsigned (Y) * Self.Width + GX_Unsigned (X)) := Value;
   end Set;

   -----------
   -- Width --
   -----------

   function Width
     (Self : Framebuffer) return GFX.Rasteriser.Device_Pixel_Index is
   begin
      return GFX.Rasteriser.Device_Pixel_Index (Self.Width);
   end Width;

end GFX.Framebuffers;
