-- C54A24B.ADA

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
--     CHECK THAT NULL SUBTYPE RANGES ARE ACCEPTABLE CASE CHOICES,
--     WHERE THE BOUNDS ARE BOTH OUT OF THE SUBRANGE'S RANGE, AND
--     WHERE VACUOUS CHOICES HAVE NON-NULL STATEMENT SEQUENCES.
--     CHECK THAT AN UNNEEDED OTHERS CLAUSE IS PERMITTED.

-- HISTORY:
--     DAT 01/29/81 CREATED ORIGINAL TEST.
--     DHH 10/20/87 SHORTENED LINES CONTAINING MORE THAN 72 CHARACTERS.

with Report;
procedure C54a24b is

   use Report;

   type C is new Character range 'A' .. 'D';
   X : C := 'B';

begin
   Test
     ("C54A24B",
      "NULL CASE CHOICE SUBRANGES WITH VALUES " & "OUTSIDE SUBRANGE");

   case X is
      when C range C'Base'Last .. C'Base'First | C range 'Z' .. ' ' =>
         X := 'A';
      when C =>
         null;
      when others =>
         X := 'C';
   end case;
   if X /= 'B' then
      Failed ("WRONG CASE EXECUTION");
   end if;

   Result;
end C54a24b;
