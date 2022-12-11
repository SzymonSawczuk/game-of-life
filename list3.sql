-- Szymon Sawczuk 260287

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

-- zad 34 (1)

DECLARE
    result_var NUMBER;
    function_var Kocury.FUNKCJA%TYPE := '&function';
BEGIN
    SELECT DECODE(MAX(funkcja), NULL, 0, 1) INTO result_var FROM Kocury WHERE funkcja = function_var;
    IF result_var = 0
        THEN DBMS_OUTPUT.PUT_LINE('Kot o podanej funkcji nie zostal znaleziony');
        ELSE DBMS_OUTPUT.PUT_LINE('Kot o funkcji ' || function_var || ' zostal znaleziony');
    END IF;
EXCEPTION
    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

-- zad 35 (2)

DECLARE
    pseudo_var Kocury.PSEUDO%TYPE := '&pseudo';
    mouse_eaten_var NUMBER;
    name_var Kocury.IMIE%TYPE;
    join_in_var Kocury.W_STADKU_OD%TYPE;
BEGIN
    SELECT (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) * 12, imie, w_stadku_od
           INTO mouse_eaten_var, name_var, join_in_var
           FROM Kocury
           WHERE pseudo = pseudo_var;

    IF mouse_eaten_var > 700
        THEN DBMS_OUTPUT.PUT_LINE('Calkowity roczny przydzial myszy >700');
        ELSIF name_var LIKE '%A%' OR name_var LIKE '%a%'
            THEN DBMS_OUTPUT.PUT_LINE('Imię zawiera litere A');
        ELSIF EXTRACT(MONTH FROM join_in_var) = 5
            THEN DBMS_OUTPUT.PUT_LINE('Maj jest miesiacem przystapienia do stada');
        ELSE DBMS_OUTPUT.PUT_LINE('Nie odpowiada kryteriom');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND
        THEN DBMS_OUTPUT.PUT_LINE('Nie znaleziono kota o danym pseudonimie');
    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

--  zad 36 (3)

DECLARE
    CURSOR cats_asc IS
        SELECT Kocury.imie, Kocury.przydzial_myszy pm, ROUND(Kocury.przydzial_myszy * 0.1) add_pm, Funkcje.max_myszy max_pm
        FROM Kocury LEFT JOIN Funkcje ON Kocury.FUNKCJA = Funkcje.funkcja
        ORDER BY  PRZYDZIAL_MYSZY ASC
    FOR UPDATE OF przydzial_myszy;

    sum_pm_var NUMBER;
    cat cats_asc%ROWTYPE;
    number_of_change_var NUMBER := 0;

BEGIN
    SELECT SUM(przydzial_myszy) INTO sum_pm_var FROM Kocury;

    <<outer_loop>>
    LOOP
        OPEN cats_asc;
        <<inner_loop>>
        LOOP
            FETCH cats_asc INTO cat;
            EXIT inner_loop WHEN cats_asc%NOTFOUND;
            EXIT outer_loop WHEN sum_pm_var > 1050;

            IF cat.pm + cat.add_pm < cat.max_pm
                THEN
                    sum_pm_var := sum_pm_var + cat.add_pm;
                    UPDATE Kocury SET przydzial_myszy = przydzial_myszy + cat.add_pm WHERE CURRENT OF cats_asc;
                    number_of_change_var := number_of_change_var + 1;
            ELSIF cat.pm + cat.add_pm >= cat.max_pm AND cat.pm < cat.max_pm
                THEN
                    sum_pm_var := sum_pm_var + cat.max_pm - cat.pm ;
                    UPDATE Kocury SET przydzial_myszy = cat.max_pm WHERE CURRENT OF cats_asc;
                    number_of_change_var := number_of_change_var + 1;
            END IF;
        END LOOP inner_loop;
        CLOSE cats_asc;
    END LOOP outer_loop;

    DBMS_OUTPUT.PUT_LINE('Calk. przydzial w stadku ' || sum_pm_var || ' Zmian - ' || number_of_change_var);
EXCEPTION
    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

SELECT imie, przydzial_myszy "Myszki po podwyzce" FROM Kocury ORDER BY PRZYDZIAL_MYSZY DESC;

ROLLBACK;


-- zad 37 (4)

