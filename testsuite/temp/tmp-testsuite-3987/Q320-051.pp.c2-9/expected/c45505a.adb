-- C45505A.ADA

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
-- CHECK THAT MULTIPLICATION FOR INTEGER SUBTYPES YIELDS A RESULT
-- BELONGING TO THE BASE TYPE.

-- *** NOTE: This test has been modified since ACVC version 1.11 to    -- 9X
-- ***       remove incompatibilities associated with the transition   -- 9X
-- ***       to Ada 9X.                                                -- 9X

-- JBG 2/24/84
-- JRL 03/30/93 REMOVED NUMERIC_ERROR FROM TEST.

with Report; use Report;
procedure C45505a is

   type Int is range 1 .. 10;

   X, Y : Int := Int (Ident_Int (5));

begin

   Test ("C45505A", "CHECK SUBTYPE OF INTEGER MULTIPLICATION");

   begin

      if X * Y / 5 /= Int (Ident_Int (5)) then
         Failed ("INCORRECT RESULT");
      end if;

   exception

      when Constraint_Error =>
         if Int'Base'Last >= Int'Val (25) then
            Failed
              ("MULTIPLICATION DOES NOT YIELD RESULT " &
               "BELONGING TO THE BASE TYPE");
         else
            Comment ("BASE TYPE HAS RANGE LESS THAN 25");
         end if;
   end;

   Result;

end C45505a;
