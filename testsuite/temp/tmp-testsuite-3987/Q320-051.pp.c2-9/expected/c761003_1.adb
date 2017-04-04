-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --  C761003_1

with Tctouch;
with C761003_Support;
package body C761003_1 is

   package Sup renames C761003_Support;

   procedure Initialize (It : in out Global) is
   begin
      Sup.Inits_Called                   := Sup.Inits_Called + 1;
      It.Tag                             := Sup.Pick_Char;
      Sup.Inits_Order (Sup.Inits_Called) := It.Tag;
   end Initialize;

   procedure Finalize (It : in out Global) is
   begin
      Tctouch.Touch
        (It.Tag);  --------------------------------------------- Tag
   end Finalize;

   procedure Initialize (It : in out Second) is
   begin
      Sup.Inits_Called                   := Sup.Inits_Called + 1;
      It.Tag                             := Sup.Pick_Char;
      Sup.Inits_Order (Sup.Inits_Called) := It.Tag;
   end Initialize;

   procedure Finalize (It : in out Second) is
   begin
      Tctouch.Touch
        (It.Tag);  --------------------------------------------- Tag
   end Finalize;

end C761003_1;