DECLARE
    CURSOR cats_desc IS
        SELECT K1.pseudo, NVL(K1.przydzial_myszy, 0) + NVL(K1.myszy_extra, 0) eating
        FROM Kocury K1
        ORDER BY eating DESC;

    number_var NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Nr'|| LPAD(' ', 3) || 'Pseudonim' || LPAD(' ', 4) ||'Zjada');
    DBMS_OUTPUT.PUT_LINE('----------------------');
    FOR cat IN cats_desc
        LOOP
            number_var := number_var + 1;
            DBMS_OUTPUT.PUT_LINE( number_var || LPAD(' ', 4) || cat.pseudo || LPAD(' ', 13 - LENGTH(cat.pseudo)) || cat.eating);
            EXIT WHEN number_var = 5;
        END LOOP;

EXCEPTION
    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);

END;

-- zad 38 (5)

DECLARE
    CURSOR cats_and_milusia IS
        SELECT imie, funkcja, szef
        FROM Kocury
        WHERE funkcja IN ('KOT', 'MILUSIA');


    depth_of_bosses NUMBER := '&depth_of_bosses';
    depth_of_bosses_max NUMBER;
    cats cats_and_milusia%ROWTYPE;

    name_current_boss Kocury.SZEF%TYPE;
    boss Kocury.SZEF%TYPE;
    temp_boss Kocury.SZEF%TYPE;

BEGIN
    SELECT MAX(LEVEL)
    INTO depth_of_bosses_max
    FROM Kocury
    CONNECT BY PRIOR szef = pseudo
    START WITH funkcja in ('KOT', 'MILUSIA');

    IF depth_of_bosses > depth_of_bosses_max
        THEN depth_of_bosses := depth_of_bosses_max - 1;
    END IF;
    DBMS_OUTPUT.PUT('Imie'||LPAD(' ', 4)||'|  Funkcja'||LPAD(' ', 4));

    FOR index_of_boss IN 1..depth_of_bosses
    LOOP
        DBMS_OUTPUT.PUT('|  SZEF'||index_of_boss||LPAD(' ', 4));
    END LOOP;
    DBMS_OUTPUT.NEW_LINE();
    DBMS_OUTPUT.PUT_LINE(LPAD('-', (depth_of_bosses + 2) * 12, '-'));

    OPEN cats_and_milusia;
    <<outer_loop>>
    LOOP
        FETCH cats_and_milusia INTO cats;
        EXIT outer_loop WHEN cats_and_milusia%NOTFOUND;
        DBMS_OUTPUT.PUT(cats.imie||LPAD(' ', 8 - LENGTH(cats.imie))||'|  '||cats.funkcja||LPAD(' ', 11 - LENGTH(cats.funkcja)));
        temp_boss := cats.szef;

        FOR index_of_boss IN 1..depth_of_bosses
        LOOP
            SELECT imie, szef INTO name_current_boss, boss
                FROM Kocury
                WHERE pseudo = temp_boss;

            DBMS_OUTPUT.PUT('|  '|| name_current_boss ||LPAD(' ', 9 - LENGTH(name_current_boss)));
            EXIT WHEN boss IS NULL;

            temp_boss := boss;
        END LOOP;

        DBMS_OUTPUT.NEW_LINE();

    END LOOP outer_loop;

    CLOSE cats_and_milusia;

EXCEPTION
    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;


-- zad 39 (6)

DECLARE
    gang_nr_var Bandy.NR_BANDY%TYPE := '&nr_bandy';
    gang_name_var Bandy.NAZWA%TYPE := '&nazwa';
    gang_field_var Bandy.TEREN%TYPE := '&teren';
    NOT_NEW_VALUES EXCEPTION;

    CURSOR gang(gang_nr Bandy.NR_BANDY%TYPE, gang_name Bandy.NAZWA%TYPE, gang_field Bandy.TEREN%TYPE) IS
        SELECT * FROM (
            SELECT DECODE(nr_bandy, gang_nr, nr_bandy, NULL) found_nr , DECODE(nazwa, gang_name, nazwa, NULL) found_name, DECODE(teren, gang_field, teren, NULL) found_field
            FROM Bandy)
        WHERE found_nr IS NOT NULL OR found_name IS NOT NULL OR found_field IS NOT NULL;

    found_gang_nr_var Bandy.NR_BANDY%TYPE := NULL;
    found_gang_name_var Bandy.NAZWA%TYPE := NULL;
    found_gang_field_var Bandy.TEREN%TYPE := NULL;

    exception_message VARCHAR2(70) := '';
