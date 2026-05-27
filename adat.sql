-- ============================================================
--  Webshop adatbázis  (adat.sql)
--  Készítette: Bartók Bence
--  Tartalom: adatbázis, 8 tábla, kapcsolatok, DDL-módosítások, adatok
--  Kódolás: UTF-8 (utf8mb4), magyar rendezési sorrend
-- ============================================================
 
DROP DATABASE IF EXISTS webshop;
CREATE DATABASE webshop
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_hungarian_ci;
USE webshop;
 
-- ============================================================
--  TÁBLÁK LÉTREHOZÁSA  (DDL)
-- ============================================================
 
-- 1) Kategória – a termékek besorolása
CREATE TABLE kategoria (
    kategoria_id INT          NOT NULL AUTO_INCREMENT,
    nev          VARCHAR(50)  NOT NULL,
    leiras       VARCHAR(255) NULL,
    PRIMARY KEY (kategoria_id),
    CONSTRAINT uq_kategoria_nev UNIQUE (nev)
) ENGINE=InnoDB;
 
-- 2) Szállító – a termékek beszállítói
CREATE TABLE szallito (
    szallito_id INT          NOT NULL AUTO_INCREMENT,
    nev         VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NULL,
    telefon     VARCHAR(15)  NULL,
    orszag      VARCHAR(50)  NOT NULL,
    PRIMARY KEY (szallito_id)
) ENGINE=InnoDB;
 
-- 3) Termék – a webshopban árult termékek
CREATE TABLE termek (
    termek_id    INT            NOT NULL AUTO_INCREMENT,
    nev          VARCHAR(100)   NOT NULL,
    ar           DECIMAL(10,2)  NOT NULL,
    kategoria_id INT            NOT NULL,
    szallito_id  INT            NOT NULL,
    PRIMARY KEY (termek_id),
    CONSTRAINT chk_termek_ar CHECK (ar >= 0),
    CONSTRAINT fk_termek_kategoria FOREIGN KEY (kategoria_id)
        REFERENCES kategoria (kategoria_id),
    CONSTRAINT fk_termek_szallito FOREIGN KEY (szallito_id)
        REFERENCES szallito (szallito_id)
) ENGINE=InnoDB;
 
-- 4) Vevő – a regisztrált vásárlók
CREATE TABLE vevo (
    vevo_id   INT          NOT NULL AUTO_INCREMENT,
    nev       VARCHAR(100) NOT NULL,
    email     VARCHAR(100) NOT NULL,
    telefon   VARCHAR(15)  NULL,
    varos     VARCHAR(50)  NOT NULL,
    reg_datum DATE         NOT NULL,
    PRIMARY KEY (vevo_id),
    CONSTRAINT uq_vevo_email UNIQUE (email)
) ENGINE=InnoDB;
 
-- 5) Rendelés – a vevők megrendelései
CREATE TABLE rendeles (
    rendeles_id INT          NOT NULL AUTO_INCREMENT,
    vevo_id     INT          NOT NULL,
    datum       DATE         NOT NULL,
    statusz     VARCHAR(20)  NULL,
    szall_cim   VARCHAR(150) NOT NULL,
    PRIMARY KEY (rendeles_id),
    CONSTRAINT fk_rendeles_vevo FOREIGN KEY (vevo_id)
        REFERENCES vevo (vevo_id)
) ENGINE=InnoDB;
 
-- 6) Rendelési tétel – egy rendelés egyes termék-sorai (kapcsolótábla)
CREATE TABLE rendeles_tetel (
    tetel_id    INT           NOT NULL AUTO_INCREMENT,
    rendeles_id INT           NOT NULL,
    termek_id   INT           NOT NULL,
    mennyiseg   INT           NOT NULL,
    egysegar    DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (tetel_id),
    CONSTRAINT chk_tetel_menny CHECK (mennyiseg > 0),
    CONSTRAINT fk_tetel_rendeles FOREIGN KEY (rendeles_id)
        REFERENCES rendeles (rendeles_id) ON DELETE CASCADE,
    CONSTRAINT fk_tetel_termek FOREIGN KEY (termek_id)
        REFERENCES termek (termek_id)
) ENGINE=InnoDB;
 
-- 7) Raktár – a fizikai raktárak
CREATE TABLE raktar (
    raktar_id INT          NOT NULL AUTO_INCREMENT,
    helyszin  VARCHAR(100) NOT NULL,
    kapacitas INT          NOT NULL,
    PRIMARY KEY (raktar_id)
) ENGINE=InnoDB;
 
