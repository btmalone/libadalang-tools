with Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;

with GNAT.Directory_Operations;

pragma Warnings (Off); -- ????????????????
with GNATCOLL.Projects; use GNATCOLL.Projects;
with GNATCOLL.VFS;      use GNATCOLL.VFS;
with GNATCOLL.Projects.Aux;
with GNATCOLL.Traces;
pragma Warnings (On);

with LAL_UL.Common;     use LAL_UL.Common;
with LAL_UL.Formatted_Output;
with LAL_UL.Tool_Names; use LAL_UL.Tool_Names;
with LAL_UL.Utils;      use LAL_UL.Utils;

package body LAL_UL.Projects is

   pragma Warnings (Off); -- ????????????????
   use Common_Flag_Switches, Common_String_Switches,
     Common_String_Seq_Switches, Common_Nat_Switches;
   pragma Warnings (On);

   function Project_File_Name (Cmd : Command_Line) return String with
      Pre => Arg (Cmd, Project_File) /= null;
      --  Returns the project file name with ".gpr" appended if necessary

   function Main_Unit_Name
     (Cmd : Command_Line) return String_Ref is
     (if
        Arg (Cmd, Update_All)
      then
        (if Num_File_Names (Cmd) = 0 then null else File_Names (Cmd) (1))
      else null);
   --  If "-U main_unit" was specified, this returns the main unit. Otherwise
   --  (-U was not specified, or was specified without a main unit name),
   --  returns null.

   procedure Recompute_View_Errors (S : String);
   --  Print out all errors but the warnings about missing directories.

   function Needed_For_Tree_Creation (Option : String) return Boolean;
   --  Checks if the argument is the compilation option that is needed for tree
   --  creation

   procedure Process_Project
     (Cmd                       : in out Command_Line;
      Project_Switches_Text     :    out Argument_List_Access;
      Global_Report_Dir         :    out String_Ref;
      Compiler_Options          :    out String_List_Access;
      Project_RTS               :    out String_Access;
      Individual_Source_Options :    out String_String_List_Map;
      Result_Dirs               :    out String_String_Map;
      Needs_Per_File_Output     :        Boolean;
      My_Project                : in out Project_Tree;
      Tool_Package_Name         :        String;
      Compute_Project_Closure   :        Boolean;
      Callback                  :        Parse_Callback;
      Tool_Temp_Dir             :        String);

   function Project_File_Name (Cmd : Command_Line) return String is
      Name : String renames Arg (Cmd, Project_File).all;
      Ext : constant String :=
        (if Has_Suffix (Name, Suffix => ".gpr") then "" else ".gpr");
   begin
      return Name & Ext;
   end Project_File_Name;

   procedure Read_File_Names_From_File
     (Cmd           : in out Command_Line;
      Par_File_Name :        String);
   --  ????????????????Should replace Read_Args_From_File

   ------------------------------
   -- Needed_For_Tree_Creation --
   ------------------------------

   function Needed_For_Tree_Creation (Option : String) return Boolean is
      Result    : Boolean          := False;
      First_Idx : constant Natural := Option'First;
   begin
      --  a simple prototype for the moment, to be completed...
      if Option = "-gnat83"
        or else Option = "-gnat95"
        or else Option = "-gnat05"
        or else Option = "-gnat12"
        or else Option = "-gnatdm"
        or else Option = "-gnatd.V"
        or else
        (Option'Length >= 10
         and then Option (First_Idx .. First_Idx + 6) = "-gnateD")
        or else Option = "-gnatI"
        or else
        (Option'Length >= 7
         and then Option (First_Idx .. First_Idx + 5) = "--RTS=")