BEGIN

    FOR gang_entry IN gang(gang_nr_var, gang_name_var, gang_field_var)
    LOOP
        IF found_gang_nr_var IS NULL AND gang_entry.found_nr IS NOT NULL
            THEN
                found_gang_nr_var := gang_entry.found_nr;
        END IF;

        IF found_gang_name_var IS NULL AND gang_entry.found_name IS NOT NULL
            THEN
                found_gang_name_var := gang_entry.found_name;
        END IF;

        IF found_gang_field_var IS NULL AND gang_entry.found_field IS NOT NULL
            THEN
                found_gang_field_var := gang_entry.found_field;
        END IF;

    END LOOP;

    IF found_gang_nr_var IS NOT NULL
        THEN exception_message := exception_message || TO_CHAR(found_gang_nr_var);
    END IF;

    IF found_gang_nr_var IS NULL
        THEN exception_message := exception_message || TO_CHAR(found_gang_name_var);
        ELSIF found_gang_name_var IS NOT NULL
            THEN exception_message := exception_message || ', ' || TO_CHAR(found_gang_name_var);
    END IF;

    IF found_gang_nr_var IS NULL AND found_gang_name_var IS NULL
        THEN exception_message := exception_message || TO_CHAR(found_gang_field_var);
        ELSIF found_gang_field_var IS NOT NULL
            THEN exception_message := exception_message || ', ' || TO_CHAR(found_gang_field_var);
    END IF;

    IF found_gang_nr_var IS NULL AND found_gang_name_var IS NULL AND found_gang_field_var IS NULL
        THEN INSERT INTO BANDY(nr_bandy, nazwa, teren, szef_bandy) VALUES(gang_nr_var, gang_name_var, gang_field_var, NULL);
        ELSE
            exception_message := exception_message || ': juz istnieje';
            RAISE NOT_NEW_VALUES;
    END IF;

EXCEPTION
    WHEN NOT_NEW_VALUES
        THEN DBMS_OUTPUT.PUT_LINE(exception_message);

    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

SELECT * FROM BANDY;

ROLLBACK;

-- zad 40 (7)

CREATE OR REPLACE PROCEDURE new_gang(
    gang_nr_var Bandy.NR_BANDY%TYPE,
    gang_name_var Bandy.NAZWA%TYPE,
    gang_field_var Bandy.TEREN%TYPE
) IS
    NOT_NEW_VALUES EXCEPTION;

    CURSOR gang(gang_nr Bandy.NR_BANDY%TYPE, gang_name Bandy.NAZWA%TYPE, gang_field Bandy.TEREN%TYPE) IS
        SELECT * FROM (
            SELECT DECODE(nr_bandy, gang_nr, nr_bandy, NULL) found_nr , DECODE(nazwa, gang_name, nazwa, NULL) found_name, DECODE(teren, gang_field, teren, NULL) found_field
            FROM Bandy)
        WHERE found_nr IS NOT NULL OR found_name IS NOT NULL OR found_field IS NOT NULL;

    found_gang_nr_var Bandy.NR_BANDY%TYPE := NULL;
    found_gang_name_var Bandy.NAZWA%TYPE := NULL;
    found_gang_field_var Bandy.TEREN%TYPE := NULL;

    exception_message VARCHAR2(70) := '';
