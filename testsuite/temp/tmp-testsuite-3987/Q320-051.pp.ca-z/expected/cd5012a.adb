-- CD5012A.ADA

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
--     CHECK THAT AN ADDRESS CLAUSE CAN BE GIVEN FOR A VARIABLE OF AN
--     ENUMERATION TYPE IN THE DECLARATIVE PART OF A GENERIC SUBPROGRAM.

-- HISTORY:
--     DHH 09/15/87  CREATED ORIGINAL TEST.
--     PWB 05/11/89  CHANGED EXTENSION FROM '.DEP' TO '.ADA'.

with System; use System;
with Report; use Report;
with Spprt13;
procedure Cd5012a is

begin

   Test
     ("CD5012A",
      "AN ADDRESS CLAUSE CAN BE " &
      "GIVEN FOR A VARIABLE OF AN ENUMERATION " &
      "TYPE IN THE DECLARATIVE PART OF A " &
      "GENERIC SUBPROGRAM");

   declare
      type Non_Char is (Red, Blue, Green);

      Color    : Non_Char;
      Test_Var : Address := Color'Address;

      generic
      procedure Genproc;

      procedure Genproc is

         Hue : Non_Char := Green;
         for Hue use at Spprt13.Variable_Address;
      begin
         if Equal (3, 3) then
            Hue := Red;
         end if;
         if Hue /= Red then
            Failed ("WRONG VALUE FOR VARIABLE IN " & "GENERIC PROCEDURE");
         end if;
         if Hue'Address /= Spprt13.Variable_Address then
            Failed ("WRONG ADDRESS FOR VARIABLE " & "IN GENERIC PROCEDURE");
         end if;
      end Genproc;

      procedure Proc is new Genproc;
   begin
      Proc;
   end;
   Result;
end Cd5012a;
