--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

pragma Restrictions (No_Elaboration_Code);

package body GFX.Generic_Pixel_Buffers_24 is

   ------------
   -- Bottom --
   ------------

   function Bottom (Self : Pixel_Buffer) return GFX.GX_Integer is
   begin
      return Self.Clip.Bottom;
   end Bottom;

   ------------
   -- Buffer --
   ------------

   procedure Buffer
     (Self    : Pixel_Buffer;
      Address : out System.Address;
      Size    : out GFX.GX_Unsigned) is
   begin
      Address := Self.Data'Address;
      Size    := Self.Columns * Self.Rows * 3;
   end Buffer;

   -----------
   -- Clear --
   -----------

   procedure Clear (Self : in out Pixel_Buffer) is
   begin
      Self.Data (0 .. Self.Columns * Self.Rows - 1) := [others => 0];
   end Clear;

   -------------
   -- Columns --
   -------------

   function Columns (Self : Pixel_Buffer) return GFX.GX_Unsigned is
   begin
      return Self.Columns;
   end Columns;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Self         : in out Pixel_Buffer;
      Top_Left     : GFX.Points.GI_Point;
      Bottom_Right : GFX.Points.GI_Point)
   is
      Columns : constant GFX.GX_Unsigned :=
        GFX.GX_Unsigned
          (GFX.GX_Integer'Max (0, Bottom_Right.X - Top_Left.X + 1));
      Rows    : constant GFX.GX_Unsigned :=
        GFX.GX_Unsigned
          (GFX.GX_Integer'Max (0, Bottom_Right.Y - Top_Left.Y + 1));

   begin
      if Self.Capacity + 1 < Columns * Rows then
         raise Program_Error;
      end if;

      Self.Clip.Top  := Top_Left.Y;
      Self.Clip.Left := Top_Left.X;
      Self.Columns   := Columns;
      Self.Rows      := Rows;

      if Columns = 0 or else Rows = 0 then
         Self.Clip.Right  := Top_Left.X - 1;
         Self.Clip.Bottom := Top_Left.Y - 1;

      else
         Self.Clip.Right  := Bottom_Right.X;
         Self.Clip.Bottom := Bottom_Right.Y;
      end if;
   end Configure;

   ----------
   -- Left --
   ----------

   function Left (Self : Pixel_Buffer) return GFX.GX_Integer is
   begin
      return Self.Clip.Left;
   end Left;

   -----------
   -- Right --
   -----------

   function Right (Self : Pixel_Buffer) return GFX.GX_Integer is
   begin
      return Self.Clip.Right;
   end Right;

   ----------
   -- Rows --
   ----------

   function Rows (Self : Pixel_Buffer) return GFX.GX_Unsigned is
   begin
      return Self.Rows;
   end Rows;

   ---------
   -- Set --
   ---------

   procedure Set
     (Self : in out Pixel_Buffer;
      X    : GFX.Rasteriser.Device_Pixel_Index;
      Y    : GFX.Rasteriser.Device_Pixel_Index;
      To   : Pixel) is
   begin
      if X in Self.Clip.Left .. Self.Clip.Right
        and Y in Self.Clip.Top .. Self.Clip.Bottom
      then
         declare
            Component : Pixel
              with Import,
                   Address =>
                     Self.Data
                       (GX_Unsigned (Y - Self.Clip.Top) * Self.Columns
                          + GX_Unsigned (X - Self.Clip.Left))'Address;

         begin
            Component := To;
         end;
      end if;
   end Set;

   ---------
   -- Top --
   ---------

   function Top (Self : Pixel_Buffer) return GFX.GX_Integer is
   begin
      return Self.Clip.Top;
   end Top;

end GFX.Generic_Pixel_Buffers_24;