BEGIN

    FOR gang_entry IN gang(gang_nr_var, gang_name_var, gang_field_var)
    LOOP
        IF found_gang_nr_var IS NULL AND gang_entry.found_nr IS NOT NULL
            THEN
                found_gang_nr_var := gang_entry.found_nr;
        END IF;

        IF found_gang_name_var IS NULL AND gang_entry.found_name IS NOT NULL
            THEN
                found_gang_name_var := gang_entry.found_name;
        END IF;

        IF found_gang_field_var IS NULL AND gang_entry.found_field IS NOT NULL
            THEN
                found_gang_field_var := gang_entry.found_field;
        END IF;

    END LOOP;

    IF found_gang_nr_var IS NOT NULL
        THEN exception_message := exception_message || TO_CHAR(found_gang_nr_var);
    END IF;

    IF found_gang_nr_var IS NULL
        THEN exception_message := exception_message || TO_CHAR(found_gang_name_var);
        ELSIF found_gang_name_var IS NOT NULL
            THEN exception_message := exception_message || ', ' || TO_CHAR(found_gang_name_var);
    END IF;

    IF found_gang_nr_var IS NULL AND found_gang_name_var IS NULL
        THEN exception_message := exception_message || TO_CHAR(found_gang_field_var);
        ELSIF found_gang_field_var IS NOT NULL
            THEN exception_message := exception_message || ', ' || TO_CHAR(found_gang_field_var);
    END IF;

    IF found_gang_nr_var IS NULL AND found_gang_name_var IS NULL AND found_gang_field_var IS NULL
        THEN INSERT INTO BANDY(nr_bandy, nazwa, teren, szef_bandy) VALUES(gang_nr_var, gang_name_var, gang_field_var, NULL);
        ELSE
            exception_message := exception_message || ': juz istnieje';
            RAISE NOT_NEW_VALUES;
    END IF;

EXCEPTION
    WHEN NOT_NEW_VALUES
        THEN DBMS_OUTPUT.PUT_LINE(exception_message);

    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

BEGIN
    NEW_GANG(6, 'TEST', 'DOM');
END;

SELECT * FROM BANDY;
ROLLBACK;

-- zad 41 (8)

CREATE OR REPLACE TRIGGER create_new_gang
    BEFORE INSERT ON Bandy
    FOR EACH ROW
    DECLARE
        gang_nr_var Bandy.NR_BANDY%TYPE;

        CURSOR max_nr IS
        SELECT MAX(nr_bandy) max_value FROM Bandy;

        max_nr_entry max_nr%ROWTYPE;
    BEGIN
        OPEN max_nr;
        FETCH max_nr INTO max_nr_entry;
            gang_nr_var := max_nr_entry.max_value + 1;
        CLOSE max_nr;

       :NEW.nr_bandy := gang_nr_var;
    END;

BEGIN
    new_gang(7, 'TEST', 'DOM');
END;

ROLLBACK;


-- zad 42 (9)

CREATE OR REPLACE PACKAGE zad42 AS
    tigers_mouses_var Kocury.PRZYDZIAL_MYSZY%TYPE;
    mouses_extra_var Kocury.MYSZY_EXTRA%TYPE := 5;

    tigers_change_var  Kocury.PRZYDZIAL_MYSZY%TYPE;
    tigers_extra_change_var  Kocury.MYSZY_EXTRA%TYPE := 0;

    tigers_old_mouses Kocury.PRZYDZIAL_MYSZY%TYPE := 0;
END zad42;

CREATE OR REPLACE TRIGGER get_tiger_mouses
    BEFORE UPDATE ON Kocury
     DECLARE
        CURSOR tiger_mouses IS
            SELECT przydzial_myszy FROM Kocury WHERE pseudo = 'TYGRYS';
        tiger tiger_mouses%ROWTYPE;
    BEGIN
        OPEN tiger_mouses;
        FETCH tiger_mouses INTO tiger;
        zad42.tigers_mouses_var := ROUND(tiger.przydzial_myszy * 0.1);
        zad42.tigers_old_mouses := tiger.przydzial_myszy;
        CLOSE tiger_mouses;
    END;

CREATE OR REPLACE TRIGGER malware
    BEFORE UPDATE ON Kocury
    FOR EACH ROW
    DECLARE
        change_var Kocury.PRZYDZIAL_MYSZY%TYPE;
    BEGIN
        IF :NEW.funkcja = 'MILUSIA'
            THEN
                change_var := :NEW.przydzial_myszy - :OLD.przydzial_myszy;
                IF change_var > 0
                    THEN
                        IF  change_var < zad42.tigers_mouses_var
                        THEN
                            :NEW.przydzial_myszy := :NEW.przydzial_myszy + zad42.tigers_mouses_var;
                            :NEW.myszy_extra := :NEW.myszy_extra + zad42.mouses_extra_var;
                            zad42.tigers_change_var := -zad42.tigers_mouses_var;
                            zad42.tigers_extra_change_var := 0;

                        ELSIF change_var >= zad42.tigers_mouses_var
                            THEN
                                zad42.tigers_change_var :=  zad42.tigers_mouses_var;
                                zad42.tigers_extra_change_var := 5;
                        END IF;
                END IF;
        END IF;
    END;

