-- F433A00.A
--
--                             Grant of Unlimited Rights
--
--     AdaCore holds unlimited rights in the software and documentation
--     contained herein. Unlimited rights are the same as those granted
--     by the U.S. Government for older parts of the Ada Conformity
--     Assessment Test Suite, and are defined in DFAR 252.227-7013(a)(19).
--     By making this public release, AdaCore intends to confer upon all
--     recipients unlimited rights equal to those held by the Ada Conformity
--     Assessment Authority. These rights include rights to use, duplicate,
--     release or disclose the released technical data and computer software
--     in whole or in part, in any manner and for any purpose whatsoever,
--     and to have or permit others to do so.
--
--                                    DISCLAIMER
--
--     ALL MATERIALS OR INFORMATION HEREIN RELEASED, MADE AVAILABLE OR
--     DISCLOSED ARE AS IS. ADACORE MAKES NO EXPRESS OR IMPLIED WARRANTY AS
--     TO ANY MATTER WHATSOEVER, INCLUDING THE CONDITIONS OF THE SOFTWARE,
--     DOCUMENTATION OR OTHER INFORMATION RELEASED, MADE AVAILABLE OR
--     DISCLOSED, OR THE OWNERSHIP, MERCHANTABILITY, OR FITNESS FOR A
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
--
--     This foundation is based on one submitted by AdaCore; AdaCore retains
--     the copyright on the foundation.
--*
--
-- FOUNDATION DESCRIPTION:
--      This foundation declares limited types, operations, and objects
--      for use in tests checking the use of limited components in array
--      aggregates.
--
-- CHANGE HISTORY:
--      2 Feb 2004 JM  Initial Version.
--     19 Sep 2007 RLB Created foundation to reduce duplicate code,
--                     added cases, and made test self-checking.
--
with Ada.Finalization;
package F433a00 is
   --  Protected object and Task types used to check that limited
   --  components are properly initialized (and thus are fully
   --  operational).

   protected type T_Po is
      entry Set (Value : in Integer);
      procedure Get (Value : out Integer);
   private
      Data : Integer := 0;
   end T_Po;

   task type T_Task is
      entry Set (Value : in Integer);
      entry Get (Value : out Integer);
   end T_Task;

   -- Record to check the number of times a component is initialized.

   procedure Reset_Init;

   function Init_Func (Value : in Integer := 4) return Integer;

   procedure Check_Init_Count (Expected : in Natural; Message : in String);

   type Lim_Rec is limited record
      A : Integer   := Init_Func;
      C : Character := 'Z';
   end record;

   type My_Rec is record
      Info : Lim_Rec := (A => <>, C => 'A'); --  limited component
      P    : T_Po;                           --  limited component
      T    : T_Task;                         --  limited component
   end record;

   procedure Check
     (Item    : in out My_Rec;
      Value   : in     Integer;
      Message : in     String);

   type Ctrl_Rec is new Ada.Finalization.Controlled with record
      Info : Integer := 33;
   end record;

   procedure Initialize (Obj : in out Ctrl_Rec);

   type Acc_Nlrec is access all Ctrl_Rec;

   type Arr_Nlrec is array (1 .. 4) of Ctrl_Rec;

end F433a00;
