     --==================================================================--

package body C460005_0 is

   procedure Proc (X : in out Tag_Type) is
   begin
      X.C1 := 25;
   end Proc;

   -----------------------------------------
   procedure Proc (X : in out Dtag_Type) is
   begin
      Proc (Tag_Type (X));
      X.C2 := "Earth";
   end Proc;

   -----------------------------------------
   procedure Proc (X : in out Ddtag_Type) is
   begin
      Proc (Dtag_Type (X));
      X.C3 := "Orbit";
   end Proc;

end C460005_0;