CREATE OR REPLACE TRIGGER change_tiger
    AFTER UPDATE ON Kocury
    DECLARE
        change_value_var Kocury.PRZYDZIAL_MYSZY%TYPE;
    BEGIN
        IF zad42.tigers_change_var <> 0
        THEN
            change_value_var := zad42.tigers_change_var;
            zad42.tigers_change_var := 0;
            UPDATE Kocury
            SET przydzial_myszy = zad42.tigers_old_mouses + change_value_var
            WHERE pseudo = 'TYGRYS';
        END IF;

        IF zad42.tigers_extra_change_var > 0
        THEN
            change_value_var := zad42.tigers_extra_change_var;
            zad42.tigers_extra_change_var := 0;
            UPDATE Kocury
            SET myszy_extra = myszy_extra + change_value_var
            WHERE pseudo = 'TYGRYS';

        END IF;
    END;

UPDATE Kocury
    SET przydzial_myszy = przydzial_myszy +9;

ALTER TRIGGER get_tiger_mouses DISABLE;
ALTER TRIGGER malware DISABLE;
ALTER TRIGGER change_tiger DISABLE;


ALTER TRIGGER get_tiger_mouses ENABLE;
ALTER TRIGGER malware ENABLE;
ALTER TRIGGER change_tiger ENABLE;

SELECT * FROM KOCURY;

ROLLBACK;

-- COMPOUND
CREATE OR REPLACE TRIGGER malware_compound
    FOR UPDATE ON Kocury
    COMPOUND TRIGGER
    tigers_mouses_var Kocury.PRZYDZIAL_MYSZY%TYPE;
    mouses_extra_var Kocury.MYSZY_EXTRA%TYPE := 5;

    tigers_change_var  Kocury.PRZYDZIAL_MYSZY%TYPE;
    tigers_extra_change_var  Kocury.MYSZY_EXTRA%TYPE := 0;

    tigers_old_mouses Kocury.PRZYDZIAL_MYSZY%TYPE := 0;

    CURSOR tiger_mouses IS
            SELECT przydzial_myszy FROM Kocury WHERE pseudo = 'TYGRYS';
    tiger tiger_mouses%ROWTYPE;

    change_var Kocury.PRZYDZIAL_MYSZY%TYPE;

    change_value_var Kocury.PRZYDZIAL_MYSZY%TYPE;

    BEFORE STATEMENT IS
    BEGIN
        OPEN tiger_mouses;
        FETCH tiger_mouses INTO tiger;
        zad42.tigers_mouses_var := ROUND(tiger.przydzial_myszy * 0.1);
        zad42.tigers_old_mouses := tiger.przydzial_myszy;
        CLOSE tiger_mouses;
    END BEFORE STATEMENT;

    BEFORE EACH ROW IS
    BEGIN
        IF :NEW.funkcja = 'MILUSIA'
            THEN
                change_var := :NEW.przydzial_myszy - :OLD.przydzial_myszy;
                IF change_var > 0
                    THEN
                        IF  change_var < zad42.tigers_mouses_var
                        THEN
                            :NEW.przydzial_myszy := :NEW.przydzial_myszy + zad42.tigers_mouses_var;
                            :NEW.myszy_extra := :NEW.myszy_extra + zad42.mouses_extra_var;
                            zad42.tigers_change_var := -zad42.tigers_mouses_var;
                            zad42.tigers_extra_change_var := 0;

                        ELSIF change_var >= zad42.tigers_mouses_var
                            THEN
                                zad42.tigers_change_var :=  zad42.tigers_mouses_var;
                                zad42.tigers_extra_change_var := 5;
                        END IF;
                END IF;
        END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        IF zad42.tigers_change_var <> 0
        THEN
            change_value_var := zad42.tigers_change_var;
            zad42.tigers_change_var := 0;
            UPDATE Kocury
            SET przydzial_myszy = zad42.tigers_old_mouses + change_value_var
            WHERE pseudo = 'TYGRYS';
        END IF;

        IF zad42.tigers_extra_change_var > 0
        THEN
            change_value_var := zad42.tigers_extra_change_var;
            zad42.tigers_extra_change_var := 0;
            UPDATE Kocury
            SET myszy_extra = myszy_extra + change_value_var
            WHERE pseudo = 'TYGRYS';

        END IF;
    END AFTER STATEMENT;
