-- C760012.A
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
--      Check that record components that have per-object access discriminant
--      constraints are initialized in the order of their component
--      declarations, and after any components that are not so constrained.
--
--      Check that record components that have per-object access discriminant
--      constraints are finalized in the reverse order of their component
--      declarations, and before any components that are not so constrained.
--
-- TEST DESCRIPTION:
--      The type List_Item is the "container" type.  It holds two fields that
--      have per-object access discriminant constraints, and two fields that
--      are not discriminated.  These four fields are all controlled types.
--      A fifth field is a pointer used to maintain a linked list of these
--      data objects.  Each component is of a unique type which allows for
--      the test to simply track the order of initialization and finalization.
--
--      The types and their purpose are:
--        Constrained_First  - a controlled discriminated type
--        Constrained_Second - a controlled discriminated type
--        Simple_First       - a controlled type with no discriminant
--        Simple_Second      - a controlled type with no discriminant
--
--      The required order of operations:
--        Initialize
--          ( Simple_First | Simple_Second )   -- no "internal order" required
--          Constrained_First
--          Constrained_Second
--        Finalize
--          Constrained_Second
--          Constrained_First
--          ( Simple_First | Simple_Second )   -- must be inverse of init.
--
--
-- CHANGE HISTORY:
--      23 MAY 95   SAIC    Initial version
--      02 MAY 96   SAIC    Reorganized for 2.1
--      05 DEC 96   SAIC    Simplified for 2.1; added init/fin ordering check
--      31 DEC 97   EDS     Remove references to and uses of
--                          Initialization_Sequence
--!

---------------------------------------------------------------- C760012_0

with Ada.Finalization;
with Ada.Unchecked_Deallocation;
package C760012_0 is

   type List_Item;

   type List is access all List_Item;

   package Firsts is  -- distinguish first from second
      type Constrained_First
        (Container : access List_Item)
      is new Ada.Finalization.Limited_Controlled with
      null record;
      procedure Initialize (T : in out Constrained_First);
      procedure Finalize (T : in out Constrained_First);

      type Simple_First is new Ada.Finalization.Controlled with record
         My_Init_Seq_Number : Natural;
      end record;
      procedure Initialize (T : in out Simple_First);
      procedure Finalize (T : in out Simple_First);

   end Firsts;

   type Constrained_Second
     (Container : access List_Item)
   is new Ada.Finalization.Limited_Controlled with
   null record;
   procedure Initialize (T : in out Constrained_Second);
   procedure Finalize (T : in out Constrained_Second);

   type Simple_Second is new Ada.Finalization.Controlled with record
      My_Init_Seq_Number : Natural;
   end record;
   procedure Initialize (T : in out Simple_Second);
   procedure Finalize (T : in out Simple_Second);

   -- by 3.8(18);6.0 the following type contains components constrained
   -- by per-object expressions

   type List_Item is new Ada.Finalization.Limited_Controlled with record
      Contenta : Firsts.Constrained_First (List_Item'Access); -- C S
      Simplea  : Firsts.Simple_First;                          -- A T
      Simpleb  : Simple_Second;                                -- A T
      Contentb : Constrained_Second (List_Item'Access);       -- D R
      Next     : List;                                         -- | |
   end record;                                                -- | |
   procedure Initialize (L : in out List_Item); ------------------+ |
   procedure Finalize (L : in out List_Item); --------------------+

   -- the tags are the same for SimpleA and SimpleB due to the fact that
   -- the language does not specify an ordering with respect to this
   -- component pair. 7.6(12) does specify the rest of the ordering.

   procedure Deallocate is new Ada.Unchecked_Deallocation (List_Item, List);

end C760012_0;
