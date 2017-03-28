
SEPARATE (C83022G0M)
FUNCTION INNER3 (X : INTEGER) RETURN INTEGER IS
     C : INTEGER := A;
     A : INTEGER := IDENT_INT(3);
BEGIN
     IF A /= IDENT_INT(3) THEN
          FAILED ("INCORRECT VALUE FOR INNER HOMOGRAPH - 20");
     END IF;

     IF C83022G0M.A /= IDENT_INT(2) THEN
          FAILED ("INCORRECT VALUE FOR OUTER HOMOGRAPH - 21");
     END IF;

     IF C83022G0M.B /= IDENT_INT(2) THEN
          FAILED ("INCORRECT VALUE FOR OUTER VARIABLE - 22");
     END IF;

     IF C /= IDENT_INT(2) THEN
          FAILED ("INCORRECT VALUE FOR INNER VARIABLE - 23");
     END IF;

     IF X /= IDENT_INT(2) THEN
          FAILED ("INCORRECT VALUE PASSED IN - 24");
     END IF;

     IF EQUAL(1,1) THEN
          RETURN A;
     ELSE
          RETURN X;
     END IF;
END INNER3;