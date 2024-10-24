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

end GFX.Framebuffers;