-- 8) Raktárkészlet – melyik termékből mennyi van az egyes raktárakban (kapcsolótábla)
CREATE TABLE raktarkeszlet (
    keszlet_id INT NOT NULL AUTO_INCREMENT,
    raktar_id  INT NOT NULL,
    termek_id  INT NOT NULL,
    mennyiseg  INT NOT NULL,
    PRIMARY KEY (keszlet_id),
    CONSTRAINT uq_raktar_termek UNIQUE (raktar_id, termek_id),
    CONSTRAINT chk_keszlet_menny CHECK (mennyiseg >= 0),
    CONSTRAINT fk_keszlet_raktar FOREIGN KEY (raktar_id)
        REFERENCES raktar (raktar_id),
    CONSTRAINT fk_keszlet_termek FOREIGN KEY (termek_id)
        REFERENCES termek (termek_id)
) ENGINE=InnoDB;
 
-- ============================================================
--  DDL FELADATOK – módosítás x2, hozzáadás x2
-- ============================================================
 
-- Hozzáadás 1: minden terméknek legyen egyedi cikkszáma
ALTER TABLE termek
    ADD COLUMN cikkszam VARCHAR(30) NOT NULL UNIQUE AFTER nev;
 
-- Hozzáadás 2: a vevő feliratkozhat a hírlevélre (0 = nem, 1 = igen)
ALTER TABLE vevo
    ADD COLUMN hirlevel TINYINT(1) NOT NULL DEFAULT 0;
 
-- Módosítás 1: a rendelés státusza legyen kötelező, alapértelmezett értékkel
ALTER TABLE rendeles
    MODIFY COLUMN statusz VARCHAR(30) NOT NULL DEFAULT 'Új';
 
-- Módosítás 2: a szállító telefonszáma hosszabb (nemzetközi) formátumot is felvehessen
ALTER TABLE szallito
    MODIFY COLUMN telefon VARCHAR(30) NULL;
 
-- ============================================================
--  ADATOK FELTÖLTÉSE  (DML – INSERT)
-- ============================================================
 
-- Kategóriák
INSERT INTO kategoria (nev, leiras) VALUES
('Laptop',         'Hordozható számítógépek'),
('Okostelefon',    'Mobiltelefonok és okoseszközök'),
('Monitor',        'Kijelzők és monitorok'),
('Kiegészítők',    'Egér, billentyűzet, kábelek'),
('Tárolók',        'SSD, HDD, pendrive'),
('Hálózati eszköz','Router, switch, hálózati kártya');
 
-- Szállítók (az utolsó szállítóhoz szándékosan nem tartozik termék)
INSERT INTO szallito (nev, email, telefon, orszag) VALUES
('TechDistrib Kft.',  'rendeles@techdistrib.hu', '+36 1 234 5678',  'Magyarország'),
('GlobalIT GmbH',     'sales@globalit.de',       '+49 30 1122334',  'Németország'),
('AsiaParts Ltd.',    'info@asiaparts.cn',       '+86 21 99887766', 'Kína'),
('NordHardware AB',   'order@nordhw.se',         '+46 8 5550101',   'Svédország'),
('EuroGadget s.r.o.', 'kontakt@eurogadget.cz',   '+420 2 7654321',  'Csehország');
 
-- Termékek (cikkszám, ár, kategória, szállító)
INSERT INTO termek (nev, cikkszam, ar, kategoria_id, szallito_id) VALUES
('Lenovo ThinkPad E14',        'LP-0001', 389990.00, 1, 1),
('Dell Latitude 5440',         'LP-0002', 459990.00, 1, 2),
('Asus ZenBook 14',            'LP-0003', 529990.00, 1, 3),
('Apple MacBook Air M3',       'LP-0004', 649990.00, 1, 4),
('Samsung Galaxy S24',         'PH-0001', 379990.00, 2, 3),
('Xiaomi Redmi Note 13',       'PH-0002', 119990.00, 2, 3),
('Apple iPhone 15',            'PH-0003', 449990.00, 2, 4),
('Dell UltraSharp U2724',      'MN-0001', 179990.00, 3, 2),
('LG 27GP850 monitor',         'MN-0002', 144990.00, 3, 1),
('Samsung 24 monitor',         'MN-0003',  45990.00, 3, 3),
('Logitech MX Master 3S egér', 'KG-0001',  34990.00, 4, 1),
('Vezeték nélküli billentyűzet','KG-0002',   8990.00, 4, 3),
('USB-C kábel 2m',             'KG-0003',   2990.00, 4, 3),
('HDMI kábel 1,5m',            'KG-0004',   3490.00, 4, 1),
('Samsung 980 SSD 1TB',        'TR-0001',  29990.00, 5, 3),
('WD Blue HDD 2TB',            'TR-0002',  18990.00, 5, 2),
('Kingston pendrive 128GB',    'TR-0003',   8490.00, 5, 1),
('TP-Link Archer router',      'HE-0001',  24990.00, 6, 1),
('Netgear switch 8 portos',    'HE-0002',  39990.00, 6, 2);
 
