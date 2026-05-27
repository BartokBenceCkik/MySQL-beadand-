-- ============================================================
--  Webshop adatbázis – FELADATMEGOLDÁSOK  (megoldas.sql)
--  Készítette: Bartók Bence
--  Futtatás: előbb töltsd be az adat.sql-t, majd:  mysql webshop < megoldas.sql
-- ============================================================
USE webshop;

-- ------------------------------------------------------------
--  DML – LEKÉRDEZÉSEK
-- ------------------------------------------------------------

-- i) Választó lekérdezés egy táblával
--    100 000 Ft feletti termékek, ár szerint csökkenően
SELECT nev, ar
FROM termek
WHERE ar > 100000
ORDER BY ar DESC;

-- ii) Választó lekérdezés több táblával
--     Melyik vevő mikor és milyen státuszú rendelést adott le
SELECT v.nev AS vevo, r.datum, r.statusz
FROM vevo v
INNER JOIN rendeles r ON v.vevo_id = r.vevo_id
ORDER BY r.datum;

-- iii) Számított lekérdezés
--      Rendelési tételek végösszege (mennyiség * egységár)
SELECT t.nev AS termek,
       rt.mennyiseg,
       rt.egysegar,
       rt.mennyiseg * rt.egysegar AS vegosszeg
FROM rendeles_tetel rt
INNER JOIN termek t ON rt.termek_id = t.termek_id
ORDER BY vegosszeg DESC;

-- iv) Függvények csoportosítás nélkül
--     Vevők, regisztráció éve és az eltelt napok száma
SELECT nev,
       YEAR(reg_datum) AS reg_ev,
       DATEDIFF(CURDATE(), reg_datum) AS eltelt_napok
FROM vevo
ORDER BY reg_datum;

-- v) Csoportosító lekérdezés + aggregátum függvények
--    Kategóriánként a termékek száma és átlagára
SELECT k.nev AS kategoria,
       COUNT(t.termek_id) AS termekek_szama,
       ROUND(AVG(t.ar), 0) AS atlagar
FROM kategoria k
INNER JOIN termek t ON k.kategoria_id = t.kategoria_id
GROUP BY k.kategoria_id, k.nev
ORDER BY atlagar DESC;

-- vi) Csoportosító lekérdezés csoportra adott feltétellel (HAVING)
--     200 000 Ft feletti átlagárú kategóriák
SELECT k.nev AS kategoria,
       ROUND(AVG(t.ar), 0) AS atlagar
FROM kategoria k
INNER JOIN termek t ON k.kategoria_id = t.kategoria_id
GROUP BY k.kategoria_id, k.nev
HAVING AVG(t.ar) > 200000
ORDER BY atlagar DESC;

-- vii) Szélsőérték meghatározása
--      A legdrágább termék
SELECT nev, ar
FROM termek
WHERE ar = (SELECT MAX(ar) FROM termek);

-- viii) Left Join kapcsolattal megoldható feladat
--       Azok a szállítók, akikhez nem tartozik termék
SELECT sz.nev, sz.orszag
FROM szallito sz
LEFT JOIN termek t ON sz.szallito_id = t.szallito_id
WHERE t.termek_id IS NULL;

-- ix) Unió és metszet
--     a) UNIÓ: budapesti + debreceni vevők
SELECT nev, varos FROM vevo WHERE varos = 'Budapest'
UNION
SELECT nev, varos FROM vevo WHERE varos = 'Debrecen';

--     b) METSZET: hírlevélre feliratkozott ÉS budapesti vevők
SELECT nev FROM vevo WHERE hirlevel = 1
INTERSECT
SELECT nev FROM vevo WHERE varos = 'Budapest';

-- x) Any
--    Nem kiegészítő termékek, amelyek drágábbak BÁRMELYIK kiegészítőnél
SELECT nev, ar
FROM termek
WHERE ar > ANY (
        SELECT t.ar FROM termek t
        INNER JOIN kategoria k ON t.kategoria_id = k.kategoria_id
        WHERE k.nev = 'Kiegészítők'
      )
  AND kategoria_id <> (SELECT kategoria_id FROM kategoria WHERE nev = 'Kiegészítők')
