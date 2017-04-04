--===================================================--

package body C940004_1 is
-- Generic_Semaphore_Pkg

   protected body Semaphore_Type is

      function Tc_Count return Integer is
      begin
         return Request'Count;
      end Tc_Count;

      entry Request (R : in out User_Rec_Type) when not In_Use is
      begin
         In_Use               := True;
         R.Access_To_Resource := True;
      end Request;

      procedure Release (R : in out User_Rec_Type) is
      begin
         In_Use               := False;
         R.Access_To_Resource := False;
      end Release;

   end Semaphore_Type;

   function Has_Access (R : User_Rec_Type) return Boolean is
   begin
      return R.Access_To_Resource;
   end Has_Access;

end C940004_1;       -- Generic_Semaphore_Pkg