--        or else
--         Option = ""
      then
         Result := True;
      end if;

      return Result;
   end Needed_For_Tree_Creation;

   ---------------------------
   -- Recompute_View_Errors --
   ---------------------------

   procedure Recompute_View_Errors (S : String) is
   begin
      if Index (S, "warning") /= 0
        and then Index (S, "directory") /= 0
        and then Index (S, "not found") /= 0
      then
         return;
      else
         Put_Line (S);
         --  ????????????????Raise?
      end if;
   end Recompute_View_Errors;

   procedure Process_Project
     (Cmd                       : in out Command_Line;
      Project_Switches_Text     :    out Argument_List_Access;
      Global_Report_Dir         :    out String_Ref;
      Compiler_Options          :    out String_List_Access;
      Project_RTS               :    out String_Access;
      Individual_Source_Options :    out String_String_List_Map;
      Result_Dirs               :    out String_String_Map;
      Needs_Per_File_Output     :        Boolean;
      My_Project : in out Project_Tree; -- My_Project_Tree????????????????
      Tool_Package_Name         :        String;
      Compute_Project_Closure   :        Boolean;
      Callback                  :        Parse_Callback;
      Tool_Temp_Dir             :        String)
   is
      Project_Env : Project_Environment_Access;

      use String_Access_Vectors;
      Compiler_Options_Vector : String_Access_Vector;

      procedure Initialize_Environment;
      --  Initializes the environment for extracting the information from the
      --  project file. This includes setting the parameters specific to the
      --  given tool version assuming that the tools for cross environment are
      --  named in a standard way (that is, <cross-prefix>-<tool_name>).

      function Is_Ada_File (File : Virtual_File) return Boolean;
      --  Checks if the given source file is an Ada file.

      function Is_Externally_Built (File : Virtual_File) return Boolean;
      --  Checks if the given source file belongs to an externally build
      --  library.

      procedure Load_Tool_Project;
      --  Does the same as GNATCOLL.Projects.Load, the only difference is that
      --  all the parameters except the project are hidden. This procedure
      --  never generates any error or warning message, because here we do
      --  not know values of external variables. ????????????????Inspect all
      --  comments below.

      procedure Get_Files_From_Binder_Output;
      --  Provided that the tool arguments contain '-U main_unit' parameter,
      --  tries to get the full closure of main_unit and to store it as tool
      --  argument files. This procedure assumes that: * the tool temporary
      --  directory has already been created; * we are in the directory the
      --  tool has been called from

      procedure Get_Sources_From_Project;
      --  Extracts and stores the list of sources of the project to process as
      --  tool arguments.
      --
      --  More documentation is needed:
      --
      --  * when we extract the sources from the project * what happens when
      --    o there is no -U option
      --    o -U option is specified, but without the main unit
      --    o -U option is specified with the main unit name
      --
      --  ??? Extended projects???

      procedure Set_External_Values;
      --  For each value of an external variable that has been stored as a
      --  result of the initial parameter processing, checks that the given
      --  variable indeed is defined in the project, and the value specified
      --  for it is the valid value for this variable. If both checks are
      --  successful sets the given value as the value of a given variable,
      --  otherwise raises Parameter_Error. If all the stored pairs of external
      --  variable names and corresponding values are successfully processed,
      --  recomputes the view of the project with these values of external
      --  variables.

      procedure Extract_Compilation_Attributes;
      --  Extracts and stores as compiler options the attributes that may be
      --  needed to call the compiler from the tool to create the tree.
      --
      --  This extracts and stores options corresponding to the following
      --  attributes:
      --     Builder.Global_Configuration_Pragmas
      --     Builder.Global_Config_File
      --     Compiler.Local_Configuration_Pragmas
      --     Compiler.Local_Config_File
      --
      --  ??? Should we extract anything more then global configuration file
      --  here???

      procedure Extract_Tool_Options;
      --  Extracts tool attributes from the project file. The default does the
      --  following: * if there is exactly one source file specified, tries to
      --  get the
      --    tool options from the Switches attribute with the corresponding
      --    index. If there is no such Switches attribute, tries to get tool
      --    attributes from the Default_Switches attribute.
      --  * otherwise tries to get the tool attributes from the
      --    Default_Switches attribute.

      procedure Create_Configuration_File;
      procedure Create_Mapping_File;
      --  Create the configuration/mapping file for the project and adds the
      --  corresponding option to the list of options used to create the tree.
      --
      --  These procedures form the important parameters for the
      --  compiler call to create the tree, so the caller should call to
      --  ASIS_US.Compiler_Options.Set_Arg_List after the calls to these
      --  subprograms.????????????????

      procedure Set_Global_Result_Dirs;
      --  Sets the directory to place the global tool results into.

      procedure Set_Individual_Source_Options;
      --  Also for each file from the project that is a tool argument computes
      --  and stores in the source table the list of compiler options needed
      --  to create the tree for this particular file. It also defines the
      --  directory the file-specific results of the tool should be placed
      --  into. This procedure should be called *after* storing the argument
      --  files in the source table. It is NOT a part of the actions combined
      --  in Process_Project_File procedure.????????????????

      ----------------------------
      -- Initialize_Environment --
      ----------------------------

      procedure Initialize_Environment is
      begin
         GNATCOLL.Traces.Parse_Config_File;
         Initialize (Project_Env);

         Project_Env.Set_Target_And_Runtime
           (Target, Arg (Cmd, Run_Time_System).all);

         if Arg (Cmd, Follow_Symbolic_Links) then
            Project_Env.Set_Trusted_Mode (True);
         end if;

         Set_Automatic_Config_File (Project_Env.all);
      end Initialize_Environment;

      -----------------------
      -- Load_Tool_Project --
      -----------------------

      procedure Load_Tool_Project is
         procedure Errors (S : String);
         procedure Errors (S : String) is
         begin
            if Index (S, " not a regular file") /= 0 then
               Cmd_Error
                 ("project file " & Project_File_Name (Cmd) & " not found");
            else
               Cmd_Error (S);
            end if;
         end Errors;
      begin
         My_Project.Load
         (GNATCOLL.VFS.Create
            (+Project_File_Name (Cmd)), Project_Env, Errors =>
            Errors'Unrestricted_Access, Recompute_View      =>
            False);
         --  Report_Missing_Dirs => False????????????????

         if Is_Aggregate_Project (My_Project.Root_Project) then
            Cmd_Error ("aggregate projects are not supported");
         end if;
      exception
         when Invalid_Project =>
            Cmd_Error (Project_File_Name (Cmd) & ": invalid project");
      end Load_Tool_Project;

      -----------------
      -- Is_Ada_File --
      -----------------

      function Is_Ada_File (File : Virtual_File) return Boolean is
         use Ada.Characters.Handling;
      begin
         return To_Lower (Language (Info (My_Project, File))) = "ada";
      end Is_Ada_File;

      -------------------------
      -- Is_Externally_Built --
      -------------------------

      function Is_Externally_Built (File : Virtual_File) return Boolean is
         F_Info : constant File_Info            := Info (My_Project, File);
         Proj   : constant Project_Type         := Project (F_Info);
         Attr   : constant Attribute_Pkg_String :=
           Build ("", "externally_built");
      begin
         if Has_Attribute (Proj, Attr) then
            if Attribute_Value (Proj, Attr) = "true" then
               return True;
            end if;
         end if;
         return False;
      end Is_Externally_Built;

      ------------------------------------
      -- Get_Files_From_Binder_Output --
      ------------------------------------

      procedure Get_Files_From_Binder_Output is
         Command : String_Access;
         Return_Code : Integer;

         Bind_Out_File_Name : constant String := Tool_Temp_Dir & ".bind_out";
         Success            : Boolean;

         Max_Str_Len : constant Positive := 1_024;
         Str_Buff    : String (1 .. Max_Str_Len);
         Str_Len     : Natural;

         Builder_Options : String_Access_Vector;
         Program_Output_File : File_Type;
      --  File used to redirect the program output into.

      begin
         --  Define the name of the command to call:
         Command := Locate_Exec_On_Path ("gprbuild");

         Append (Builder_Options, new String'("-f"));
         Append (Builder_Options, new String'("-q"));
         Append (Builder_Options, new String'("-b"));

         if Target /= "" then
            Append (Builder_Options, new String'("--target=" & Target));
         end if;

         Append (Builder_Options, new String'("-P"));
         Append (Builder_Options, new String'(Arg (Cmd, Project_File).all));

         declare
            X_Vars : constant String_Ref_Array := Arg (Cmd, External_Variable);
         begin
            for X of X_Vars loop
               Append (Builder_Options, new String'("-X" & X.all));
            end loop;
         end;

         if Arg (Cmd, Run_Time_System).all /= "" then
            Append (Builder_Options,
                    new String'("--RTS=" & Arg (Cmd, Run_Time_System).all));
         end if;

         Append (Builder_Options, new String'("-gnatws"));

         Append (Builder_Options, new String'(Main_Unit_Name (Cmd).all));

         Append (Builder_Options, new String'("-bargs"));

         Append (Builder_Options, new String'("-ws"));
         Append (Builder_Options, new String'("-R"));
         Append (Builder_Options, new String'("-Z"));

         if ASIS_UL.Debug.Debug_Flag_C then
--            Info_No_EOL (Command.all);
--            Info_No_EOL (" ");
--
--            for J in 1 .. Tool_Switches.Last loop
--               Info_No_EOL (Tool_Switches.Table (J).all);
--               Info_No_EOL (" ");
--            end loop;
            raise Program_Error; -- ????
         end if;

         Spawn
           (Program_Name => Command.all,
            Args         => To_Array (Builder_Options),
            Output_File  => Bind_Out_File_Name,
            Success      => Success,
            Return_Code  => Return_Code,
            Err_To_Out   => False);

         --  Read source files

         if Success and then Return_Code = 0 then

            Open (Program_Output_File, In_File, Bind_Out_File_Name);

            --  We first need to erase the Main_Unit_Name from the command
            --  line, because we're about to append the actual files.
            --  Otherwise, if the Main_Unit_Name is "foo.adb", it would be
            --  duplicated, and if it's "foo", then we would try to read
            --  "foo" (possibly an executable file) as an Ada source file:
            Clear_File_Names (Cmd);

            while not End_Of_File (Program_Output_File) loop
               Get_Line (Program_Output_File, Str_Buff, Str_Len);
               Append_File_Name (Cmd, Trim (Str_Buff (1 .. Str_Len), Both));
            end loop;

            Close (Program_Output_File);
         else
            Cmd_Error ("could not get closure of " & Main_Unit_Name (Cmd).all);
         end if;

         --  Clean-up
         Free (Command);

         if not ASIS_UL.Debug.Debug_Flag_N then
            Delete_File (Bind_Out_File_Name, Success);
         end if;

      exception
         when others =>
            if Is_Open (Program_Output_File) then
               Close (Program_Output_File);
            end if;

            if ASIS_UL.Debug.Debug_Flag_N then
               Delete_File (Bind_Out_File_Name, Success);
            end if;

            raise;
      end Get_Files_From_Binder_Output;

      ------------------------------
      -- Get_Sources_From_Project --
      ------------------------------

      procedure Get_Sources_From_Project is
         Prj   : Project_Type;
         Files : File_Array_Access;
--         Success  : Boolean := False;

         Num_Names : constant Natural := Num_File_Names (Cmd);
         --  Number of File_Names on the command line
         Num_Files_Switches : constant Natural :=
           Arg_Length (Cmd, Common.Files);
         --  Number of "-files=..." switches on the command line
         Argument_File_Specified : constant Boolean :=
           (if Arg (Cmd, Update_All) then Num_Files_Switches > 0
            else Num_Names > 0 or else Num_Files_Switches > 0);
      --  True if we have source files specified on the command line. If -U
      --  (Update_All) was specified, then the "file name" (if any) is taken
      --  to be the main unit name, not a file name.

      begin
         if Arg (Cmd, Update_All) and then Num_Names > 1 then
            Cmd_Error ("cannot specify more than one main after -U");
         end if;

         --  We get file names from the project file if Compute_Project_Closure
         --  is True, and no file names were given on the command line, either
         --  directly, or via one or more "-files=par_file_name" switches.

         if Compute_Project_Closure and then not Argument_File_Specified then
            if Main_Unit_Name (Cmd) = null then
               Prj := My_Project.Root_Project;

               Files := Prj.Source_Files (Recursive => Arg (Cmd, Update_All));

               for F in Files'Range loop
                  if not Is_Externally_Built (Files (F))
                    and then Is_Ada_File (Files (F))
                  then
                     Append_File_Name (Cmd, Files (F).Display_Base_Name);
                     --  No need to call Callback for non-switches
                  end if;
               end loop;

               if Arg (Cmd, Update_All) then
                  if Num_File_Names (Cmd) = 0 then
                     Cmd_Error
                       (Project_File_Name (Cmd) &
                        "does not contain source files");
                  end if;
               else
                  loop
                     Prj := Extended_Project (Prj);
                     exit when Prj = No_Project;

                     Unchecked_Free (Files);
                     Files := Prj.Source_Files (Recursive => False);

                     for F in Files'Range loop
                        if not Is_Externally_Built (Files (F))
                          and then Is_Ada_File (Files (F))
                        then
                           Append_File_Name (Cmd, Files (F).Display_Base_Name);
                        end if;
                     end loop;
                  end loop;

               end if;

            else
               Get_Files_From_Binder_Output;
            end if;
         end if;
      end Get_Sources_From_Project;

      -------------------------
      -- Set_External_Values --
      -------------------------

      procedure Set_External_Values is
         Vars   : Scenario_Variable_Array   := My_Project.Scenario_Variables;
         X_Vars : constant String_Ref_Array := Arg (Cmd, External_Variable);
--         Vars : Scenario_Variable_Array := My_Project.Scenario_Variables;
--         use X_Vars_Sets;
--         C        : Cursor;
--         Next_Var : X_Var_Record;
      begin
         for X of X_Vars loop
            --  X is of the form "VAR=value"

            declare
               pragma Assert (X'First = 1);
               Equal : constant Natural := Index (X.all, "=");
               X_Var : String renames X (1 .. Equal - 1);
               X_Val : String renames X (Equal + 1 .. X'Last);
            begin
               if Equal = 0 then -- "=" not found (????say so)
                  Cmd_Error ("wrong parameter of -X option: " & X.all);
               end if;

               for V of Vars loop
                  if X_Var = External_Name (V) then
                     declare
                        Pos_Vals : constant String_List :=
                          My_Project.Possible_Values_Of (V);
                        Present : Boolean := False;
                     begin
                        for Pos_Val of Pos_Vals loop
                           if X_Val = Pos_Val.all then
                              Present := True;
                              exit;
                           end if;
                        end loop;

                        if not Present then
                           Cmd_Error
                             ("value " & X_Val & " is illegal for " & X_Var);
                        end if;

                     end;

                     Set_Value (V, X_Val);
                     exit;

                  else
                     null; -- ????????????????Cmd_Error?
                  end if;
               end loop;
            end;
         end loop;

         My_Project.Change_Environment (Vars);
         My_Project.Recompute_View
         (Errors => Recompute_View_Errors'Unrestricted_Access);
      end Set_External_Values;

      ------------------------------------
      -- Extract_Compilation_Attributes --
      ------------------------------------

      procedure Extract_Compilation_Attributes is
         Proj      : Project_Type := My_Project.Root_Project;
         Attr_Proj : Project_Type;

         --  Attributes to check:
         Builder_Global_Configuration_Pragmas : constant Attribute_Pkg_String
           := Build (Builder_Package, "Global_Configuration_Pragmas");
         Builder_Global_Config_File : constant Attribute_Pkg_String
           := Build (Builder_Package, "Global_Config_File");

         Needs_RTS : Boolean := False;
      begin
         if Has_Attribute (Proj, Builder_Global_Configuration_Pragmas) then
            Attr_Proj :=
              Attribute_Project
                (Project   => Proj,
                 Attribute => Builder_Global_Configuration_Pragmas);

            declare
               Attr_Val : constant String :=
                 Attribute_Value (Proj, Builder_Global_Configuration_Pragmas);
            begin
               Append
                 (Compiler_Options_Vector,
                  new String'
                    ("-gnatec=" &
                     Normalize_Pathname
                       (Name      => Attr_Val,
                        Directory =>
                          GNAT.Directory_Operations.Dir_Name
                            (Display_Full_Name (Project_Path (Attr_Proj))))));
            end;
         end if;

         if Has_Attribute (Proj, Builder_Global_Config_File, "ada") then
            Attr_Proj :=
              Attribute_Project
                (Project   => Proj,
                 Index     => "ada",
                 Attribute => Builder_Global_Config_File);

            declare
               Attr_Val : constant String :=
                 Attribute_Value (Proj, Builder_Global_Config_File, "ada");
            begin
               Append
                 (Compiler_Options_Vector,
                  new String'
                    ("-gnatec=" &
                     Normalize_Pathname
                       (Name      => Attr_Val,
                        Directory =>
                          GNAT.Directory_Operations.Dir_Name
                            (Display_Full_Name (Project_Path (Attr_Proj))))));
            end;
         end if;

         Needs_RTS := Has_Attribute (Proj, Runtime_Attribute, Index => "Ada");

         while not Needs_RTS and then Proj /= No_Project loop
            Proj      := Extended_Project (Proj);
            Needs_RTS :=
              Has_Attribute (Proj, Runtime_Attribute, Index => "Ada");
         end loop;

         if Needs_RTS then
            --  ???There is some code duplication with
            --  ASIS_UL.Compiler_Options.Get_Full_Path_To_RTS,
            --  needs refactoring
            declare
               Dirs : constant File_Array :=
                 Project_Env.Predefined_Object_Path;
               Idx : Natural;
            begin
               for J in Dirs'Range loop
                  Idx := Index (Dirs (J).Display_Full_Name, "adalib");

                  if Idx /= 0 then
                     declare
                        Result : constant String := Dirs (J).Display_Full_Name;
                        F_Idx  : constant Positive := Result'First;
                     begin
                        Append
                          (Compiler_Options_Vector,
                           new String'
                             ("--RTS=" &
                              Trim (Result (F_Idx .. Idx - 2), Both)));

                        Project_RTS := new String'(Get_Runtime (Proj));

                        goto Done;
                     end;
                  end if;
               end loop;

               Cmd_Error
                 ("cannot detect the full path to runtime " &
                  "from Runtime attribute");
               <<Done>>
               null;
            end;
         end if;
      end Extract_Compilation_Attributes;

      --------------------------
      -- Extract_Tool_Options --
      --------------------------

      procedure Extract_Tool_Options is
         Arg_File_Name : String_Access;

         Proj : constant Project_Type := Root_Project (My_Project);

         Attr_Switches : constant Attribute_Pkg_List :=
           Build (Tool_Package_Name, "Switches");
         Attr_Def_Switches : constant Attribute_Pkg_List :=
           Build (Tool_Package_Name, "Default_Switches");

         Attr_Indexes : String_List_Access;
         Index_Found  : Boolean := False;
      begin
         if Num_File_Names (Cmd) = 1 then
            --  ????What if the "one file" comes from -files=
            Arg_File_Name := new String'(File_Names (Cmd) (1).all);

            Attr_Indexes :=
              new String_List'(Attribute_Indexes (Proj, Attr_Switches));

            for J in Attr_Indexes'Range loop
               if Arg_File_Name.all = Attr_Indexes (J).all then
                  --  What about non-case-sensitive system?
                  Index_Found := True;
                  exit;
               end if;
            end loop;
         end if;

         if not Index_Found then
            --  We have to get tool options from Default_Sources

            if Has_Attribute (Proj, Attr_Def_Switches, "ada") then
               Project_Switches_Text :=
                 Attribute_Value (Proj, Attr_Def_Switches, "ada");
            end if;
         else
            if Has_Attribute (Proj, Attr_Switches) then
               Project_Switches_Text :=
                 Attribute_Value (Proj, Attr_Switches, Arg_File_Name.all);
            end if;
         end if;

         if Project_Switches_Text = null then
            Project_Switches_Text := new Argument_List'(1 .. 0 => <>);
         else
            Parse
              (Project_Switches_Text,
               Cmd,
               Phase              => Project_File,
               Callback           => Callback,
               Collect_File_Names => False);
            --  Collect_File_Names doesn't matter, because we're only parsing
            --  switches.
         end if;
      end Extract_Tool_Options;

      -------------------------------
      -- Create_Configuration_File --
      -------------------------------

      procedure Create_Configuration_File is
         use GNAT.Directory_Operations;
         Cur_Dir : constant String := Get_Current_Dir;
      begin
--         Change_Dir (Tool_Temp_Dir);
         --  Create it in the temp dir so it gets deleted at the end

         declare
            Config_Name : constant String :=
              GNATCOLL.Projects.Aux.Create_Config_Pragmas_File
                (My_Project.Root_Project);
         begin
            Append
              (Compiler_Options_Vector,
               new String'("-gnatec=" & Config_Name));
         end;

         Change_Dir (Cur_Dir);
      end Create_Configuration_File;

      -------------------------
      -- Create_Mapping_File --
      -------------------------

      procedure Create_Mapping_File is
         use GNAT.Directory_Operations;
         Cur_Dir : constant String := Get_Current_Dir;
      begin
--         Change_Dir (Tool_Temp_Dir);
         --  Create it in the temp dir so it gets deleted at the end

         declare
            Mapping_Name : constant String :=
              GNATCOLL.Projects.Aux.Create_Ada_Mapping_File
                (My_Project.Root_Project);
         begin
            Append
              (Compiler_Options_Vector,
               new String'("-gnatem=" & Mapping_Name));
         end;

         Change_Dir (Cur_Dir);
      end Create_Mapping_File;

      ----------------------------
      -- Set_Global_Result_Dirs --
      ----------------------------

      procedure Set_Global_Result_Dirs is
         Global_Report_Dir : Virtual_File;
      begin
         if not Arg (Cmd, No_Objects_Dir) then
            if Arg (Cmd, Subdirs) /= null then
               Set_Object_Subdir (Project_Env.all, +Arg (Cmd, Subdirs).all);
               Recompute_View
                 (My_Project,
                  Errors => Recompute_View_Errors'Unrestricted_Access);
            end if;

            Global_Report_Dir := My_Project.Root_Project.Object_Dir;

            if Global_Report_Dir = No_File then
               Global_Report_Dir := My_Project.Root_Project.Project_Path;
            end if;

            Process_Project.Global_Report_Dir :=
              new String'(Display_Dir_Name (Global_Report_Dir));
         end if;
      end Set_Global_Result_Dirs;

      -----------------------------------
      -- Set_Individual_Source_Options --
      -----------------------------------

      procedure Set_Individual_Source_Options is

         function Source_Result_Dir (Source_Prj : Project_Type) return String;
         --  Detects the path to the directory where the source-specific
         --  results for Source_File should be placed. Returns the object
         --  directory for the project the source belongs to (Source_Prj),
         --  it takes into account the effect of '--subdir=<dir>' option.
         --  ????????????????Way too complicated. Why not just return the
         --  obj dir? And then we can get rid of Needs_Per_File_Output.

         -----------------------
         -- Source_Result_Dir --
         -----------------------

         function Source_Result_Dir
           (Source_Prj : Project_Type) return String
         is
            Report_Dir : Virtual_File;
         begin
            Report_Dir := Source_Prj.Object_Dir;

            if Report_Dir = No_File then
               Report_Dir := My_Project.Root_Project.Project_Path;
            end if;

            return Display_Dir_Name (Report_Dir);
         end Source_Result_Dir;

         Sources : constant File_Array_Access :=
           My_Project.Root_Project.Source_Files (Recursive => True);

         Project_U   : Project_Type;
         Attr_Proj   : Project_Type;
         Source_Info : File_Info;
         Name        : String_Access;

         Sws        : String_List_Access;
         Is_Default : Boolean := False;

         File_Switches : String_Access_Vector;

         procedure Scan_Switches;
         --  Works on Sws as on a global object. Scans the argument, checks if
         --  the element being visited is needed for tree creation, and if it
         --  is, stores it in File_Switches.

         procedure Add_Switch (S : String);
         --  Adds S to File_Switches;

         Compiler_Local_Configuration_Pragmas : constant Attribute_Pkg_String
           := Build (Compiler_Package, "Local_Configuration_Pragmas");
         Compiler_Local_Config_File : constant Attribute_Pkg_String
           := Build (Compiler_Package, "Local_Config_File");

         procedure Add_Switch (S : String) is
         begin
            Append (File_Switches, new String'(S));
         end Add_Switch;

         procedure Scan_Switches is
         begin
            for J in Sws'Range loop
               if ASIS_UL.Debug.Debug_Flag_C then
                  Put (Sws (J).all & ' ');
               end if;

               if Needed_For_Tree_Creation (Sws (J).all) then
                  Add_Switch (Sws (J).all);
               end if;
            end loop;

            if ASIS_UL.Debug.Debug_Flag_C then
               if Is_Default then
                  Put ("(default)");
               end if;

               Put_Line ("");
            end if;

            Free (Sws);
         end Scan_Switches;

      begin
         for S in Sources'Range loop
            Source_Info := My_Project.Info (Sources (S));
            Project_U   := Project (Source_Info);
            Name        := new String'(Display_Base_Name (Sources (S)));

            if ASIS_UL.Debug.Debug_Flag_C then
               Put_Line ("Switches defined for " & Name.all);
            end if;

            Switches
              (Project          => Project_U,
               In_Pkg           => Compiler_Package,
               File             => Sources (S),
               Language         => "ada",
               Value            => Sws,
               Is_Default_Value => Is_Default);

            Scan_Switches;

            Switches
              (Project          => Project_U,
               In_Pkg           => Builder_Package,
               File             => Sources (S),
               Language         => "ada",
               Value            => Sws,
               Is_Default_Value => Is_Default);

            Scan_Switches;

            if not Arg (Cmd, Update_All)
              and then Has_Attribute
                (Project_U,
                 Compiler_Local_Configuration_Pragmas)
            then
               Attr_Proj :=
                 Attribute_Project
                   (Project   => Project_U,
                    Attribute => Compiler_Local_Configuration_Pragmas);
               declare
                  Attr_Val : constant String :=
                    Attribute_Value
                      (Project_U,
                       Compiler_Local_Configuration_Pragmas);
               begin
                  Add_Switch
                    ("-gnatec=" &
                     Normalize_Pathname
                       (Name      => Attr_Val,
                        Directory =>
                          GNAT.Directory_Operations.Dir_Name
                            (Display_Full_Name (Project_Path (Attr_Proj)))));
               end;
            end if;

            if not Arg (Cmd, Update_All)
              and then Has_Attribute
                (Project_U,
                 Compiler_Local_Config_File,
                 "ada")
            then
               Attr_Proj :=
                 Attribute_Project
                   (Project   => Project_U,
                    Attribute => Compiler_Local_Config_File,
                    Index     => "ada");

               declare
                  Attr_Val : constant String :=
                    Attribute_Value
                      (Project_U,
                       Compiler_Local_Config_File,
                       "ada");
               begin
                  Add_Switch
                    ("-gnatec=" &
                     Normalize_Pathname
                       (Name      => Attr_Val,
                        Directory =>
                          GNAT.Directory_Operations.Dir_Name
                            (Display_Full_Name (Project_Path (Attr_Proj)))));
               end;
            end if;

            if Is_Empty (File_Switches) then
               if ASIS_UL.Debug.Debug_Flag_C then
                  Put_Line ("No stored switches");
               end if;
            else
--               if ASIS_UL.Debug.Debug_Flag_C then
--                  Put_Line ("Stored switches " & File_Switches.all);
--               end if;

               Insert
                 (Individual_Source_Options,
                  Name,
                  new String_List'(To_Array (File_Switches)));
            end if;

            --  Defining the directory to place the file-specific results into:

            if not Arg (Cmd, No_Objects_Dir)
              and then Needs_Per_File_Output
            then
               Insert
                 (Result_Dirs,
                  Name,
                  new String'(Source_Result_Dir (Project_U)));
            end if;
         end loop;
      end Set_Individual_Source_Options;

   --  Start of processing for Process_Project

   begin
      --  ????????????????
      --  Process_Project_File has:
      --  Opt.Directories_Must_Exist_In_Projects := False; But that is
      --  apparently unnecessary (no tests fail if it is removed).

      --  Process_Project_File has:
      --  Register_Tool_Attributes (My_Project); which is needed for gnat2xml
      --  (LA17-020-gnat2xml_1).

      Initialize_Environment;
      Load_Tool_Project;
      Set_External_Values;
      Extract_Compilation_Attributes;
      Extract_Tool_Options;
      Get_Sources_From_Project;
      Create_Mapping_File;
      Create_Configuration_File;

      Set_Global_Result_Dirs;
      Set_Individual_Source_Options;

      Compiler_Options :=
        new Argument_List'(To_Array (Compiler_Options_Vector));
   end Process_Project;

   -------------------------
   -- Read_File_Names_From_File --
   -------------------------

   procedure Read_File_Names_From_File
     (Cmd           : in out Command_Line;
      Par_File_Name :        String)
   is
      Arg_File    : File_Type;
      Next_Ch     : Character;
      End_Of_Line : Boolean;

      function Get_File_Name return String;
      --  Reads from Par_File_Name the name of the next file (the file to read
      --  from should exist and be opened). Returns an empty string if there is
      --  no file names in Par_File_Name any more

      function Get_File_Name return String is
         File_Name_Buffer : String (1 .. 16 * 1_024);
         File_Name_Len    : Natural := 0;
      begin
         if not End_Of_File (Arg_File) then
            Get (Arg_File, Next_Ch);

            while Next_Ch in ' ' | ASCII.HT | ASCII.LF | ASCII.CR loop
               exit when End_Of_File (Arg_File);
               Get (Arg_File, Next_Ch);
            end loop;

            --  If we are here. Next_Ch is neither a white space nor
            --  end-of-line character. Two cases are possible, they
            --  require different processing:
            --
            --  1. Next_Ch = '"', this means that the file name is surrounded
            --     by quotation marks and it can contain spaces inside.
            --
            --  2. Next_Ch /= '"', this means that the file name is bounded by
            --     a white space or end-of-line character

            if Next_Ch = '"' then

               --  We do not generate any warning for badly formatted content
               --  of the file such as
               --
               --    file_name_1
               --    "file name 2
               --    file_name_3
               --
               --  (We do not check that quotation marks correctly go by pairs)

               --  Skip leading '"'
               Get (Arg_File, Next_Ch);

               while Next_Ch not in '"' | ASCII.LF | ASCII.CR loop
                  File_Name_Len                    := File_Name_Len + 1;
                  File_Name_Buffer (File_Name_Len) := Next_Ch;

                  Look_Ahead (Arg_File, Next_Ch, End_Of_Line);

                  exit when End_Of_Line or else End_Of_File (Arg_File);

                  Get (Arg_File, Next_Ch);
               end loop;

               if Next_Ch = '"'
                 and then not Ada.Text_IO.End_Of_Line (Arg_File)
               then
                  --  skip trailing '"'
                  Get (Arg_File, Next_Ch);
               end if;
            else
               while Next_Ch not in ' ' | ASCII.HT | ASCII.LF | ASCII.CR loop
                  File_Name_Len                    := File_Name_Len + 1;
                  File_Name_Buffer (File_Name_Len) := Next_Ch;

                  Look_Ahead (Arg_File, Next_Ch, End_Of_Line);

                  exit when End_Of_Line or else End_Of_File (Arg_File);

                  Get (Arg_File, Next_Ch);
               end loop;
            end if;

         end if;

         return File_Name_Buffer (1 .. File_Name_Len);
      end Get_File_Name;

   --  Start of processing for Read_File_Names_From_File

   begin
      if not Is_Regular_File (Par_File_Name) then
         Cmd_Error (Par_File_Name & " does not exist");
      end if;

      Open (Arg_File, In_File, Par_File_Name);

      loop
         declare
            Tmp_Str : constant String := Get_File_Name;
         begin
            exit when Tmp_Str = "";
            Append_File_Name (Cmd, Tmp_Str);
         end;
      end loop;

      Close (Arg_File);
   exception
      when others =>
         Cmd_Error ("cannot read arguments from " & Par_File_Name);
   end Read_File_Names_From_File;

   procedure Process_Command_Line
     (Cmd                             : in out Command_Line;
      Cmd_Text, Project_Switches_Text :    out Argument_List_Access;
      Global_Report_Dir               :    out String_Ref;
      Compiler_Options                :    out String_List_Access;
      Project_RTS                     :    out String_Access;
      Individual_Source_Options       :    out String_String_List_Map;
      Result_Dirs                     :    out String_String_Map;
      Needs_Per_File_Output           :        Boolean;
      Tool_Package_Name               :        String;
      Compute_Project_Closure         :        Boolean        := True;
      Callback                        :        Parse_Callback := null;
      Post_Cmd_Line_1_Action : not null access procedure (Cmd : Command_Line);
      Tool_Temp_Dir                   :        String;
      Print_Help                      : not null access procedure)
   is
   --  We have to Parse the command line BEFORE we Parse the project file,
   --  because command-line args tell us the name of the project file, and
   --  options for processing it.

   --  We have to Parse the command line AFTER we Parse the project file,
   --  because command-line switches should override those from the project
   --  file.

   --  So we do both.

   --  In addition, we parse the command line ignoring errors first, for
   --  --version and --help switches. ???This also sets debug flags, etc.
   begin
      Cmd_Text := Text_Args_From_Command_Line;

      --  First, process --version or --help switches, if present

      Parse
        (Cmd_Text,
         Cmd,
         Collect_File_Names => True,
         Phase              => Cmd_Line_1,
         Callback           => Callback,
         Ignore_Errors      => True);

      Post_Cmd_Line_1_Action (Cmd);
      --  Why not just move that processing here? We have vis on
      --  Common????????????????

      if ASIS_UL.Debug.Debug_Flag_C then
         Print_Command_Line (Incremental_Mode (Cmd), Mimic_gcc (Cmd));
      end if;

      if Arg (Cmd, Version) then
         Put_Line (Tool_Name & " version 0.0");
         --  ???Not sure what to print here. ASIS tools have an elaborate
         --  scheme that depends on package Gnatvsn in the compiler sources.
         OS_Exit (0);
      end if;

      if Arg (Cmd, Help) then
         Print_Help.all;
         OS_Exit (0);
      end if;

      if Error_Detected (Cmd) then
         Parse
           (Cmd_Text,
            Cmd,
            Phase              => Cmd_Line_1,
            Callback           => null,
            Collect_File_Names => False);

         --  Can't get here, because Parse will have raised Command_Line_Error
         raise Program_Error;
      end if;

      declare
         My_Project : Project_Tree;

         procedure Update_File_Name (File_Name : in out String_Ref);

         procedure Update_File_Name (File_Name : in out String_Ref) is
         begin
            if Is_Regular_File (File_Name.all) then -- ????
               return;
            end if;

            if Arg (Cmd, Project_File) /= null then
               declare
                  Res : constant Virtual_File :=
                    GNATCOLL.Projects.Create (My_Project, +File_Name.all);
               begin
                  if Res = No_File then
                     Cmd_Error (File_Name.all & " not found");
                     --  ????Warning in Source_Table
                  end if;

                  File_Name := new String'(Res.Display_Full_Name);
               end;
            end if;
         end Update_File_Name;

      begin
         if Arg (Cmd, Project_File) /= null then
            Process_Project
              (Cmd,
               Project_Switches_Text,
               Global_Report_Dir,
               Compiler_Options,
               Project_RTS,
               Individual_Source_Options,
               Result_Dirs,
               Needs_Per_File_Output,
               My_Project,
               Tool_Package_Name,
               Compute_Project_Closure,
               Callback,
               Tool_Temp_Dir);
         else
            Compiler_Options      := new Argument_List'(1 .. 0 => <>);
            Project_Switches_Text := new Argument_List'(1 .. 0 => <>);
            --  Leave Individual_Source_Options and Result_Dirs empty
         end if;

         --  Now Parse again, so command-line args override project file args

--  Environment has:
--               if not Mimic_gcc then
--                  --  Ignore unrecognized switches in the inner invocation
--                  Error ...

         Parse
           (Cmd_Text,
            Cmd,
            Phase              => Cmd_Line_2,
            Callback           => Callback,
            Collect_File_Names => False);
         --  ????Collect_File_Names = (Phase = Cmd_Line_2).

         --  The following could just as well happen before the above
         --  Cmd_Line_2 Parse, because file names and "-files=par_file_name"
         --  switches came from the Cmd_Line_1 Parse, or from the project file.

         --  We process the "-files=par_file_name" switches by reading file
         --  names from the file(s) and appending those to the command line.
         --  Then we update the file names to contain directory information
         --  if appropriate.

         for Par_File_Name of Arg (Cmd, Files) loop
            Read_File_Names_From_File (Cmd, Par_File_Name.all);
         end loop;

         if Num_File_Names (Cmd) = 0 then
            Cmd_Error ("No input source file set");
         end if;

         Sort_File_Names (Cmd);
         Iter_File_Names (Cmd, Update_File_Name'Access);
      end;
   end Process_Command_Line;

   ------------------------
   -- Print_Command_Line --
   ------------------------

   procedure Print_Command_Line (Incremental_Mode, Mimic_gcc : Boolean) is
      use Ada.Command_Line, Ada.Directories, ASIS_UL;
   begin
      if Incremental_Mode then
         Formatted_Output.Put ("(outer)\n  ");
      end if;
      if Mimic_gcc then
         Formatted_Output.Put ("(inner)\n  ");
      end if;

      Formatted_Output.Put ("current directory = \1\n", Current_Directory);
      --  A4G.A_Debug.Print_Env; -- disable for now

      Formatted_Output.Put ("  \1", Command_Name);

      for X in 1 .. Argument_Count loop
         Formatted_Output.Put (" \1", Argument (X));
      end loop;
      Formatted_Output.Put ("\n");
   end Print_Command_Line;

end LAL_UL.Projects;