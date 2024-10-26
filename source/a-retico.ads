
pragma Restrictions (No_Elaboration_Code);

with A0B.Time;

package Ada.Real_Time.Conversions is

   function To_Time_Span
     (Item : Ada.Real_Time.Time_Span) return A0B.Time.Time_Span;

end Ada.Real_Time.Conversions;
