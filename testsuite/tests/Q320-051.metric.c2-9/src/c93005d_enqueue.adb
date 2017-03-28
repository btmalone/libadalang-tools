
WITH REPORT; USE REPORT;
WITH SYSTEM; USE SYSTEM;
PRAGMA ELABORATE (REPORT);
PACKAGE BODY C93005D_ENQUEUE IS

     TASK T3 IS
     END T3;

     TASK BODY T3 IS
     BEGIN
          T1.E;
          FAILED ("ENQUEUED CALLER DID NOT GET EXCEPTION");
     EXCEPTION
          WHEN TASKING_ERROR => NULL;
          WHEN OTHERS => FAILED ("WRONG EXCEPTION RAISED");
     END T3;

     PROCEDURE REQUIRE_BODY IS
     BEGIN
          NULL;
     END;
BEGIN                    -- T3 CALLS T1 HERE
     DELAY 1.0;            -- ENSURE THAT T3 EXECUTES
END C93005D_ENQUEUE;