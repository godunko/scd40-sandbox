--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Callbacks.Generic_Subprogram;

package body A0B.Awaits is

   procedure On_Callback (Self : in out Await);

   package Callbacks is
     new A0B.Callbacks.Generic_Subprogram (Await, On_Callback);

   ---------------------
   -- Create_Callback --
   ---------------------

   function Create_Callback
     (Self : aliased in out Await) return A0B.Callbacks.Callback is
   begin
      --  pragma Assert
      --    (not Ada.Synchronous_Task_Control.Current_State (Self.Barrier));
      Ada.Synchronous_Task_Control.Set_False (Self.Barrier);

      return Callbacks.Create_Callback (Self);
   end Create_Callback;

   -----------------
   -- On_Callback --
   -----------------

   procedure On_Callback (Self : in out Await) is
   begin
      Ada.Synchronous_Task_Control.Set_True (Self.Barrier);
   end On_Callback;

   ----------------------------
   -- Suspend_Until_Callback --
   ----------------------------

   procedure Suspend_Until_Callback
     (Self    : in out Await;
      Success : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      Ada.Synchronous_Task_Control.Suspend_Until_True (Self.Barrier);
      Ada.Synchronous_Task_Control.Set_False (Self.Barrier);
   end Suspend_Until_Callback;

end A0B.Awaits;
