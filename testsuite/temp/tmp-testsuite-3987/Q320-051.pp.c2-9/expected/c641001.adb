------------------------------------------------------------------- C641001

with Report;
with Tctouch;
with C641001_0;
procedure C641001 is

   function Ii (I : Integer) return Integer renames Report.Ident_Int;
   -- ^^ name chosen to allow embedding in calls

   A_String_10 : C641001_0.String_10;
   Slicable    : String (1 .. 40);
   Tag_Slices  : C641001_0.Tag_List (0 .. 11);

   Global_Data : String (1 .. 26) := "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

   procedure Check_Out_Sliding (Lo1, Hi1, Lo2, Hi2 : Natural) is

      subtype One_Constrained_String is String (Lo1 .. Hi1);   -- 1  5
      subtype Two_Constrained_String is String (Lo2 .. Hi2);   -- 6 10

      procedure Out_Param (Param : out One_Constrained_String) is
      begin
         Param := Report.Ident_Str (Global_Data (Lo2 .. Hi2));
      end Out_Param;
      Object : Two_Constrained_String;
   begin
      Out_Param (Object);
      if Object /= Report.Ident_Str (Global_Data (Lo2 .. Hi2)) then
         Report.Failed ("Bad result in Check_Out_Sliding");
      end if;
   exception
      when others =>
         Report.Failed ("Exception in Check_Out_Sliding");
   end Check_Out_Sliding;

   procedure Check_Dynamic_Subtype_Cases
     (F_Lower, F_Upper : Natural;
      A_Lower, A_Upper : Natural)
   is

      subtype Dyn_String is String (F_Lower .. F_Upper);

      procedure Check_Dyn_Subtype_Formal_Out (Param : out Dyn_String) is
      begin
         Param := Global_Data (11 .. 20);
      end Check_Dyn_Subtype_Formal_Out;

      procedure Check_Dyn_Subtype_Formal_In (Param : in Dyn_String) is
      begin
         if Param /= Global_Data (11 .. 20) then
            Report.Failed ("Dynamic case, data mismatch");
         end if;
      end Check_Dyn_Subtype_Formal_In;

      Stuff : String (A_Lower .. A_Upper);

   begin
      Check_Dyn_Subtype_Formal_Out (Stuff);
      Check_Dyn_Subtype_Formal_In (Stuff);
   end Check_Dynamic_Subtype_Cases;

begin  -- Main test procedure.

   Report.Test
     ("C641001",
      "Check that actual parameters passed by " &
      "reference are view converted to the nominal " &
      "subtype of the formal parameter");

   -- non error cases for string slices

   C641001_0.Check_String_10 (A_String_10, 1, 10);
   Tctouch.Assert (A_String_10 = "1234567890", "Nominal case");

   C641001_0.Check_String_10 (A_String_10, 11, 20);
   Tctouch.Assert (A_String_10 = "ABCDEFGHIJ", "Sliding to subtype");

   C641001_0.Check_String_10 (Slicable (1 .. 10), 1, 10);
   Tctouch.Assert (Slicable (1 .. 10) = "1234567890", "Slice, no sliding");

   C641001_0.Check_String_10 (Slicable (1 .. 10), 21, 30);
   Tctouch.Assert (Slicable (1 .. 10) = "KLMNOPQRST", "Sliding to slice");

   C641001_0.Check_String_10 (Slicable (11 .. 20), 11, 20);
   Tctouch.Assert (Slicable (11 .. 20) = "ABCDEFGHIJ", "Sliding to same");

   C641001_0.Check_String_10 (Slicable (21 .. 30), 11, 20);
   Tctouch.Assert (Slicable (21 .. 30) = "ABCDEFGHIJ", "Sliding up");

   -- error cases for string slices

   C641001_0.Check_Illegal_Slice_Reference (Slicable (21 .. 30), 20);

   C641001_0.Check_Illegal_Slice_Reference (Slicable (1 .. 15), Slicable'Last);

   -- checks for view converting actuals to formals

   -- catch low bound fault
   C641001_0.Check_Tag_Slice
     (Tag_Slices (Ii (0) .. 9));     -- II ::= Ident_Int
   Tctouch.Assert (Tag_Slices'First = 0, "Tag_Slices'First = 0");
   Tctouch.Assert (Tag_Slices'Last = 11, "Tag_Slices'Last = 11");

   -- catch high bound fault
   C641001_0.Check_Tag_Slice (Tag_Slices (2 .. Ii (11)));
   Tctouch.Assert (Tag_Slices'First = 0, "Tag_Slices'First = 0");
   Tctouch.Assert (Tag_Slices'Last = 11, "Tag_Slices'Last = 11");

   Check_Formal_Association_Check : begin
      C641001_0.Check_String_10 (Slicable, 1, 10); -- catch length fault
      Report.Failed ("Exception not raised at Check_Formal_Association_Check");
   exception
      when Constraint_Error =>
         null; -- expected case
      when others =>
         Report.Failed ("Wrong exception at Check_Formal_Association_Check");
   end Check_Formal_Association_Check;

   -- check for constrained actual, unconstrained formal
   C641001_0.Check_Out_Tagged_Data (Tag_Slices (5));
   Tctouch.Assert
     (Tag_Slices (5).Data_Item = "!****",
      "formal out returned bad result");

   -- additional checks for out mode formal parameters, dynamic subtypes

   Check_Out_Sliding (Ii (1), Ii (5), Ii (6), Ii (10));

   Check_Out_Sliding (21, 25, 6, 10);

   Check_Dynamic_Subtype_Cases
     (F_Lower => Ii (1),
      F_Upper => Ii (10),
      A_Lower => Ii (1),
      A_Upper => Ii (10));

   Check_Dynamic_Subtype_Cases
     (F_Lower => Ii (21),
      F_Upper => Ii (30),
      A_Lower => Ii (1),
      A_Upper => Ii (10));

   Check_Dynamic_Subtype_Cases
     (F_Lower => Ii (1),
      F_Upper => Ii (10),
      A_Lower => Ii (21),
      A_Upper => Ii (30));

   Report.Result;

end C641001;
