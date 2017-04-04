-- C3A2A02.A
--
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
--
-- OBJECTIVE:
--      Check that, for X'Access of a general access type A, Program_Error is
--      raised if the accessibility level of X is deeper than that of A.
--      Check for cases where X'Access occurs in an instance body, and A
--      is a type either declared inside the instance, or declared outside
--      the instance but not passed as an actual during instantiation.
--
-- TEST DESCRIPTION:
--      In order to satisfy accessibility requirements, the designated
--      object X must be at the same or a less deep nesting level than the
--      general access type A -- X must "live" as long as A. Nesting
--      levels are the run-time nestings of masters: block statements;
--      subprogram, task, and entry bodies; and accept statements. Packages
--      are invisible to accessibility rules.
--
--      This test declares three generic packages:
--
--         (1) One in which X is of a formal tagged derived type and declared
--             in the body, A is a type declared outside the instance, and
--             X'Access occurs in the declarative part of a nested subprogram.
--
--         (2) One in which X is a formal object of a tagged type, A is a
--             type declared outside the instance, and X'Access occurs in the
--             declarative part of the body.
--
--         (3) One in which there are two X's and two A's. In the first pair,
--             X is a formal in object of a tagged type, A is declared in the
--             specification, and X'Access occurs in the declarative part of
--             the body. In the second pair, X is of a formal derived type,
--             X and A are declared in the specification, and X'Access occurs
--             in the sequence of statements of the body.
--
--      The test verifies the following:
--
--         For (1), Program_Error is raised when the nested subprogram is
--         called, if the generic package is instantiated at a deeper level
--         than that of A. The exception is propagated to the innermost
--         enclosing master. Also, check that Program_Error is not raised
--         if the instantiation is at the same level as that of A.
--
--         For (2), Program_Error is raised upon instantiation if the object
--         passed as an actual during instantiation has an accessibility level
--         deeper than that of A. The exception is propagated to the innermost
--         enclosing master. Also, check that Program_Error is not raised if
--         the level of the actual object is not deeper than that of A.
--
--         For (3), Program_Error is not raised, for actual objects at
--         various accessibility levels (since A will have at least the same
--         accessibility level as X in all cases, no exception should ever
--         be raised).
--
-- TEST FILES:
--      The following files comprise this test:
--
--         F3A2A00.A
--      -> C3A2A02.A
--
--
-- CHANGE HISTORY:
--      12 May 95   SAIC    Initial prerelease version.
--      10 Jul 95   SAIC    Modified code to avoid dead variable optimization.
--      26 Jun 98   EDS     Added pragma Elaborate (C3A2A02_0) to package
--                          package C3A2A02_3, in order to avoid possible
--                          instantiation error.
--!

with F3a2a00;
generic
   type Fd is new F3a2a00.Tagged_Type with private;
package C3a2a02_0 is
   procedure Proc;
end C3a2a02_0;
