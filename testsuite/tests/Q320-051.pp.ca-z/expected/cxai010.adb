-- CXAI010.A
--
--                             Grant of Unlimited Rights
--
--     The Ada Conformity Assessment Authority (ACAA) holds unlimited
--     rights in the software and documentation contained herein. Unlimited
--     rights are the same as those granted by the U.S. Government for older
--     parts of the Ada Conformity Assessment Test Suite, and are defined
--     in DFAR 252.227-7013(a)(19). By making this public release, the ACAA
--     intends to confer upon all recipients unlimited rights equal to those
--     held by the ACAA. These rights include rights to use, duplicate,
--     release or disclose the released technical data and computer software
--     in whole or in part, in any manner and for any purpose whatsoever, and
--     to have or permit others to do so.
--
--                                    DISCLAIMER
--
--     ALL MATERIALS OR INFORMATION HEREIN RELEASED, MADE AVAILABLE OR
--     DISCLOSED ARE AS IS. THE ACAA MAKES NO EXPRESS OR IMPLIED
--     WARRANTY AS TO ANY MATTER WHATSOEVER, INCLUDING THE CONDITIONS OF THE
--     SOFTWARE, DOCUMENTATION OR OTHER INFORMATION RELEASED, MADE AVAILABLE
--     OR DISCLOSED, OR THE OWNERSHIP, MERCHANTABILITY, OR FITNESS FOR A
--     PARTICULAR PURPOSE OF SAID MATERIAL.
--
--                                     Notice
--
--     The ACAA has created and maintains the Ada Conformity Assessment Test
--     Suite for the purpose of conformity assessments conducted in accordance
--     with the International Standard ISO/IEC 18009 - Ada: Conformity
--     assessment of a language processor. This test suite should not be used
--     to make claims of conformance unless used in accordance with
--     ISO/IEC 18009 and any applicable ACAA procedures.
--*
-- OBJECTIVE:
--      Check that an implementation supports the functionality defined
--      in package Ada.Containers.Bounded_Vectors.
--
-- TEST DESCRIPTION:
--      This test verifies that an implementation supports the subprograms
--      contained in package Ada.Containers.Bounded_Vectors.
--      Each of the subprograms is exercised in a general sense, to ensure that
--      it is available, and that it provides the expected results in a known
--      test environment.
--
-- CHANGE HISTORY:
--      23 Sep 13   JAC     Initial pre-release version.
--       6 Dec 13   JAC     Second pre-release version.
--      28 Mar 14   RLB     Created ACATS 4.0 version, renamed test.
--                          Added additional capacity error cases.
--       3 Apr 14   RLB     Merged in tampering checks from third pre-release
--                          version.
--!
with Ada.Containers.Bounded_Vectors;
with Report;
with Ada.Exceptions;

procedure Cxai010 is

   My_Default_Value : constant := 999.0;

   type My_Float is new Float with
      Default_Value => My_Default_Value;

   package My_Bounded_Vectors is new Ada.Containers.Bounded_Vectors
     (Index_Type   => Natural,
      Element_Type => My_Float); -- Default =

   package My_Sorting is new My_Bounded_Vectors.Generic_Sorting ("<" => ">");
   -- Sort in reverse order to check is using what specified not simply <

   Num_Tests : constant := 10;

   Capacity_Reqd : constant := 2 * Num_Tests + 4;

   My_Vector_1 : My_Bounded_Vectors.Vector (Capacity => Capacity_Reqd);
   My_Vector_2 : My_Bounded_Vectors.Vector (Capacity => Capacity_Reqd);
   My_Vector_3 : My_Bounded_Vectors.Vector (Capacity => Capacity_Reqd);
   Big_Vector  : My_Bounded_Vectors.Vector (Capacity => Capacity_Reqd);

   subtype Array_Bounds_Type is Ada.Containers.Count_Type range 1 .. Num_Tests;

   -- No fractional parts so that can compare values for equality.

   Value_In_Array : constant array (Array_Bounds_Type) of My_Float :=
     (12.0, 23.0, 34.0, 45.0, 56.0, 67.0, 78.0, 89.0, 90.0, 1.0);

   My_Cursor_1 : My_Bounded_Vectors.Cursor;
   My_Cursor_2 : My_Bounded_Vectors.Cursor;
   My_Cursor_3 : My_Bounded_Vectors.Cursor;

   My_Index_1 : Natural;

   procedure Tampering_Check
     (Container : in out My_Bounded_Vectors.Vector;
      Where     : in     String) with
      Pre => not Container.Is_Empty
    is

      Program_Error_Raised : Boolean := False;

   begin

      declare
      begin

         -- Don't try to insert into a full bounded container as it's a grey
         -- area as to whether Capacity_Error or Program_Error should be raised

         Container.Delete_First;

      exception

         when Program_Error =>

            Program_Error_Raised := True;

      end;

      if not Program_Error_Raised then

         Report.Failed ("Tampering should have raised error in " & Where);

      end if;

   end Tampering_Check;

   use type Ada.Containers.Count_Type;
   use type My_Bounded_Vectors.Cursor;
   use type My_Bounded_Vectors.Vector;