-- Vevők
INSERT INTO vevo (nev, email, telefon, varos, reg_datum, hirlevel) VALUES
('Kovács Anna',    'kovacs.anna@example.com',   '+36 20 1112233', 'Budapest', '2024-03-12', 1),
('Nagy Péter',     'nagy.peter@example.com',    '+36 30 2223344', 'Debrecen', '2024-05-20', 0),
('Szabó Eszter',   'szabo.eszter@example.com',  '+36 70 3334455', 'Szeged',   '2024-07-01', 1),
('Tóth Gábor',     'toth.gabor@example.com',    '+36 20 4445566', 'Budapest', '2024-09-15', 0),
('Horváth Júlia',  'horvath.julia@example.com', '+36 30 5556677', 'Pécs',     '2025-01-08', 1),
('Varga Dániel',   'varga.daniel@example.com',  '+36 70 6667788', 'Debrecen', '2025-02-14', 0),
('Kiss Réka',      'kiss.reka@example.com',     '+36 20 7778899', 'Győr',     '2025-03-22', 1),
('Molnár Tamás',   'molnar.tamas@example.com',  '+36 30 8889900', 'Budapest', '2025-04-05', 0),
('Balogh Nóra',    'balogh.nora@example.com',   '+36 70 9990011', 'Szeged',   '2025-05-18', 1),
('Farkas Bence',   'farkas.bence@example.com',  '+36 20 1011213', 'Miskolc',  '2025-06-30', 0);
 
-- Rendelések
INSERT INTO rendeles (vevo_id, datum, statusz, szall_cim) VALUES
( 1, '2025-07-10', 'Teljesítve',       'Budapest, Fő utca 12.'),
( 2, '2025-08-22', 'Teljesítve',       'Debrecen, Piac utca 5.'),
( 3, '2025-09-03', 'Új',               'Szeged, Tisza Lajos krt. 8.'),
( 1, '2025-10-18', 'Teljesítve',       'Budapest, Fő utca 12.'),
( 4, '2025-11-05', 'Új',               'Budapest, Rákóczi út 40.'),
( 5, '2025-12-19', 'Törölve',          'Pécs, Király utca 22.'),
( 6, '2026-01-02', 'Teljesítve',       'Debrecen, Petőfi tér 1.'),
( 3, '2026-02-21', 'Szállítás alatt',  'Szeged, Tisza Lajos krt. 8.'),
( 7, '2026-03-09', 'Új',               'Győr, Baross út 15.'),
( 8, '2026-04-27', 'Teljesítve',       'Budapest, Andrássy út 60.'),
( 9, '2026-05-11', 'Új',               'Szeged, Kárász utca 3.'),
( 2, '2026-05-20', 'Szállítás alatt',  'Debrecen, Piac utca 5.');
 
-- Rendelési tételek (egységár = a rendelés időpontjában érvényes ár)
INSERT INTO rendeles_tetel (rendeles_id, termek_id, mennyiseg, egysegar) VALUES
( 1,  1, 1, 389990.00),
( 1, 11, 1,  34990.00),
( 1, 13, 2,   2990.00),
( 2,  5, 1, 379990.00),
( 2, 12, 1,   8990.00),
( 3,  8, 2, 179990.00),
( 3, 14, 1,   3490.00),
( 4,  4, 1, 649990.00),
( 4, 15, 1,  29990.00),
( 5,  6, 1, 119990.00),
( 6,  3, 1, 529990.00),
( 6, 11, 1,  34990.00),
( 7,  9, 1, 144990.00),
( 7, 16, 2,  18990.00),
( 8,  7, 1, 449990.00),
( 8, 13, 3,   2990.00),
( 9, 18, 1,  24990.00),
( 9, 17, 2,   8490.00),
(10,  2, 1, 459990.00),
(10, 19, 1,  39990.00),
(11, 10, 1,  45990.00),
(11, 11, 1,  34990.00),
(12,  1, 1, 389990.00),
(12, 15, 2,  29990.00);
 
-- Raktárak
INSERT INTO raktar (helyszin, kapacitas) VALUES
('Budapesti központi raktár', 5000),
('Debreceni raktár',          2000),
('Szegedi raktár',            1500);
 
-- Raktárkészlet
INSERT INTO raktarkeszlet (raktar_id, termek_id, mennyiseg) VALUES
(1,  1, 25),(1,  2, 18),(1,  3, 12),(1,  4,  8),(1,  5, 30),
(1,  8, 15),(1, 11, 60),(1, 13,200),(1, 15, 45),(1, 18, 22),
(2,  5, 10),(2,  6, 40),(2,  9, 14),(2, 12, 80),(2, 16, 33),
(2, 17,120),(2, 19,  9),
(3,  7, 11),(3, 10, 20),(3, 11, 25),(3, 14,150),(3, 15, 18);
