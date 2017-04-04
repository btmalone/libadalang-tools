-- C761013.A
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
--
-- OBJECTIVE:
--    Check that a function call renamed as an object is not finalized until
--    the unit or block that directly contains the renaming is left.
--
--    Check that a renaming of an object is not finalized too soon
--    (which an object declared at the place of a renaming would be).
--
-- TEST DESCRIPTION:
--    We check specifically that the renaming is not finalized too early.
--    In particular, we check that the accessibility of the renaming is
--    that of the renamed view; if the object has a longer lifetime than
--    the master in which it is nested, the renaming is not finalized.
--    OTOH, when renaming a function call, the return object of that call
--    is finalized when the enclosing master is finalized. That's true
--    even when a single component is renamed, because the master of the
--    return object is that enclosing the function_call (not the call itself)
--    and for renamed function_call component, the function_call is a master,
--    but the entire name is not a master (it is not an expression) [this
--    is different for an initialized object declaration].
--
-- CHANGE HISTORY:
--    25 Jan 2001   PHL   Initial version.
--    19 Sep 2007   RLB   Converted to ACATS 3,0 test, added additional
--                        test cases.
--
--!

with Ada.Finalization; use Ada.Finalization;
package C761013_0 is

   type Ctrl is new Controlled with record
      C         : Integer := 15;
      Finalized : Boolean := False;
   end record;

   procedure Initialize (Obj : in out Ctrl);

   procedure Finalize (Obj : in out Ctrl);

   function F return Ctrl;

   type User is record
      Component : Ctrl;
   end record;

   function U return User;

end C761013_0;