ORDER BY ar;

-- xi) All
--     Termékek, amelyek drágábbak az ÖSSZES kiegészítőnél
SELECT nev, ar
FROM termek
WHERE ar > ALL (
        SELECT t.ar FROM termek t
        INNER JOIN kategoria k ON t.kategoria_id = k.kategoria_id
        WHERE k.nev = 'Kiegészítők'
      )
ORDER BY ar;

-- xii) (Többszörösen) összetett lekérdezés
--      A legtöbbet költő vevő neve és összköltése
SELECT v.nev,
       SUM(rt.mennyiseg * rt.egysegar) AS osszes_koltes
FROM vevo v
INNER JOIN rendeles r        ON v.vevo_id = r.vevo_id
INNER JOIN rendeles_tetel rt ON r.rendeles_id = rt.rendeles_id
GROUP BY v.vevo_id, v.nev
HAVING SUM(rt.mennyiseg * rt.egysegar) = (
    SELECT MAX(osszeg) FROM (
        SELECT SUM(rt2.mennyiseg * rt2.egysegar) AS osszeg
        FROM rendeles r2
        INNER JOIN rendeles_tetel rt2 ON r2.rendeles_id = rt2.rendeles_id
        GROUP BY r2.vevo_id
    ) AS osszesitett
);

-- xiii) (Többszörösen) összetett lekérdezés – korrelált allekérdezés
--       Termékek, amelyek ára a saját kategóriájuk átlaga felett van
SELECT t.nev, t.ar, k.nev AS kategoria
FROM termek t
INNER JOIN kategoria k ON t.kategoria_id = k.kategoria_id
WHERE t.ar > (
        SELECT AVG(t2.ar)
        FROM termek t2
        WHERE t2.kategoria_id = t.kategoria_id
      )
ORDER BY k.nev, t.ar DESC;

-- ------------------------------------------------------------
--  DML – REKORDOK KEZELÉSE
--  (Figyelem: ezek MÓDOSÍTJÁK az adatbázist!)
-- ------------------------------------------------------------

-- 1) Rekordok hozzáadása (1.) – új vevő
INSERT INTO vevo (nev, email, telefon, varos, reg_datum, hirlevel)
VALUES ('Lakatos Zsófia', 'lakatos.zsofia@example.com',
        '+36 20 5556677', 'Eger', '2026-05-15', 1);

-- 2) Rekordok hozzáadása (2.) – új rendelés + két tétel
--    A LAST_INSERT_ID() az előző INSERT által adott azonosítót adja vissza,
--    így nem kell kézzel beírni a vevő, illetve a rendelés id-ját.
INSERT INTO rendeles (vevo_id, datum, statusz, szall_cim)
VALUES (LAST_INSERT_ID(), '2026-05-21', 'Új', 'Eger, Dobó tér 4.');

SET @uj_rendeles = LAST_INSERT_ID();
INSERT INTO rendeles_tetel (rendeles_id, termek_id, mennyiseg, egysegar)
VALUES (@uj_rendeles, 5, 1, 379990.00),
       (@uj_rendeles, 11, 2, 34990.00);

-- 3) Rekordok törlése – a 'Törölve' státuszú rendelések
--    (a tételek az ON DELETE CASCADE miatt automatikusan törlődnek)
DELETE FROM rendeles
WHERE statusz = 'Törölve';

-- 4) Rekordok módosítása – feltétel alapján
--    A 2026-01-01 előtti (régi), 'Új' rendelések 'Teljesítve' státuszúra állítása
UPDATE rendeles
SET statusz = 'Teljesítve'
WHERE statusz = 'Új' AND datum < '2026-01-01';

-- 5) Rekordok módosítása – összes rekord
--    Minden termék árának 10%-os emelése
UPDATE termek
SET ar = ROUND(ar * 1.10, 2);
