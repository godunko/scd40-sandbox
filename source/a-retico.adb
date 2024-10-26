
pragma Restrictions (No_Elaboration_Code);

package body Ada.Real_Time.Conversions is

   ------------------
   -- To_Time_Span --
   ------------------

   function To_Time_Span
     (Item : Ada.Real_Time.Time_Span) return A0B.Time.Time_Span is
   begin
      return A0B.Time.Time_Span (Item);
   end To_Time_Span;

end Ada.Real_Time.Conversions;