END;

-- zad 43 (10)
DECLARE

    header_mes_var VARCHAR2(200);
    is_found_var BOOLEAN := FALSE;
    last_cat_function_var VARCHAR2(20);
    last_cat_value_var VARCHAR2(20);
    last_gang Kocury.NR_BANDY%TYPE := 0;

    sum_of_gender_gang NUMBER := 0;
    sum_of_all NUMBER := 0;
    shift_var NUMBER := 0;

    CURSOR cat_functions IS
        SELECT funkcja, SUM(NVL(Kocury.przydzial_myszy, 0) + NVL(Kocury.myszy_extra, 0)) sum_of_function_mouses FROM Kocury GROUP BY funkcja;

    CURSOR cat_gangs IS
        SELECT Kocury.nr_bandy, Bandy.nazwa, Kocury.plec, COUNT(Kocury.pseudo) how_many_cats
        FROM Kocury LEFT JOIN Bandy on Kocury.nr_bandy = Bandy.nr_bandy
        WHERE Kocury.nr_bandy IS NOT NULL
        GROUP BY Kocury.nr_bandy, Bandy.nazwa, Kocury.plec
        ORDER BY  Kocury.nr_bandy, Kocury.plec;

    CURSOR cats IS
        SELECT Kocury.nr_bandy, Kocury.plec, Kocury.funkcja, SUM(NVL(Kocury.przydzial_myszy, 0) + NVL(Kocury.myszy_extra, 0)) sum_of_mouses
        FROM Kocury
        GROUP BY Kocury.nr_bandy, Kocury.plec, Kocury.funkcja;
BEGIN
    header_mes_var := 'NAZWA BANDY'||LPAD(' ', 8)||'| PLEC'||LPAD(' ', 4)||'| ILE'||LPAD(' ', 4);
    shift_var := LENGTH(header_mes_var);

    FOR cat_function IN cat_functions
    LOOP
        header_mes_var := header_mes_var || '| '|| cat_function.funkcja || LPAD(' ', 4);
    END LOOP;
    header_mes_var := header_mes_var || '| SUMA';
    DBMS_OUTPUT.PUT_LINE(header_mes_var);
    DBMS_OUTPUT.PUT_LINE(LPAD('-', LENGTH(header_mes_var) , '-'));


    FOR cat_gang IN cat_gangs
    LOOP
        IF last_gang <> cat_gang.nr_bandy
            THEN DBMS_OUTPUT.PUT(cat_gang.nazwa || LPAD(' ', 19 - LENGTH(cat_gang.nazwa ))|| '| ' );
            ELSE DBMS_OUTPUT.PUT( LPAD(' ', 19)|| '| ' );
        END IF;
        last_gang := cat_gang.nr_bandy;

        IF cat_gang.plec = 'M'
            THEN DBMS_OUTPUT.PUT('Kocor' || LPAD(' ', 8 - LENGTH('Kocor')));
            ELSE DBMS_OUTPUT.PUT('Kotka' || LPAD(' ', 8 - LENGTH('Kotka')));
        END IF;

        DBMS_OUTPUT.PUT( '| ' || cat_gang.how_many_cats);

        last_cat_function_var := 'ILE';
        last_cat_value_var := cat_gang.how_many_cats;
        FOR cat_function IN cat_functions
        LOOP
            FOR cat IN cats
            LOOP
                IF cat_gang.nr_bandy = cat.nr_bandy AND cat_gang.plec = cat.plec AND cat.funkcja = cat_function.funkcja
                    THEN
                    DBMS_OUTPUT.PUT(LPAD(' ', LENGTH(last_cat_function_var) + 4 - LENGTH(last_cat_value_var))|| '| ' || cat.sum_of_mouses);
                    sum_of_gender_gang := sum_of_gender_gang + cat.sum_of_mouses;
                    last_cat_value_var := cat.sum_of_mouses;
                    is_found_var := TRUE;
                END IF;
            END LOOP;
            IF NOT is_found_var
                THEN DBMS_OUTPUT.PUT(LPAD(' ',  LENGTH(last_cat_function_var) + 4 - LENGTH(last_cat_value_var))||'| 0');
                last_cat_value_var := '0';
            END IF;
            is_found_var := FALSE;
            last_cat_function_var := cat_function.funkcja;
        END LOOP;
        DBMS_OUTPUT.PUT(LPAD(' ',  LENGTH(last_cat_function_var) + 4 - LENGTH(last_cat_value_var))|| '| ' ||sum_of_gender_gang);
        sum_of_all := sum_of_all + sum_of_gender_gang;
        sum_of_gender_gang := 0;
    DBMS_OUTPUT.NEW_LINE();
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Z' || LPAD('-', LENGTH(header_mes_var) - 1 , '-'));
    DBMS_OUTPUT.PUT('ZJADA RAZEM' || LPAD(' ', shift_var - 11 ) );

    FOR cat_function IN cat_functions
        LOOP
            last_cat_function_var := cat_function.funkcja;
            last_cat_value_var := cat_function.sum_of_function_mouses;
            DBMS_OUTPUT.PUT( '| ' || cat_function.sum_of_function_mouses || LPAD(' ', LENGTH(last_cat_function_var) + 4 - LENGTH(last_cat_value_var)) );
        END LOOP;
    DBMS_OUTPUT.PUT( '| ' || sum_of_all);
    DBMS_OUTPUT.NEW_LINE();

