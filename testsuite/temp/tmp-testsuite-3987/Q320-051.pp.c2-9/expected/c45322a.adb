-- C45322A.ADA

--                             Grant of Unlimited Rights
--
--     Under contracts F33600-87-D-0337, F33600-84-D-0280, MDA903-79-C-0687,
--     F08630-91-C-0015, and DCA100-97-D-0025, the U.S. Government obtained
--     unlimited rights in the software and documentation contained herein.
--     Unlimited rights are defined in DFAR 252.227-7013(a)(19).  By making
--     this public release, the Government intends to confer upon all
--     recipients unlimited rights  equal to those held by the Government.
--     These rights include rights to use, duplicate, release or disclose the
--     released technical data and computer software in whole or in part, in
--     any manner and for any purpose whatsoever, and to have or permit others
--     to do so.
--
--                                    DISCLAIMER
--
--     ALL MATERIALS OR INFORMATION HEREIN RELEASED, MADE AVAILABLE OR
--     DISCLOSED ARE AS IS.  THE GOVERNMENT MAKES NO EXPRESS OR IMPLIED
--     WARRANTY AS TO ANY MATTER WHATSOEVER, INCLUDING THE CONDITIONS OF THE
--     SOFTWARE, DOCUMENTATION OR OTHER INFORMATION RELEASED, MADE AVAILABLE
--     OR DISCLOSED, OR THE OWNERSHIP, MERCHANTABILITY, OR FITNESS FOR A
--     PARTICULAR PURPOSE OF SAID MATERIAL.
--*
-- OBJECTIVE:
--     CHECK THAT CONSTRAINT_ERROR IS RAISED IF
--     MACHINE_OVERFLOWS IS TRUE AND THE RESULT OF THE ADDITION OR
--     SUBTRACTION LIES OUTSIDE OF THE RANGE OF THE BASE TYPE.

-- *** NOTE: This test has been modified since ACVC version 1.11 to    -- 9X
-- ***       remove incompatibilities associated with the transition   -- 9X
-- ***       to Ada 9X.                                                -- 9X

-- HISTORY:
--     NPL 09/01/90  CREATED ORIGINAL TEST.
--     LDC 10/09/90  CHANGED THE STYLE OF THE TEST TO THE STANDARD
--                   ACVC FORMAT AND WRAPPED LINES WHICH WHERE LONGER
--                   THAN 71 CHARACTERS.
--     JRL 03/30/93  REMOVED NUMERIC_ERROR FROM TEST.

with Report; use Report;

procedure C45322a is

   type Float5 is digits 5;
   F5 : Float5;

   function Ident (F : Float5) return Float5 is
   begin
      return F * Float5 (Ident_Int (1));
   end Ident;

   function Equal (F, G : Float5) return Boolean is
   begin
      return F = G + Float5 (Ident_Int (0));
   end Equal;

begin
   Test
     ("C45322A",
      "CHECK THAT CONSTRAINT_ERROR " &
      "IS RAISED IF MACHINE_OVERFLOWS IS TRUE AND " &
      "THE RESULT OF THE ADDITION OR SUBTRACTION " &
      "LIES OUTSIDE OF THE RANGE OF THE BASE TYPE");

   if not Float5'Machine_Overflows then
      Not_Applicable ("MACHINE_OVERFLOWS IS FALSE");
   else

      begin
         F5 := Ident (Float5'Base'Last) + Float5'Base'Last;

         Failed ("NO EXCEPTION RAISED BY LARGE '+'");

         if not Equal (F5, F5) then
            Comment ("DON'T OPTIMIZE F5");
         end if;
      exception
         when Constraint_Error =>
            null;
         when others =>
            Failed ("UNEXPECTED EXCEPTION RAISED BY LARGE '+'");
      end;

      -- AS ABOVE BUT INTERCHANGING '+' AND '-'
      begin
         F5 := Ident (Float5'Base'Last) - Float5'Base'Last;

         if not Equal (F5, F5) then
            Comment ("DON'T OPTIMIZE F5");
         end if;
      exception
         when Constraint_Error =>
            Failed ("CONSTRAINT_ERROR " & "RAISED BY INTERCHANGING LARGE '+'");
         when others =>
            Failed
              ("UNEXPECTED EXCEPTION RAISED BY " & "INTERCHANGING LARGE '+'");
      end;

      begin
         F5 := Ident (Float5'Base'First) + Float5'Base'First;

         Failed ("NO EXCEPTION RAISED BY SMALL '+'");

         if not Equal (F5, F5) then
            Comment ("DON'T OPTIMIZE F5");
         end if;
      exception
         when Constraint_Error =>
            null;
         when others =>
            Failed ("UNEXPECTED EXCEPTION RAISED BY SMALL '+'");
      end;

      -- AS ABOVE BUT INTERCHANGING '+' AND '-'
      begin
         F5 := Ident (Float5'Base'First) - Float5'Base'First;

         if not Equal (F5, F5) then
            Comment ("DON'T OPTIMIZE F5");
         end if;
      exception
         when Constraint_Error =>
            Failed ("CONSTRAINT_ERROR " & "RAISED BY INTERCHANGING SMALL '+'");
         when others =>
            Failed
              ("UNEXPECTED EXCEPTION RAISED BY " & "INTERCHANGING SMALL '+'");
      end;

      begin
         F5 := Ident (Float5'Base'Last) - Float5'Base'First;

         Failed ("NO EXCEPTION RAISED BY LARGE '-'");

         if not Equal (F5, F5) then
            Comment ("DON'T OPTIMIZE F5");
         end if;
      exception
         when Constraint_Error =>
            null;
         when others =>
            Failed ("UNEXPECTED EXCEPTION RAISED BY LARGE '-'");
      end;

      -- AS ABOVE BUT INTERCHANGING '+' AND '-'
      begin
         F5 := Ident (Float5'Base'Last) + Float5'Base'First;

         if not Equal (F5, F5) then
            Comment ("DON'T OPTIMIZE F5");
         end if;
      exception
         when Constraint_Error =>
            Failed ("CONSTRAINT_ERROR " & "RAISED BY INTERCHANGING LARGE '-'");
         when others =>
            Failed
              ("UNEXPECTED EXCEPTION RAISED BY " & "INTERCHANGING LARGE '-'");
      end;

      begin
         F5 := Ident (Float5'Base'First) - Float5'Base'Last;

         Failed ("NO EXCEPTION RAISED BY SMALL '-'");

         if not Equal (F5, F5) then
            Comment ("DON'T OPTIMIZE F5");
         end if;
      exception
         when Constraint_Error =>
            null;
         when others =>
            Failed ("UNEXPECTED EXCEPTION RAISED BY SMALL '-'");
      end;

      -- AS ABOVE BUT INTERCHANGING '+' AND '-'
      begin
         F5 := Ident (Float5'Base'First) + Float5'Base'Last;

         if not Equal (F5, F5) then
            Comment ("DON'T OPTIMIZE F5");
         end if;
      exception
         when Constraint_Error =>
            Failed ("CONSTRAINT_ERROR " & "RAISED BY INTERCHANGING SMALL '-'");
         when others =>
            Failed
              ("UNEXPECTED EXCEPTION RAISED BY " & "INTERCHANGING SMALL '-'");
      end;

   end if;

   Result;

end C45322a;
