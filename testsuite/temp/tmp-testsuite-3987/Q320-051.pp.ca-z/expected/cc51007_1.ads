-- No body for CC51007_0;

     --===================================================================--

with Cc51007_0;

with Ada.Calendar;
pragma Elaborate (Ada.Calendar);

package Cc51007_1 is

   type Low_Alert is new Cc51007_0.Alert with record
      Time_Of_Arrival : Ada.Calendar.Time :=
        Ada.Calendar.Time_Of (1_901, 8, 1);
   end record;

   procedure Handle (A : in out Low_Alert);           -- Overrides parent's
   -- implementation.
   Low : Low_Alert;

end Cc51007_1;