begin

   Report.Test
     ("CXAI010",
      "Check that an implementation supports the functionality defined in " &
      "package Ada.Containers.Bounded_Vectors");

   -- Test Reserve_Capacity and Capacity

   declare
   begin

      My_Vector_1.Reserve_Capacity (Capacity => Num_Tests);

   exception

      when others =>

         Report.Failed
           ("Reserve_Capacity <= Capacity discriminant should have no effect" &
            " #1");

   end;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         My_Vector_2.Reserve_Capacity (Capacity => Capacity_Reqd + 1);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Reserve_Capacity beyond Capacity discriminant should have " &
            "failed with Capacity_Error");

      end if;

   end;

   declare
   begin

      My_Vector_2.Reserve_Capacity (Capacity => Num_Tests / 2);

   exception

      when others =>

         Report.Failed
           ("Reserve_Capacity <= Capacity discriminant should have no effect" &
            " #2");

   end;

   -- Compiler may warn that is always False

   if My_Vector_1.Capacity /= Capacity_Reqd then

      Report.Failed ("Capacity not as expected");

   end if;

   -- Test empty using Empty_Vector, Is_Empty, Length and Last_Index

   if My_Vector_1 /= My_Bounded_Vectors.Empty_Vector then

      Report.Failed ("Not initially empty #1");

   end if;

   if not My_Vector_1.Is_Empty then

      Report.Failed ("Not initially empty #2");

   end if;

   if My_Vector_1.Length /= 0 then

      Report.Failed ("Not initially empty #3");

   end if;

   if My_Vector_1.Last_Index /= My_Bounded_Vectors.No_Index then

      Report.Failed ("Not initially empty");

   end if;

   -- Test Append (element form), First, Element (cursor form), Query_Element
   -- (two forms), Next (two forms) and First_Element

   for I in Array_Bounds_Type loop

      My_Vector_1.Append (New_Item => Value_In_Array (I));

      if My_Vector_1.Length /= I then

         Report.Failed ("Wrong Length after appending");

      end if;

   end loop;

   My_Cursor_1 := My_Vector_1.First;

   for I in Array_Bounds_Type loop

      declare

         procedure My_Query (Element : in My_Float) is
         begin

            Tampering_Check
              (Container => My_Vector_1,
               Where     => "Query_Element");

            if Element /= Value_In_Array (I) then

               Report.Failed
                 ("Mismatch between element and what was appended #1");

            end if;

         end My_Query;

      begin

         if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
           Value_In_Array (I)
         then

            Report.Failed
              ("Mismatch between element and what was appended #2");

         end if;

         -- Toggle between the two forms of Query_Element

         if I mod 2 = 0 then

            My_Bounded_Vectors.Query_Element
              (Position => My_Cursor_1,
               Process  => My_Query'Access);

         else

            My_Vector_1.Query_Element
              (Index   => Natural (I) - 1,
               Process => My_Query'Access);

         end if;

      end;

      -- Toggle between alternative methods for incrementing cursor

      if I mod 2 = 0 then

         My_Cursor_1 := My_Bounded_Vectors.Next (Position => My_Cursor_1);

      else

         My_Bounded_Vectors.Next (Position => My_Cursor_1);

      end if;

   end loop;

   if My_Vector_1.First_Element /= Value_In_Array (Value_In_Array'First) then

      Report.Failed ("Mismatch between first element and first appended");

   end if;

   -- Test First_Index and Last_Index

   if My_Vector_1.First_Index /= Natural'First then

      Report.Failed ("First_Index not as expected");

   end if;

   -- Index_Type begins at 0 so last if N elements will have index N - 1
   if My_Vector_1.Last_Index /= Num_Tests - 1 then

      Report.Failed ("Last_Index not as expected");

   end if;

   -- Test To_Cursor and To_Index

   if My_Vector_1.To_Cursor (Index => My_Vector_1.First_Index) /=
     My_Vector_1.First
   then

      Report.Failed ("To_Cursor failed");

   end if;

   if My_Bounded_Vectors.To_Index (My_Vector_1.First) /=
     My_Vector_1.First_Index
   then

      Report.Failed ("To_Index failed");

   end if;

   -- Test Prepend, Last, Element, Previous (two forms) and Last_Element

   for I in reverse Array_Bounds_Type loop

      My_Vector_2.Prepend (New_Item => Value_In_Array (I));

      if My_Vector_2.Length /= Num_Tests - I + 1 then

         Report.Failed ("Wrong Length after prepending");

      end if;

   end loop;

   My_Cursor_2 := My_Vector_2.Last;

   for I in reverse Array_Bounds_Type loop

      if My_Bounded_Vectors.Element (Position => My_Cursor_2) /=
        Value_In_Array (I)
      then

         Report.Failed ("Mismatch between element and what was prepended");

      end if;

      -- Toggle between alternative methods for decrementing cursor

      if I mod 2 = 0 then

         My_Cursor_2 := My_Bounded_Vectors.Previous (Position => My_Cursor_2);

      else

         My_Bounded_Vectors.Previous (Position => My_Cursor_2);

      end if;

   end loop;

   if My_Vector_2.Last_Element /= Value_In_Array (Value_In_Array'Last) then

      Report.Failed ("Mismatch between last element and last prepended");

   end if;

   -- Test equality

   if My_Vector_1 /= My_Vector_2 then

      Report.Failed ("Bounded_Vectors not equal");

   end if;

   -- Test assignment, Iterate and Reverse_Iterate

   declare

      My_Vector_3 : My_Bounded_Vectors.Vector := My_Vector_1;

      I : Array_Bounds_Type := Array_Bounds_Type'First;

      procedure My_Process (Position : in My_Bounded_Vectors.Cursor) is
      begin

         Tampering_Check (Container => My_Vector_3, Where => "Iterate");

         if My_Bounded_Vectors.Element (Position) /= Value_In_Array (I) then

            Report.Failed ("Iterate hasn't found the expected value");

         end if;

         if I < Array_Bounds_Type'Last then

            I := I + 1;

         end if;

      end My_Process;

      procedure My_Reverse_Process (Position : in My_Bounded_Vectors.Cursor) is
      begin

         Tampering_Check
           (Container => My_Vector_3,
            Where     => "Reverse_Iterate");

         if My_Bounded_Vectors.Element (Position) /= Value_In_Array (I) then

            Report.Failed ("Reverse_Iterate hasn't found the expected value");

         end if;

         if I > Array_Bounds_Type'First then

            I := I - 1;

         end if;

      end My_Reverse_Process;

   begin

      My_Vector_3.Iterate (Process => My_Process'Access);

      My_Vector_3.Reverse_Iterate (Process => My_Reverse_Process'Access);

   end;

   -- Test Replace_Element (two forms) and Update_Element (two forms)

   -- Double the values of the two Bounded_Vectors by two different methods and
   -- check still equal

   My_Cursor_1 := My_Vector_1.First;
   My_Cursor_2 := My_Vector_2.First;

   for I in Array_Bounds_Type loop

      declare

         procedure My_Update (Element : in out My_Float) is
         begin

            Tampering_Check
              (Container => My_Vector_2,
               Where     => "Update_Element");

            Element := Element * 2.0;

         end My_Update;

      begin

         -- Toggle between the two forms of Replace_Element

         if I mod 2 = 0 then

            My_Vector_1.Replace_Element
              (Position => My_Cursor_1,
               New_Item => Value_In_Array (I) * 2.0);

         else

            My_Vector_1.Replace_Element
              (Index    => Natural (I) - 1,
               New_Item => Value_In_Array (I) * 2.0);

         end if;

         -- Toggle between the two forms of Update_Element. Different modulo to
         -- give more permutations

         if I mod 3 = 0 then

            My_Vector_2.Update_Element
              (Position => My_Cursor_2,
               Process  => My_Update'Access);

         else

            My_Vector_2.Update_Element
              (Index   => Natural (I) - 1,
               Process => My_Update'Access);

         end if;

      end;

      My_Bounded_Vectors.Next (Position => My_Cursor_1);
      My_Bounded_Vectors.Next (Position => My_Cursor_2);

   end loop;

   if My_Vector_1 /= My_Vector_2 then

      Report.Failed ("Doubled Bounded_Vectors not equal");

   end if;

   -- Test Clear, Reverse_Elements and inequality

   My_Vector_1.Clear;

   if not My_Vector_1.Is_Empty then

      Report.Failed ("Failed to clear");

   end if;

   for I in Array_Bounds_Type loop

      My_Vector_1.Append (New_Item => Value_In_Array (I));

   end loop;

   My_Vector_1.Reverse_Elements;

   My_Cursor_1 := My_Vector_1.First;

   for I in Array_Bounds_Type loop

      if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
        Value_In_Array (Num_Tests - I + 1)
      then

         Report.Failed ("Reversed array not as expected");

      end if;

      My_Bounded_Vectors.Next (Position => My_Cursor_1);

   end loop;

   if My_Vector_1 = My_Vector_2 then

      Report.Failed ("Different Bounded_Vectors equal");

   end if;

   -- Test Move. Target has the test values in reverse order, after Move these
   -- should be replaced (not appended) by the test values in forward order

   My_Vector_2.Clear;

   for I in Array_Bounds_Type loop

      My_Vector_2.Append (New_Item => Value_In_Array (I));

   end loop;

   My_Vector_1.Move (Source => My_Vector_2);

   if not My_Vector_2.Is_Empty then

      Report.Failed ("Moved source not empty");

   end if;

   My_Cursor_1 := My_Vector_1.First;

   for I in Array_Bounds_Type loop

      if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
        Value_In_Array (I)
      then

         Report.Failed ("Target vector not as expected after move");

      end if;

      My_Bounded_Vectors.Next (Position => My_Cursor_1);

   end loop;

   -- Test Insert (six forms; using different counts including default) and
   -- Swap (two forms)

   -- My_Vector_2 should initially be empty

   My_Vector_2.Insert
     (Before   => My_Bounded_Vectors.No_Element, -- At end
      New_Item => Value_In_Array (1)); -- Count should default to 1

   My_Vector_2.Insert
     (Before   => My_Bounded_Vectors.No_Element, -- At end
      New_Item => Value_In_Array (2),
      Position => My_Cursor_2, -- First of added elements
      Count    => 2);

   -- Elements with Default_Value. Should insert in-between the previous two
   -- blocks
   My_Vector_2.Insert
     (Before   => My_Cursor_2,
      Position => My_Cursor_2, -- First of added elements
      Count    => 3);

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         -- Elements with Default_Value
         My_Vector_2.Insert
           (Before   => My_Cursor_2,
            Position => My_Cursor_2, -- First of added elements
            Count    => Capacity_Reqd);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Inserting (element form) beyond capacity should have failed " &
            "with Capacity_Error");

      end if;

   end;

   -- The order should now be Value_In_Array (1), Default_Value, Default_Value,
   -- Default_Value, Value_In_Array (2), Value_In_Array (2)

   My_Vector_2.Swap
     (I => My_Vector_2.First,
      J => My_Cursor_2); -- First of added elements

   -- The order should now be Default_Value, Value_In_Array (1), Default_Value,
   -- Default_Value, Value_In_Array (2), Value_In_Array (2)

   My_Vector_2.Swap
     (I => My_Vector_2.Last_Index,
   -- Much easier decrementing an index than repeated calls of Previous of a
   -- cursor
      J => My_Vector_2.Last_Index - 2);

   -- The order should now be Default_Value, Value_In_Array (1), Default_Value,
   -- Value_In_Array (2), Value_In_Array (2), Default_Value

   My_Cursor_2 := My_Vector_2.First;

   -- Check = Default_Value
   if My_Bounded_Vectors.Element (Position => My_Cursor_2) /=
     My_Default_Value
   then

      Report.Failed ("Inserted value not as expected #1");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_2);

   if My_Bounded_Vectors.Element (Position => My_Cursor_2) /=
     Value_In_Array (1)
   then

      Report.Failed ("Inserted value not as expected #2");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_2);

   -- Check = Default_Value
   if My_Bounded_Vectors.Element (Position => My_Cursor_2) /=
     My_Default_Value
   then

      Report.Failed ("Inserted value not as expected #3");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_2);

   if My_Bounded_Vectors.Element (Position => My_Cursor_2) /=
     Value_In_Array (2)
   then

      Report.Failed ("Inserted value not as expected #4");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_2);

   if My_Bounded_Vectors.Element (Position => My_Cursor_2) /=
     Value_In_Array (2)
   then

      Report.Failed ("Inserted value not as expected #5");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_2);

   -- Check = Default_Value
   if My_Bounded_Vectors.Element (Position => My_Cursor_2) /=
     My_Default_Value
   then

      Report.Failed ("Inserted value not as expected #6");

   end if;

   My_Vector_3.Insert
     (Before   => My_Bounded_Vectors.No_Element, -- At end
      New_Item => My_Vector_2);

   My_Vector_3.Insert (Before => 3, New_Item => My_Vector_2);

   -- The order should now be Default_Value, Value_In_Array (1), Default_Value,
   -- Default_Value, Value_In_Array (1), Default_Value, Value_In_Array (2),
   -- Value_In_Array (2), Default_Value, Value_In_Array (2), Value_In_Array
   -- (2), Default_Value

   -- Fill up the big vector

   for I in Ada.Containers.Count_Type range 0 .. Capacity_Reqd - 1 loop

      Big_Vector.Append (New_Item => Value_In_Array ((I mod Num_Tests) + 1));

   end loop;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         Big_Vector.Append (New_Item => Value_In_Array (1));

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Appending when already full should have failed with " &
            "Capacity_Error");

      end if;

   end;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         Big_Vector.Prepend (New_Item => Value_In_Array (1));

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Prepending when already full should have failed with " &
            "Capacity_Error");

      end if;

   end;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         My_Vector_3.Insert (Before => 3, New_Item => Big_Vector);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Inserting (vector form) when already full should have failed " &
            "with Capacity_Error");

      end if;

   end;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         Big_Vector.Insert (Before => 5, New_Item => Value_In_Array (1));

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Inserting (element form, indexed) when already full should " &
            "have failed with Capacity_Error");

      end if;

   end;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         Big_Vector.Insert
           (Before   => My_Bounded_Vectors.No_Element, -- At end
            New_Item => Value_In_Array (1));

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Inserting (element form, cursor) when already full should " &
            "have failed with Capacity_Error");

      end if;

   end;

   -- Try not quite full cases of exceeding Capacity_Error.
   if Big_Vector.Length /= Capacity_Reqd then
      Report.Failed ("Big_Vector not full");
   end if;

   -- Remove the last two elements:
   Big_Vector.Delete_Last (Count => 2);

   if Big_Vector.Length /= Capacity_Reqd - 2 then
      Report.Failed ("Wrong size for Big_Vector after deleting last elements");
   end if;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         Big_Vector.Append (New_Item => Value_In_Array (1), Count => 3);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

            if Big_Vector.Length /= Capacity_Reqd - 2 then
               Report.Failed
                 ("Some elements added when Capacity_Error was raised " &
                  "for Append");
            end if;

         when Err : others =>

            Report.Failed
              ("Wrong exception raised when appending 3 elements when " &
               "nearly full");
            Report.Comment
              ("Raised " & Ada.Exceptions.Exception_Information (Err));

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Appending 3 elements when nearly full should have failed with " &
            "Capacity_Error");

      end if;

   end;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         Big_Vector.Prepend (New_Item => Value_In_Array (1), Count => 4);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

            if Big_Vector.Length /= Capacity_Reqd - 2 then
               Report.Failed
                 ("Some elements added when Capacity_Error was raised " &
                  "for Append");
            end if;

         when Err : others =>

            Report.Failed
              ("Wrong exception raised when prepending 4 elements when " &
               "nearly full");
            Report.Comment
              ("Raised " & Ada.Exceptions.Exception_Information (Err));

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Prepending 4 elements when nearly full should have failed with " &
            "Capacity_Error");

      end if;

   end;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         Big_Vector.Insert
           (Before   => Big_Vector.Find (Item => Value_In_Array (7)),
            New_Item => Value_In_Array (1),
            Count    => 5);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

            if Big_Vector.Length /= Capacity_Reqd - 2 then
               Report.Failed
                 ("Some elements added when Capacity_Error was raised " &
                  "for Insert");
            end if;

         when Err : others =>

            Report.Failed
              ("Wrong exception raised when inserting 5 elements when " &
               "nearly full");
            Report.Comment
              ("Raised " & Ada.Exceptions.Exception_Information (Err));

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Inserting 5 elements when nearly full should have failed with " &
            "Capacity_Error");

      end if;

   end;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         Big_Vector.Insert
           (Before   => 14,
            New_Item => Value_In_Array (1),
            Count    => 6);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

            if Big_Vector.Length /= Capacity_Reqd - 2 then
               Report.Failed
                 ("Some elements added when Capacity_Error was raised " &
                  "for Insert");
            end if;

         when Err : others =>

            Report.Failed
              ("Wrong exception raised when inserting 6 elements when " &
               "nearly full");
            Report.Comment
              ("Raised " & Ada.Exceptions.Exception_Information (Err));

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Inserting 6 elements when nearly full should have failed with " &
            "Capacity_Error");

      end if;

   end;

   -- Restore the list for following tests:
   Big_Vector.Append (Value_In_Array (4));
   Big_Vector.Append (Value_In_Array (5));

   My_Vector_3.Insert
     (Before   => My_Bounded_Vectors.No_Element, -- At end
      New_Item => My_Vector_2,
      Position => My_Cursor_3); -- First of added elements

   -- The order should now be Default_Value, Value_In_Array (1), Default_Value,
   -- Default_Value, Value_In_Array (1), Default_Value, Value_In_Array (2),
   -- Value_In_Array (2), Default_Value, Value_In_Array (2), Value_In_Array
   -- (2), Default_Value, Default_Value, Value_In_Array (1), Default_Value,
   -- Value_In_Array (2), Value_In_Array (2), Default_Value

   -- Check a few sample values

   if My_Vector_3.Element (Index => 4) /= Value_In_Array (1) then

      Report.Failed ("Inserted value not as expected #7");

   end if;

   if My_Vector_3.Element (Index => 8) /= My_Default_Value then

      Report.Failed ("Inserted value not as expected #8");

   end if;

   if My_Vector_3.Element (Index => 12) /= My_Default_Value then

      Report.Failed ("Inserted value not as expected #9");

   end if;

   if My_Vector_3.Element (Index => 16) /= Value_In_Array (2) then

      Report.Failed ("Inserted value not as expected #10");

   end if;

   -- Test Delete, Delete_First and Delete_Last (using different counts
   -- including default)

   -- My_Cursor_2 should initially be pointing to the last element of
   -- My_Vector_2

   My_Vector_2.Delete (Position => My_Cursor_2); -- Count should default to 1

   My_Vector_2.Delete (Index => 1); -- Count should default to 1

   My_Vector_2.Delete_First (Count => 1);

   My_Vector_2.Delete_Last (Count => 2);

   if My_Vector_2.Length /= 1 then

      Report.Failed ("Wrong Length after deleting");

   end if;

   -- Check = Default_Value
   if My_Bounded_Vectors.Element (My_Vector_2.First) /= My_Default_Value then

      Report.Failed ("Remaining value not as expected");

   end if;

   -- Test Find, Reverse_Find, Find_Index and Reverse_Find_Index

   -- My_Vector_1 should still contain the test values (in forward order), and
   -- My_Vector_2 a single element of the Default_Value

   My_Cursor_1 := My_Vector_1.Find (Item => Value_In_Array (3));

   My_Vector_1.Insert
     (Before   => My_Cursor_1,
      New_Item => My_Vector_2.First_Element);

   My_Vector_2.Delete_First;

   -- The order should now be Value_In_Array (1), Value_In_Array (2),
   -- Default_Value, Value_In_Array (3), Value_In_Array (4), Value_In_Array
   -- (5), Value_In_Array (6), Value_In_Array (7), Value_In_Array (8),
   -- Value_In_Array (9), Value_In_Array (10)

   -- My_Vector_2 should now be empty so re-fill

   for I in Array_Bounds_Type loop

      My_Vector_2.Append (New_Item => Value_In_Array (I));

   end loop;

   My_Cursor_1 := My_Vector_1.Reverse_Find (Item => Value_In_Array (5));

   My_Cursor_2 := My_Vector_2.Find (Item => Value_In_Array (7));

   My_Vector_1.Insert
     (Before   => My_Cursor_1,
      New_Item => My_Bounded_Vectors.Element (Position => My_Cursor_2));

   My_Vector_2.Delete (Position => My_Cursor_2); -- Count should default to 1

   -- The order should now be Value_In_Array (1), Value_In_Array (2),
   -- Default_Value, Value_In_Array (3), Value_In_Array (4), Value_In_Array
   -- (7), Value_In_Array (5), Value_In_Array (6), Value_In_Array (7),
   -- Value_In_Array (8), Value_In_Array (9), Value_In_Array (10)

   My_Index_1 := My_Vector_1.Find_Index (Item => Value_In_Array (9));

   My_Cursor_3 := My_Vector_1.Find (Item => Value_In_Array (2));

   My_Vector_1.Insert
     (Before   => My_Cursor_3,
      New_Item => My_Vector_1.Element (Index => My_Index_1));

   -- My_Cursor_1 is now "ambiguous" as an element has been inserted earlier
   -- in the list. (In the GNAT v7.1.2 implementation it is still pointing to
   -- the 11th element, but the original Value_In_Array (9) is now the 12th
   -- element). So find again, using Reverse_Find_Index to find the original
   -- Value_In_Array (9) not the copy before Value_In_Array (2)

   My_Index_1 := My_Vector_1.Reverse_Find_Index (Item => Value_In_Array (9));

   My_Vector_1.Delete (Index => My_Index_1); -- Count should default to 1

   -- The order should now be Value_In_Array (1), Value_In_Array (9),
   -- Value_In_Array (2), Default_Value, Value_In_Array (3), Value_In_Array
   -- (4), Value_In_Array (7), Value_In_Array (5), Value_In_Array (6),
   -- Value_In_Array (7), Value_In_Array (8), Value_In_Array (10)

   My_Cursor_1 := My_Vector_1.First;

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (1)
   then

      Report.Failed ("Value not as expected #1");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (9)
   then

      Report.Failed ("Value not as expected #2");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (2)
   then

      Report.Failed ("Value not as expected #3");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   -- Check = Default_Value
   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     My_Default_Value
   then

      Report.Failed ("Value not as expected #4");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (3)
   then

      Report.Failed ("Value not as expected #5");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (4)
   then

      Report.Failed ("Value not as expected #6");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (7)
   then

      Report.Failed ("Value not as expected #7");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (5)
   then

      Report.Failed ("Value not as expected #8");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (6)
   then

      Report.Failed ("Value not as expected #9");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (7)
   then

      Report.Failed ("Value not as expected #10");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (8)
   then

      Report.Failed ("Value not as expected #11");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   if My_Bounded_Vectors.Element (Position => My_Cursor_1) /=
     Value_In_Array (10)
   then

      Report.Failed ("Value not as expected #12");

   end if;

   -- Test Contains

   if not My_Vector_1.Contains (Item => Value_In_Array (8)) then

      Report.Failed ("Contains failed to find");

   end if;

   if My_Vector_1.Contains (Item => 0.0) then

      Report.Failed ("Contains found when shouldn't have");

   end if;

   -- Test Has_Element

   -- My_Cursor_1 should still be pointing to the last element

   if not My_Bounded_Vectors.Has_Element (Position => My_Cursor_1) then

      Report.Failed ("Has_Element failed to find");

   end if;

   My_Bounded_Vectors.Next (Position => My_Cursor_1);

   -- My_Cursor_1 should now be pointing off the end

   if My_Bounded_Vectors.Has_Element (Position => My_Cursor_1) then

      Report.Failed ("Has_Element found when shouldn't have");

   end if;

   -- Test Generic_Sorting, Assign and Copy

   if My_Sorting.Is_Sorted (Container => My_Vector_1) then

      Report.Failed ("Thinks is sorted when isn't");

   end if;

   My_Sorting.Sort (Container => My_Vector_1);

   if not My_Sorting.Is_Sorted (Container => My_Vector_1) then

      Report.Failed ("Thinks isn't sorted after Sort when should be");

   end if;

   My_Vector_2.Assign (Source => My_Vector_1);

   My_Sorting.Merge (Source => My_Vector_2, Target => My_Vector_1);

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         My_Sorting.Merge (Source => Big_Vector, Target => My_Vector_1);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Merging beyond capacity should have failed with Capacity_Error");

      end if;

   end;

   if not My_Sorting.Is_Sorted (Container => My_Vector_1) then

      Report.Failed ("Thinks isn't sorted after Merge when should be");

   end if;

   if My_Vector_1.Length /= Capacity_Reqd then

      Report.Failed ("Target vector hasn't grown as expected after Merge");

   end if;

   if My_Vector_2.Length /= 0 then

      Report.Failed ("Source vector length not 0 after Merge");

   end if;

   My_Vector_2 := My_Bounded_Vectors.Copy (Source => My_Vector_1);

   if My_Vector_2.Length /= Capacity_Reqd then

      Report.Failed ("Result length not as expected after Copy");

   end if;

   if My_Vector_1.Length /= Capacity_Reqd then

      Report.Failed ("Source length not left alone by Copy");

   end if;

   -- Test To_Vector (two forms) and Element (index form)

   -- If the capacity if the vector returned by the function on the right-hand
   -- side did not equal the Capacity discriminant of the left-hand side then
   -- the discriminant check would fail

   My_Vector_1 := My_Bounded_Vectors.To_Vector (Length => Capacity_Reqd);

   if My_Vector_1.Length /= Capacity_Reqd then

      Report.Failed ("To_Vector didn't create vector of given length");

   end if;

   -- Not easy to test that elements are empty since value unspecified and
   -- implementation dependent what the result of attempting to read would be

   -- If the capacity if the vector returned by the function on the right-hand
   -- side did not equal the Capacity discriminant of the left-hand side then
   -- the discriminant check would fail

   My_Vector_1 :=
     My_Bounded_Vectors.To_Vector
       (New_Item => My_Default_Value,
        Length   => Capacity_Reqd);

   for I in Array_Bounds_Type loop

      if My_Vector_1.Element (Index => Natural (I) - 1) /=
        My_Default_Value
      then

         Report.Failed ("To_Vector didn't create vector of given value");

      end if;

   end loop;

   -- Test Set_Length

   My_Vector_1.Set_Length (Length => Num_Tests * 2);

   if My_Vector_1.Length /= Num_Tests * 2 then

      Report.Failed ("Set_Length didn't change the length to the given value");

   end if;

   -- Test Insert_Space (two forms)

   My_Vector_1.Insert_Space (Before => My_Vector_1.Last_Index, Count => 1);

   if My_Vector_1.Length /= 2 * Num_Tests + 1 then

      Report.Failed
        ("Insert_Space (index form) didn't grow the length as expected");

   end if;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         My_Vector_1.Insert_Space
           (Before => My_Vector_1.Last_Index,
            Count  => Capacity_Reqd);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Inserting space (index form) beyond capacity should have " &
            "failed with Capacity_Error");

      end if;

   end;

   My_Vector_1.Insert_Space
     (Before   => My_Bounded_Vectors.No_Element, -- At end
      Position => My_Cursor_1,
      Count    => 1);

   if My_Vector_1.Length /= 2 * Num_Tests + 2 then

      Report.Failed
        ("Insert_Space (cursor form) didn't grow the length as expected");

   end if;

   declare

      Capacity_Error_Raised : Boolean := False;

   begin

      declare
      begin

         My_Vector_1.Insert_Space
           (Before   => My_Bounded_Vectors.No_Element, -- At end
            Position => My_Cursor_1,
            Count    => Capacity_Reqd);

      exception

         when Ada.Containers.Capacity_Error =>

            Capacity_Error_Raised := True;

      end;

      if not Capacity_Error_Raised then

         Report.Failed
           ("Inserting space (cursor form) beyond capacity should have " &
            "failed with Capacity_Error");

      end if;

   end;

   -- Test "&" and Append (vector form)

   -- If the capacity if the vector returned by the function on the right-hand
   -- side did not equal the Capacity discriminant of the left-hand side then
   -- the discriminant check would fail

   My_Vector_1.Clear;
   My_Vector_2.Clear;
   My_Vector_3.Clear;

   My_Vector_1 :=
     My_Bounded_Vectors.Copy
       (Source   => Value_In_Array (2) & Value_In_Array (3),
        Capacity => Capacity_Reqd);

   My_Vector_2 :=
     My_Bounded_Vectors.Copy
       (Source   => Value_In_Array (4) & Value_In_Array (5),
        Capacity => Capacity_Reqd);

   My_Vector_3 :=
     My_Bounded_Vectors.Copy
       (Source   => My_Vector_1 & My_Vector_2,
        Capacity => Capacity_Reqd);

   -- My Vector_3 should now contain Value_In_Array (2), Value_In_Array (3),
   -- Value_In_Array (4), Value_In_Array (5)

   My_Vector_3 :=
     My_Bounded_Vectors.Copy
       (Source   => My_Vector_3 & Value_In_Array (6),
        Capacity => Capacity_Reqd);

   -- My Vector_3 should now contain Value_In_Array (2), Value_In_Array (3),
   -- Value_In_Array (4), Value_In_Array (5), Value_In_Array (6)

   My_Vector_3 :=
     My_Bounded_Vectors.Copy
       (Source   => Value_In_Array (1) & My_Vector_3,
        Capacity => Capacity_Reqd);

   -- My Vector_3 should now contain Value_In_Array (1), Value_In_Array
   -- (2), Value_In_Array (3), Value_In_Array (4), Value_In_Array (5),
   -- Value_In_Array (6)

   My_Vector_2 :=
     My_Bounded_Vectors.Copy
       (Source   => Value_In_Array (7) & Value_In_Array (8),
        Capacity => Capacity_Reqd);

   My_Vector_3.Append (New_Item => My_Vector_2);

   -- My Vector_3 should now contain Value_In_Array (1), Value_In_Array
   -- (2), Value_In_Array (3), Value_In_Array (4), Value_In_Array (5),
   -- Value_In_Array (6), Value_In_Array (7), Value_In_Array (8)

   for I in 0 .. 7 loop

      if My_Vector_3.Element (Index => I) /=
        Value_In_Array (Ada.Containers.Count_Type (I) + 1)
      then

         Report.Failed ("Value after & not as expected");

      end if;

   end loop;

   Report.Result;

end Cxai010;