EXCEPTION
    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

-- zad 44 (11)

CREATE OR REPLACE PACKAGE tax_and_new_gang AS
    FUNCTION calculate_tax(cat_pseudo Kocury.PSEUDO%TYPE) RETURN NUMBER;
    PROCEDURE new_gang_zad44(
    gang_nr_var Bandy.NR_BANDY%TYPE,
    gang_name_var Bandy.NAZWA%TYPE,
    gang_field_var Bandy.TEREN%TYPE
    );
END;


CREATE OR REPLACE PACKAGE BODY tax_and_new_gang
AS
     FUNCTION calculate_tax(cat_pseudo Kocury.PSEUDO%TYPE) RETURN NUMBER IS
            CURSOR cat_mouses IS
            SELECT NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) mouses_all, szef  FROM Kocury WHERE pseudo = cat_pseudo;

            CURSOR cat_subordinates IS
            SELECT COUNT(pseudo) amount FROM Kocury WHERE szef = cat_pseudo;

            CURSOR cat_enemies IS
            SELECT COUNT(imie_wroga) amount FROM Wrogowie_kocurow WHERE pseudo = cat_pseudo;

            cat_mouse cat_mouses%ROWTYPE;
            cat_subordinate cat_subordinates%ROWTYPE;
            cat_enemy cat_enemies%ROWTYPE;
            income_var NUMBER;
            result_var NUMBER;

        BEGIN
            OPEN cat_mouses;
            OPEN cat_subordinates;
            OPEN cat_enemies;

            FETCH cat_mouses INTO cat_mouse;
            FETCH cat_subordinates INTO cat_subordinate;
            FETCH cat_enemies INTO cat_enemy;

            income_var := cat_mouse.mouses_all;
            result_var := CEIL(income_var * 0.05);

            IF cat_subordinate.amount = 0
                THEN result_var := result_var + 2;
            END IF;

            IF cat_enemy.amount = 0
                THEN result_var := result_var + 1;
            END IF;

            IF cat_mouse.szef IS NULL
                THEN result_var := result_var + 3;
            END IF;

            CLOSE cat_mouses;
            CLOSE cat_subordinates;
            CLOSE cat_enemies;

            RETURN result_var;

        END calculate_tax;


    PROCEDURE new_gang_zad44(
    gang_nr_var Bandy.NR_BANDY%TYPE,
    gang_name_var Bandy.NAZWA%TYPE,
    gang_field_var Bandy.TEREN%TYPE
    ) IS
        BEGIN
            new_gang(gang_nr_var, gang_name_var, gang_field_var);
        END new_gang_zad44;

END;

SELECT pseudo, tax_and_new_gang.calculate_tax(pseudo) FROM Kocury;

DROP PACKAGE tax_and_new_gang;

