-- CE2109A.ADA

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
--     CHECK THAT THE DEFAULT MODES IN CREATE ARE SET CORRECTLY FOR
--     SEQUENTIAL_IO.

-- APPLICABILITY CRITERIA:
--     THIS TEST IS ONLY APPLICABLE TO IMPLEMENTATIONS WHICH SUPPORT
--     CREATE WITH OUT_FILE MODE FOR SEQUENTIAL FILES.

-- HISTORY:
--     ABW 08/13/82
--     SPS 11/09/82
--     JBG 11/11/83
--     TBN 02/13/86  SPLIT TEST.  PUT DIRECT_IO INTO CE2109B.ADA AND
--                   TEXT_IO INTO CE2109C.ADA.
--     TBN 11/04/86  REVISED TEST TO OUTPUT A NON_APPLICABLE
--                   RESULT WHEN FILES ARE NOT SUPPORTED.
--     DWC 08/12/87  CHANGED NOT_APPLICABLE MESSAGE, REMOVED
--                   NAME_ERROR, AND CLOSED THE FILE.

with Report; use Report;
with Sequential_Io;

procedure Ce2109a is

   Incomplete : exception;
   package Seq is new Sequential_Io (Integer);
   use Seq;
   File2 : Seq.File_Type;

begin

   Test ("CE2109A", "CHECK DEFAULT MODE IN CREATE FOR SEQ_IO");

   begin
      Create (File2);
   exception
      when Use_Error =>
         Not_Applicable
           ("CREATE OF SEQUENTIAL FILE WITH " & "OUT_FILE MODE NOT SUPPORTED");
         raise Incomplete;
      when others =>
         Failed ("UNEXPECTED EXCEPTION RAISED; SEQUENTIAL " & "CREATE");
         raise Incomplete;
   end;

   if Mode (File2) /= Out_File then
      Failed ("MODE INCORRECTLY SET FOR SEQUENTIAL_IO");
   end if;

   Close (File2);

   Result;

exception
   when Incomplete =>
      Result;

end Ce2109a;
