--==================================================================--

package body Ca11015_0 is

   procedure Initialize_Basic_Map (Map : in out Map_Type) is
   -- Not a real initialization.  Real application can use geographic
   -- database to create the basic map.
   begin
      for I in Latitude'First .. Latitude'Last loop
         for J in 1 .. 2 loop
            Map (I, J) := Unexplored;
         end loop;
         for J in 3 .. 4 loop
            Map (I, J) := Desert;
         end loop;
         for J in 5 .. 7 loop
            Map (I, J) := Plains;
         end loop;
      end loop;

   end Initialize_Basic_Map;
   ---------------------------------------------------
   function Get_Physical_Feature
     (Lat  : Latitude;
      Long : Longitude;
      Map  : Map_Type) return Physical_Features
   is
   begin
      return (Map (Lat, Long));
   end Get_Physical_Feature;
   ---------------------------------------------------
   function Next_Page return Page_Type is
   begin
      Page := Page + 1;
      return (Page);
   end Next_Page;

---------------------------------------------------
begin -- CA11015_0
   -- Initialize a basic map.
   Initialize_Basic_Map (Basic_Map);

end Ca11015_0;