-- zad 45 (12)
CREATE TABLE Dodatki_extra(
    pseudo VARCHAR2(15) CONSTRAINT pseudo_fk REFERENCES Kocury(pseudo),
    extra NUMBER(4) DEFAULT 0 NOT NULL
);

COMMIT;

DROP TABLE Dodatki_extra;

CREATE OR REPLACE TRIGGER punish_milus
    BEFORE UPDATE OF przydzial_myszy ON Kocury
    FOR EACH ROW
    DECLARE
        CURSOR does_have_rows(find_milus Kocury.PSEUDO%TYPE) IS
        SELECT COUNT(pseudo) amount FROM Dodatki_extra WHERE pseudo = find_milus;

        amount_of_rows does_have_rows%ROWTYPE;
--         PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        IF LOGIN_USER <> 'TYGRYS'
            THEN
                IF :NEW.funkcja = 'MILUSIA'
                    THEN
                        OPEN does_have_rows(:NEW.pseudo);
                        FETCH does_have_rows INTO amount_of_rows;

                        IF amount_of_rows.amount = 0
                            THEN EXECUTE IMMEDIATE 'INSERT INTO Dodatki_extra VALUES (:pseudo_milus, 0)' USING :NEW.pseudo;
                        END IF;
                        CLOSE does_have_rows;
                        EXECUTE IMMEDIATE 'UPDATE Dodatki_extra SET extra = extra - 10 WHERE pseudo = :pseudo_milus' USING :NEW.pseudo;
                END IF;
        END IF;

--         COMMIT;
    END;

UPDATE Kocury
    SET przydzial_myszy = przydzial_myszy +9;

SELECT * FROM Kocury;
SELECT * FROM Dodatki_extra;

ROLLBACK;

-- zad 46 (13)

CREATE TABLE Monitor_not_valid(
    user_login_var VARCHAR2(100) NOT NULL,
    date_of_try DATE DEFAULT SYSDATE NOT NULL,
    pseudo_who_changed_var VARCHAR2(15) NOT NULL,
    what_operation_var VARCHAR2(15) NOT NULL
);

DROP TABLE Monitor_not_valid;

CREATE OR REPLACE TRIGGER check_compartment
    BEFORE UPDATE OR INSERT ON Kocury
    FOR EACH ROW
    DECLARE
        CURSOR compartment(cat_function Funkcje.FUNKCJA%TYPE) IS
        SELECT min_myszy, max_myszy FROM Funkcje WHERE funkcja = cat_function;

        found_compartment compartment%ROWTYPE;

        user_login_var VARCHAR2(100);
        pseudo_who_changed_var Kocury.PSEUDO%TYPE;
        what_operation_var VARCHAR2(15);

--         error_not_valid_compartment EXCEPTION;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        OPEN compartment(:NEW.funkcja);
        FETCH compartment INTO found_compartment;

        IF :NEW.przydzial_myszy < found_compartment.MIN_MYSZY OR :NEW.przydzial_myszy > found_compartment.max_myszy
            THEN
--                 :NEW.przydzial_myszy := :OLD.przydzial_myszy;

                user_login_var := LOGIN_USER;
                pseudo_who_changed_var := :NEW.pseudo;

                IF INSERTING
                    THEN what_operation_var := 'INSERT';
                    ELSE what_operation_var := 'UPDATE';
                END IF;

                INSERT INTO MONITOR_NOT_VALID VALUES(user_login_var, SYSDATE , pseudo_who_changed_var, what_operation_var);
                COMMIT;
                    RAISE_APPLICATION_ERROR(-20001, 'Podany przydzial poza przedzialem funkcji kota');
--                 RAISE error_not_valid_compartment;

        END IF;
        CLOSE compartment;

--     EXCEPTION
--         WHEN error_not_valid_compartment THEN DBMS_OUTPUT.PUT_LINE('Podany przydzial poza przedzialem funkcji kota');
    END;

UPDATE Kocury
    SET
        przydzial_myszy = 10
    WHERE pseudo = 'UCHO';

INSERT INTO Kocury VALUES('MARCIN', 'M', 'SIEKACZ', 'KOT', null, '2011-05-15', 10, null, 2);

SELECT * FROM Kocury;

SELECT * FROM Monitor_not_valid;

ROLLBACK;
