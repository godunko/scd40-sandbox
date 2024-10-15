--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Await till callback.
--
--  This is Ada Tasking version.

private with Ada.Synchronous_Task_Control;

with A0B.Callbacks;

package A0B.Awaits
  with Preelaborate
is

   type Await is limited private;

   function Create_Callback
     (Self : aliased in out Await) return A0B.Callbacks.Callback;
   --  Returns callback object that unblocks call of Suspend_Delay_Callback.

   procedure Suspend_Until_Callback
     (Self    : in out Await;
      Success : in out Boolean);
   --  Suspend execution of the current task till callback is called.

private

   type Await is limited record
      Barrier : aliased Ada.Synchronous_Task_Control.Suspension_Object;
   end record;

end A0B.Awaits;
