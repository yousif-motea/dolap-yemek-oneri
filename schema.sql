-- GELİŞTİRİLMİŞ DOLAP DB - ZENGİN TARİF KOLEKSİYONU
-- 50+ tarif, kategoriler, çalışan fotoğraflar

SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS=0;

DROP VIEW IF EXISTS `recipe_stats`;
DROP TABLE IF EXISTS `recipe_ingredients`;
DROP TABLE IF EXISTS `user_favorites`;
DROP TABLE IF EXISTS `pantry_items`;
DROP TABLE IF EXISTS `pantry`;
DROP TABLE IF EXISTS `recipes`;
DROP TABLE IF EXISTS `ingredients`;

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;

-- Veritabanı oluştur
CREATE DATABASE IF NOT EXISTS `dolap_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `dolap_db`;

-- 1) Malzemeler tablosu
CREATE TABLE `ingredients` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(50) DEFAULT 'diğer',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `ux_ingredients_name` (`name`),
  KEY `ix_ingredients_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2) Tarifler tablosu
CREATE TABLE `recipes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(200) NOT NULL,
  `ingredients_text` TEXT,
  `instructions` TEXT,
  `prep_minutes` INT,
  `calories` INT,
  `difficulty` ENUM('kolay','orta','zor') DEFAULT 'kolay',
  `tags` VARCHAR(500),
  `image_url` VARCHAR(500),
  `category` VARCHAR(50) DEFAULT 'ana yemek',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `ix_recipes_title` (`title`),
  KEY `ix_recipes_difficulty` (`difficulty`),
  KEY `ix_recipes_category` (`category`),
  KEY `ix_recipes_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3) Tarif-malzeme ilişkileri
CREATE TABLE `recipe_ingredients` (
  `recipe_id` INT NOT NULL,
  `ingredient_id` INT NOT NULL,
  PRIMARY KEY (`recipe_id`,`ingredient_id`),
  CONSTRAINT `fk_ri_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ri_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4) Dolap
CREATE TABLE `pantry` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `ingredient_id` INT NOT NULL,
  `added_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `ux_pantry_ingredient` (`ingredient_id`),
  CONSTRAINT `fk_pantry_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5) Favoriler
CREATE TABLE `user_favorites` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `session_id` VARCHAR(100) NOT NULL,
  `recipe_id` INT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `ix_uf_session` (`session_id`),
  KEY `ix_uf_recipe` (`recipe_id`),
  CONSTRAINT `fk_uf_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- MALZEME VERİLERİ (Kategorilere göre düzenlenmiş)
-- ============================================================

INSERT INTO `ingredients` (`name`, `category`) VALUES
-- Sebzeler
('domates', 'sebze'), ('soğan', 'sebze'), ('sarımsak', 'sebze'), 
('patates', 'sebze'), ('havuç', 'sebze'), ('pırasa', 'sebze'),
('yeşil biber', 'sebze'), ('kırmızı biber', 'sebze'), ('sivri biber', 'sebze'),
('patlıcan', 'sebze'), ('kabak', 'sebze'), ('karnabahar', 'sebze'),
('brokoli', 'sebze'), ('mantar', 'sebze'), ('ıspanak', 'sebze'),
('semizotu', 'sebze'), ('bezelye', 'sebze'), ('fasulye', 'sebze'),
('barbunya', 'sebze'), ('mısır', 'sebze'), ('salatalık', 'sebze'),
('maydanoz', 'yeşillik'), ('dereotu', 'yeşillik'), ('nane', 'yeşillik'),
('roka', 'yeşillik'), ('taze soğan', 'yeşillik'),

-- Et ve Tavuk
('kıyma', 'et'), ('kuşbaşı et', 'et'), ('tavuk göğsü', 'tavuk'),
('tavuk but', 'tavuk'), ('tavuk kanat', 'tavuk'),

-- Bakliyat ve Tahıllar
('kırmızı mercimek', 'bakliyat'), ('yeşil mercimek', 'bakliyat'),
('nohut', 'bakliyat'), ('kuru fasulye', 'bakliyat'),
('pirinç', 'tahıl'), ('bulgur', 'tahıl'), ('makarna', 'tahıl'),
('erişte', 'tahıl'), ('şehriye', 'tahıl'), ('sıvıyağ', 'tahıl'),

-- Süt Ürünleri
('süt', 'süt ürünü'), ('yoğurt', 'süt ürünü'), ('ayran', 'süt ürünü'),
('peynir', 'süt ürünü'), ('beyaz peynir', 'süt ürünü'), 
('kaşar peyniri', 'süt ürünü'), ('tereyağı', 'süt ürünü'),
('krema', 'süt ürünü'),

-- Temel Malzemeler
('un', 'temel'), ('mısır unu', 'temel'), ('nişasta', 'temel'),
('yumurta', 'temel'), ('zeytinyağı', 'yağ'), ('sıvı yağ', 'yağ'),
('tuz', 'baharat'), ('karabiber', 'baharat'), ('pul biber', 'baharat'),
('kimyon', 'baharat'), ('kekik', 'baharat'), ('köri', 'baharat'),
('tarçın', 'baharat'), ('karanfil', 'baharat'),

-- Salçalar ve Soslar
('domates salçası', 'salça'), ('biber salçası', 'salça'),
('ketçap', 'sos'), ('mayonez', 'sos'), ('hardal', 'sos'),
('soya sosu', 'sos'),

-- Diğer
('limon', 'meyve'), ('portakal', 'meyve'),
('şeker', 'tatlandırıcı'), ('bal', 'tatlandırıcı'),
('su', 'sıvı'), ('sebze suyu', 'sıvı'), ('et suyu', 'sıvı'),
('sirke', 'diğer'), ('zeytin', 'diğer'), ('ceviz', 'diğer'),
('susam', 'diğer'), ('haşhaş', 'diğer')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- ============================================================
-- TARİF VERİLERİ (50+ çeşitli tarif) - GÜNCELLENMİŞ FOTOĞRAFLAR
-- ============================================================

INSERT INTO `recipes` 
(`title`, `ingredients_text`, `instructions`, `prep_minutes`, `calories`, `difficulty`, `tags`, `category`, `image_url`) 
VALUES

-- ÇORBALAR
('Mercimek Çorbası',
 'kırmızı mercimek, soğan, havuç, patates, zeytinyağı, tuz, kimyon, limon',
 '1) Mercimek ve sebzeleri haşlayın.\n2) Blenderdan geçirin.\n3) Kimyon ve limonla servis edin.',
 40, 220, 'kolay', 'çorba,vejetaryen,sağlıklı', 'çorba',
 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600'),

('Domates Çorbası',
 'domates, soğan, sarımsak, zeytinyağı, tuz, karabiber, un, tereyağı',
 '1) Soğan ve sarımsağı zeytinyağında kavurun.\n2) Domatesleri ekleyip pişirin.\n3) Un ve tereyağı ile kıvam verin.\n4) Tuz ve biberle tatlandırın.',
 30, 180, 'kolay', 'çorba,vejetaryen,pratik', 'çorba',
 'images/domates_corbasi.jpg'),

('Ezogelin Çorbası',
 'kırmızı mercimek, bulgur, pirinç, soğan, biber salçası, domates salçası, tuz, nane, tereyağı',
 '1) Mercimek, bulgur ve pirinci haşlayın.\n2) Soğan ve salçaları kavurun.\n3) Karıştırıp pişirin.\n4) Nane ve tereyağı ile servis yapın.',
 45, 250, 'orta', 'çorba,geleneksel,doyurucu', 'çorba',
 'images/ezogelin.jpg'),

('Tavuk Çorbası',
 'tavuk göğsü, havuç, patates, makarna, su, tuz, karabiber, limon',
 '1) Tavuk ve sebzeleri haşlayın.\n2) Tavuğu didikleyin.\n3) Makarna ekleyip pişirin.\n4) Limonla servis edin.',
 50, 200, 'kolay', 'çorba,tavuk,sağlıklı', 'çorba',
 'images/tavuk çorbası.jpg'),

('Yayla Çorbası',
 'yoğurt, pirinç, un, yumurta, nane, tuz, tereyağı',
 '1) Pirinç haşlayın.\n2) Yoğurt, un ve yumurta karışımı hazırlayın.\n3) Karıştırıp kaynatın.\n4) Naneli tereyağı ile servis yapın.',
 35, 190, 'orta', 'çorba,yoğurtlu,geleneksel', 'çorba',
 'images/yayla çorbası.jpg'),

-- ANA YEMEKLER - ET
('İzmir Köfte',
 'kıyma, yumurta, un, soğan, domates, yeşil biber, patates, zeytinyağı, tuz, karabiber',
 '1) Köfte harcını yoğurup şekillendirin.\n2) Sebzeleri doğrayın.\n3) Köftelerle birlikte fırında pişirin.',
 60, 450, 'orta', 'ana yemek,et,fırın', 'ana yemek',
 'images/izmir köfte.jpg'),

('Etli Nohut',
 'kuşbaşı et, nohut, soğan, domates salçası, tuz, karabiber, kimyon',
 '1) Nohutu ıslatın.\n2) Eti kavurun.\n3) Nohut ve baharatları ekleyip haşlayın.',
 90, 380, 'orta', 'ana yemek,et,bakliyat', 'ana yemek',
 'images/etli_nohut.jpg'),

('Karnıyarık',
 'patlıcan, kıyma, soğan, domates, yeşil biber, sarımsak, domates salçası, tuz',
 '1) Patlıcanları kızartın.\n2) İç harcını hazırlayın.\n3) Patlıcanları doldurup fırınlayın.',
 70, 420, 'zor', 'ana yemek,et,zeytinyağlı', 'ana yemek',
 'images/karnıyarık.jpg'),

('Mantı',
 'un, yumurta, kıyma, soğan, yoğurt, sarımsak, tereyağı, pul biber',
 '1) Hamur açın, küçük kareler kesin.\n2) İç harcı koyup şekillendirin.\n3) Haşlayıp yoğurt ve tereyağ ile servis yapın.',
 120, 520, 'zor', 'ana yemek,hamur işi,geleneksel', 'ana yemek',
 'images/mantı.jpg'),

('Hünkar Beğendi',
 'kuşbaşı et, patlıcan, süt, un, tereyağı, kaşar peyniri, soğan, domates salçası',
 '1) Patlıcanları közleyip püre yapın.\n2) Eti haşlayın.\n3) Patlıcan püresi üzerine et servis yapın.',
 80, 480, 'zor', 'ana yemek,et,otantik', 'ana yemek',
 'https://images.unsplash.com/photo-1574484284002-952d92456975?w=600'),

-- ANA YEMEKLER - TAVUK
('Tavuk Sote',
 'tavuk göğsü, soğan, sarımsak, yeşil biber, domates, zeytinyağı, tuz, karabiber',
 '1) Tavuğu yüksek ateşte soteleyin.\n2) Sebzeleri ekleyin.\n3) Kısık ateşte yumuşayana kadar pişirin.',
 45, 320, 'kolay', 'ana yemek,tavuk,pratik', 'ana yemek',
 'images/sote.jpg'),

('Fırında Tavuk',
 'tavuk but, patates, havuç, soğan, zeytinyağı, kekik, tuz, karabiber, limon',
 '1) Tavuk ve sebzeleri baharatlarla marine edin.\n2) Fırın tepsisine dizin.\n3) 180 derecede 50 dakika pişirin.',
 70, 380, 'kolay', 'ana yemek,tavuk,fırın', 'ana yemek',
 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=600'),

('Tavuk Şiş',
 'tavuk göğsü, yoğurt, zeytinyağı, sarımsak, kekik, tuz, karabiber, limon',
 '1) Tavuğu marine edin.\n2) Şişlere dizin.\n3) Közde veya fırında pişirin.',
 45, 280, 'kolay', 'ana yemek,tavuk,ızgara', 'ana yemek',
 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600'),

('Tavuk Dürüm',
 'tavuk göğsü, lavaş, marul, domates, soğan, mayonez, ketçap, tuz, karabiber',
 '1) Tavuğu soteleyin.\n2) Lavaşa sebzeleri yerleştirin.\n3) Tavuk ve sosları ekleyip dürün.',
 30, 350, 'kolay', 'pratik,tavuk,fast food', 'atıştırmalık',
 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600'),

-- ZEYTİNYAĞLILAR
('İmam Bayıldı',
 'patlıcan, soğan, domates, sarımsak, maydanoz, zeytinyağı, şeker, tuz',
 '1) Patlıcanları kızartın.\n2) İç harcı hazırlayın.\n3) Doldurup fırınlayın.\n4) Soğuk servis yapın.',
 60, 280, 'orta', 'zeytinyağlı,vejetaryen,soğuk', 'zeytinyağlı',
 'images/imam_bayildi.jpg'),

('Zeytinyağlı Fasulye',
 'taze fasulye, soğan, domates, zeytinyağı, şeker, tuz, limon',
 '1) Fasulyeyi doğrayın.\n2) Soğanla kavurun.\n3) Domatesle pişirin.\n4) Soğuk servis yapın.',
 50, 200, 'kolay', 'zeytinyağlı,vejetaryen,sağlıklı', 'zeytinyağlı',
 'images/zeytin yağlı fasulye.jpg'),

('Zeytinyağlı Barbunya',
 'barbunya, soğan, havuç, patates, domates, zeytinyağı, şeker, tuz',
 '1) Fasulyeleri ıslatın.\n2) Sebzelerle pişirin.\n3) Zeytinyağı ve şeker ekleyin.\n4) Soğuk servis yapın.',
 70, 220, 'kolay', 'zeytinyağlı,vejetaryen,klasik', 'zeytinyağlı',
 'images/zeytin yağlı barbunya.jpg'),

('Pırasa',
 'pırasa, havuç, pirinç, zeytinyağı, şeker, tuz, limon',
 '1) Pırasayı doğrayın.\n2) Havuç ve pirinçle pişirin.\n3) Zeytinyağı ekleyin.\n4) Soğuk servis yapın.',
 45, 180, 'kolay', 'zeytinyağlı,vejetaryen,hafif', 'zeytinyağlı',
 'images/pırasa.jpg'),

-- MAKARNA VE PİLAVLAR
('Kıymalı Makarna',
 'makarna, kıyma, soğan, sarımsak, domates salçası, tuz, karabiber, zeytinyağı',
 '1) Makarnayı haşlayın.\n2) Kıymayı soğan ve sarımsakla kavurun.\n3) Salçayı ekleyin, sosu makarnayla birleştirin.',
 25, 350, 'kolay', 'makarna,et,pratik', 'makarna',
 'images/makarna.jpg'),

('Spagetti Bolonez',
 'makarna, kıyma, domates, soğan, sarımsak, zeytinyağı, fesleğen, tuz, karabiber',
 '1) Bolonez sosunu hazırlayın.\n2) Makarnayı haşlayın.\n3) Sosla karıştırıp servis yapın.',
 40, 420, 'orta', 'makarna,et,italyan', 'makarna',
 'images/spagetti.jpg'),

('Makarna',
 'makarna, tuz, su, zeytinyağı',
 '1) Tuzu eklediğiniz suyu kaynatın.\n2) Makarnayı paketteki süre kadar haşlayın.\n3) Süzün, zeytinyağı ile karıştırın.',
 15, 280, 'kolay', 'pratik,makarna,vejetaryen', 'makarna',
 'images/makarna_sade.jpg'),

('Pirinç Pilavı',
 'pirinç, tereyağı, su, tuz',
 '1) Pirinci yıkayın.\n2) Tereyağında kavurun.\n3) Su ve tuz ekleyip pişirin.',
 30, 220, 'kolay', 'pilav,yan yemek,temel', 'pilav',
 'images/pilav.jpg'),

('Şehriyeli Pilav',
 'pirinç, şehriye, tereyağı, su, tuz',
 '1) Şehriyeyi kızartın.\n2) Pirinç ekleyip kavurun.\n3) Su ve tuz ekleyip pişirin.',
 30, 240, 'kolay', 'pilav,yan yemek,klasik', 'pilav',
 'images/şehriyeli pilav.jpg'),

('İç Pilav',
 'pirinç, kuşbaşı et, karaciğer, soğan, fındık, kuş üzümü, tarçın, tereyağı',
 '1) Eti pişirin.\n2) Pirinç ve iç malzemeleri kavurun.\n3) Su ekleyip pişirin.',
 60, 450, 'zor', 'pilav,et,geleneksel', 'pilav',
 'images/pilav.jpg'),

-- BÖREK VE HAMUR İŞLERİ
('Kol Böreği',
 'yufka, peynir, maydanoz, yumurta, süt, sıvı yağ',
 '1) İç harcı hazırlayın.\n2) Yufkaları doldurup rulo yapın.\n3) Fırında kızartın.',
 45, 320, 'orta', 'börek,hamur işi,kahvaltılık', 'börek',
 'images/kol böreği.jpg'),

('Su Böreği',
 'yufka, peynir, maydanoz, yumurta, süt, tereyağı',
 '1) Yufkaları haşlayın.\n2) Katlar halinde dizin.\n3) Fırında pişirin.',
 60, 380, 'orta', 'börek,peynirli,klasik', 'börek',
 'images/su böreği.jpg'),

('Gözleme',
 'un, su, tuz, patates, peynir, maydanoz, zeytinyağı',
 '1) Hamur açın.\n2) İç harcı koyun.\n3) Sac üzerinde pişirin.',
 40, 300, 'kolay', 'hamur işi,pratik,geleneksel', 'börek',
 'images/gozleme.jpg'),

('Sigara Böreği',
 'yufka, beyaz peynir, maydanoz, kıyma, sıvı yağ',
 '1) İç harcı hazırlayın.\n2) Yufkaları sigara gibi sarın.\n3) Kızgın yağda kızartın.',
 35, 280, 'kolay', 'börek,atıştırmalık,kızartma', 'börek',
 'images/sigara böreği.jpg'),

-- SALATALAR
('Çoban Salata',
 'domates, salatalık, yeşil biber, soğan, maydanoz, zeytinyağı, limon, tuz',
 '1) Sebzeleri küp küp doğrayın.\n2) Limon ve zeytinyağı ile karıştırın.\n3) Tuzlayıp servis yapın.',
 15, 80, 'kolay', 'salata,vejetaryen,hafif', 'salata',
 'images/coban_salata.jpg'),

('Mevsim Salata',
 'marul, domates, salatalık, havuç, zeytinyağı, limon, tuz',
 '1) Sebzeleri doğrayın.\n2) Zeytinyağı ve limon sosu hazırlayın.\n3) Karıştırıp servis yapın.',
 10, 60, 'kolay', 'salata,vejetaryen,sağlıklı', 'salata',
 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600'),

('Çıtır Tavuk Salata',
 'tavuk göğsü, marul, domates, mısır, zeytinyağı, limon, tuz, un, yumurta',
 '1) Tavuğu çıtır şekilde kızartın.\n2) Salata malzemelerini karıştırın.\n3) Tavukla servis yapın.',
 35, 320, 'kolay', 'salata,tavuk,doyurucu', 'salata',
 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600'),

-- TATLILAR
('Sütlaç',
 'pirinç, süt, şeker, nişasta, vanilin',
 '1) Pirinci haşlayın.\n2) Süt ve şekeri ekleyip pişirin.\n3) Nişastayla kıvam verin.\n4) Soğutup servis yapın.',
 45, 280, 'kolay', 'tatlı,sütlü,geleneksel', 'tatlı',
 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=600'),

('Kazandibi',
 'süt, şeker, tavuk göğsü, pirinç unu, nişasta, vanilin',
 '1) Tavuk göğsünü didikleyin.\n2) Muhallebiyi pişirin.\n3) Tavayı yakıp kızartın.\n4) Soğutup servis yapın.',
 60, 320, 'zor', 'tatlı,sütlü,otantik', 'tatlı',
 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600'),

('İrmik Helvası',
 'irmik, şeker, tereyağı, süt, fındık',
 '1) İrmiği tereyağında kavurun.\n2) Sıcak süt ekleyin.\n3) Karıştırıp pişirin.\n4) Fındıkla servis yapın.',
 25, 380, 'kolay', 'tatlı,geleneksel,pratik', 'tatlı',
 'images/irmik.jpg'),

('Revani',
 'irmik, yumurta, şeker, yoğurt, un, kabartma tozu, vanilin, şerbet',
 '1) Hamuru hazırlayın.\n2) Fırında pişirin.\n3) Şerbeti dökün.\n4) Dilimleyip servis yapın.',
 60, 420, 'orta', 'tatlı,şerbetli,fırın', 'tatlı',
 'https://images.unsplash.com/photo-1571115177098-24ec42ed204d?w=600'),

('Baklava',
 'baklava yufkası, ceviz, şeker, tereyağı, şerbet',
 '1) Yufkaları yağlayıp dizin.\n2) Aralarına ceviz serpin.\n3) Dilimleyip fırınlayın.\n4) Şerbet dökün.',
 90, 520, 'zor', 'tatlı,şerbetli,geleneksel', 'tatlı',
 'https://images.unsplash.com/photo-1598110750624-207050c4f28c?w=600'),

('Kadayıf',
 'tel kadayıf, tereyağı, ceviz, şerbet',
 '1) Kadayıfı yağlayın.\n2) Ceviz ekleyip sarın.\n3) Fırında kızartın.\n4) Şerbet dökün.',
 50, 480, 'orta', 'tatlı,şerbetli,özel', 'tatlı',
 'images/kadayıf.jpg'),

('Muhallebi',
 'süt, şeker, nişasta, pirinç unu, vanilin',
 '1) Süt ve şekeri kaynatın.\n2) Nişastayla kıvam verin.\n3) Kaselere doldurun.\n4) Soğutup servis yapın.',
 30, 220, 'kolay', 'tatlı,sütlü,hafif', 'tatlı',
 'images/muhallebi.jpg'),

-- KAHVALTILILAR
('Menemen',
 'yumurta, domates, yeşil biber, soğan, zeytinyağı, tuz, karabiber',
 '1) Sebzeleri kavurun.\n2) Yumurtaları kırın.\n3) Karıştırıp pişirin.',
 15, 220, 'kolay', 'kahvaltı,yumurta,pratik', 'kahvaltılık',
 'images/menemen.jpg'),

('Sahanda Yumurta',
 'yumurta, tereyağı, tuz, karabiber',
 '1) Tereyağını eritin.\n2) Yumurtayı kırın.\n3) Pişirip servis yapın.',
 5, 180, 'kolay', 'kahvaltı,yumurta,hızlı', 'kahvaltılık',
 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=600'),

('Omlet',
 'yumurta, süt, peynir, soğan, yeşil biber, tereyağı, tuz',
 '1) Yumurtaları çırpın.\n2) Malzemeleri ekleyin.\n3) Tavada pişirin.',
 10, 250, 'kolay', 'kahvaltı,yumurta,pratik', 'kahvaltılık',
 'images/omlet.jpg'),

('Pankek',
 'un, yumurta, süt, şeker, kabartma tozu, tereyağı, bal',
 '1) Hamuru karıştırın.\n2) Tavada pişirin.\n3) Bal ve tereyağı ile servis yapın.',
 20, 320, 'kolay', 'kahvaltı,tatlı,pratik', 'kahvaltılık',
 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600'),

-- ATIŞTIRMALIKLAR
('Patates Kızartması',
 'patates, sıvı yağ, tuz',
 '1) Patatesleri doğrayın.\n2) Kızgın yağda kızartın.\n3) Tuzlayıp servis yapın.',
 20, 280, 'kolay', 'atıştırmalık,fast food,pratik', 'atıştırmalık',
 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600'),

('Soğan Halkası',
 'soğan, un, yumurta, süt, sıvı yağ, tuz',
 '1) Soğanları halka şeklinde kesin.\n2) Hamura bulayın.\n3) Kızgın yağda kızartın.',
 25, 240, 'kolay', 'atıştırmalık,kızartma,pratik', 'atıştırmalık',
 'images/soğan halkası.jpg'),

('Mısır Gevreği Tavuk',
 'tavuk göğsü, mısır gevreği, yumurta, un, sıvı yağ, tuz',
 '1) Tavuğu hazırlayın.\n2) Un, yumurta ve gevreğe bulayın.\n3) Kızartın.',
 30, 380, 'kolay', 'atıştırmalık,tavuk,kızartma', 'atıştırmalık',
 'https://images.unsplash.com/photo-1562967914-608f82629710?w=600'),

('Patates Püresi',
 'patates, süt, tereyağı, tuz, karabiber',
 '1) Patatesleri haşlayın.\n2) Ezin.\n3) Süt ve tereyağı ekleyip karıştırın.',
 25, 200, 'kolay', 'yan yemek,vejetaryen,pratik', 'yan yemek',
 'images/patates püresi.jpg'),

-- İÇECEKLER
('Ayran',
 'yoğurt, su, tuz',
 '1) Yoğurt ve suyu karıştırın.\n2) Tuz ekleyin.\n3) Köpürtün.',
 5, 50, 'kolay', 'içecek,sağlıklı,geleneksel', 'içecek',
 'images/ayran.jpg'),

('Limonata',
 'limon, su, şeker, nane',
 '1) Limon suyunu sıkın.\n2) Su ve şeker ekleyin.\n3) Nane ile servis yapın.',
 10, 80, 'kolay', 'içecek,serinletici,yaz', 'içecek',
 'images/limonata.jpg'),

('Türk Kahvesi',
 'kahve, su, şeker',
 '1) Kahve ve şekeri karıştırın.\n2) Su ekleyin.\n3) Yavaş ateşte pişirin.',
 10, 30, 'kolay', 'içecek,kahve,geleneksel', 'içecek',
 'https://images.unsplash.com/photo-1514481538271-cf9f99627ab4?w=600'),

-- DİĞER ÖZEL TARİFLER
('Kuru Fasulye',
 'kuru fasulye, soğan, domates salçası, biber salçası, zeytinyağı, tuz, karabiber',
 '1) Fasulyeleri ıslatın.\n2) Haşlayın.\n3) Soğan ve salçayla kavurup pişirin.',
 90, 280, 'kolay', 'ana yemek,bakliyat,geleneksel', 'ana yemek',
 'images/kuru fasulye.jpg'),

('Nohutlu Pilav',
 'pirinç, nohut, tereyağı, su, tuz',
 '1) Nohutu haşlayın.\n2) Pirinçle karıştırın.\n3) Su ve tuz ekleyip pişirin.',
 50, 320, 'kolay', 'pilav,bakliyat,doyurucu', 'pilav',
 'images/nohutlu pilav.jpg'),

('Karnabahar Kızartması',
 'karnabahar, un, yumurta, sıvı yağ, tuz',
 '1) Karnabaharı haşlayın.\n2) Hamura bulayın.\n3) Kızgın yağda kızartın.',
 30, 240, 'kolay', 'yan yemek,vejetaryen,kızartma', 'yan yemek',
 'images/karnabahar kızartması.jpg'),

('Patlıcan Kızartması',
 'patlıcan, un, yumurta, sıvı yağ, tuz, yoğurt, sarımsak',
 '1) Patlıcanları dilimleyin.\n2) Hamura bulayın.\n3) Kızartın.\n4) Sarımsaklı yoğurtla servis yapın.',
 35, 280, 'kolay', 'yan yemek,kızartma,pratik', 'yan yemek',
 'images/patlıcan kızartması.jpg'),

('Kabak Mücver',
 'kabak, yumurta, un, soğan, dereotu, beyaz peynir, sıvı yağ, tuz',
 '1) Kabakları rendeleyin.\n2) Malzemeleri karıştırın.\n3) Tavada pişirin.',
 30, 220, 'kolay', 'atıştırmalık,vejetaryen,pratik', 'atıştırmalık',
 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=600'),

('Havuçlu Kek',
 'havuç, un, yumurta, şeker, sıvı yağ, kabartma tozu, tarçın, ceviz',
 '1) Havucu rendeleyin.\n2) Hamuru hazırlayın.\n3) Fırında pişirin.',
 50, 380, 'orta', 'tatlı,kek,fırın', 'tatlı',
 'images/havuc_kek.jpg'),

('İskender Kebap',
 'döner eti, yoğurt, domates sosu, tereyağı, pide ekmeği',
 '1) Pide ekmeğini dilimleyin.\n2) Döner etini dizin.\n3) Sos ve yoğurt ekleyin.\n4) Tereyağı ile servis yapın.',
 30, 550, 'orta', 'ana yemek,et,özel', 'ana yemek',
 'images/iskender.jpg'),

('Lahmacun',
 'yufka, kıyma, soğan, domates, yeşil biber, maydanoz, biber salçası, baharatlar',
 '1) İç harcı hazırlayın.\n2) Hamuru açın.\n3) Harcı yayın.\n4) Fırında pişirin.',
 60, 320, 'orta', 'hamur işi,et,geleneksel', 'börek',
 'images/lahmacun.jpg'),

('Adana Kebap',
 'kıyma, kuyruk yağı, pul biber, kimyon, tuz, karabiber',
 '1) Kıymayı baharatlarla yoğurun.\n2) Şişe geçirin.\n3) Közde pişirin.',
 40, 480, 'orta', 'et,ızgara,özel', 'ana yemek',
 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=600');

-- ============================================================
-- TARİF-MALZEME İLİŞKİLERİ (Otomatik bağlantılar)
-- ============================================================

-- Çorba malzemeleri
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Mercimek Çorbası' AND i.name IN ('kırmızı mercimek','soğan','havuç','patates','zeytinyağı','tuz','kimyon','limon'))
  OR (r.title = 'Domates Çorbası' AND i.name IN ('domates','soğan','sarımsak','zeytinyağı','tuz','karabiber','un','tereyağı'))
  OR (r.title = 'Ezogelin Çorbası' AND i.name IN ('kırmızı mercimek','bulgur','pirinç','soğan','biber salçası','domates salçası','tuz','nane','tereyağı'))
  OR (r.title = 'Tavuk Çorbası' AND i.name IN ('tavuk göğsü','havuç','patates','makarna','su','tuz','karabiber','limon'))
  OR (r.title = 'Yayla Çorbası' AND i.name IN ('yoğurt','pirinç','un','yumurta','nane','tuz','tereyağı'));

-- Ana yemek malzemeleri
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'İzmir Köfte' AND i.name IN ('kıyma','yumurta','un','soğan','domates','yeşil biber','patates','zeytinyağı','tuz','karabiber'))
  OR (r.title = 'Etli Nohut' AND i.name IN ('kuşbaşı et','nohut','soğan','domates salçası','tuz','karabiber','kimyon'))
  OR (r.title = 'Karnıyarık' AND i.name IN ('patlıcan','kıyma','soğan','domates','yeşil biber','sarımsak','domates salçası','tuz'))
  OR (r.title = 'Mantı' AND i.name IN ('un','yumurta','kıyma','soğan','yoğurt','sarımsak','tereyağı','pul biber'))
  OR (r.title = 'Hünkar Beğendi' AND i.name IN ('kuşbaşı et','patlıcan','süt','un','tereyağı','kaşar peyniri','soğan','domates salçası'))
  OR (r.title = 'Tavuk Sote' AND i.name IN ('tavuk göğsü','soğan','sarımsak','yeşil biber','domates','zeytinyağı','tuz','karabiber'))
  OR (r.title = 'Fırında Tavuk' AND i.name IN ('tavuk but','patates','havuç','soğan','zeytinyağı','kekik','tuz','karabiber','limon'))
  OR (r.title = 'Tavuk Şiş' AND i.name IN ('tavuk göğsü','yoğurt','zeytinyağı','sarımsak','kekik','tuz','karabiber','limon'))
  OR (r.title = 'Tavuk Dürum' AND i.name IN ('tavuk göğsü','marul','domates','soğan','mayonez','ketçap','tuz','karabiber'))
  OR (r.title = 'İskender Kebap' AND i.name IN ('yoğurt','domates','tereyağı'))
  OR (r.title = 'Adana Kebap' AND i.name IN ('kıyma','pul biber','kimyon','tuz','karabiber'));

-- Zeytinyağlılar
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'İmam Bayıldı' AND i.name IN ('patlıcan','soğan','domates','sarımsak','maydanoz','zeytinyağı','şeker','tuz'))
  OR (r.title = 'Zeytinyağlı Fasulye' AND i.name IN ('fasulye','soğan','domates','zeytinyağı','şeker','tuz','limon'))
  OR (r.title = 'Zeytinyağlı Barbunya' AND i.name IN ('barbunya','soğan','havuç','patates','domates','zeytinyağı','şeker','tuz'))
  OR (r.title = 'Pırasa' AND i.name IN ('pırasa','havuç','pirinç','zeytinyağı','şeker','tuz','limon'));

-- Makarna ve pilavlar
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Kıymalı Makarna' AND i.name IN ('makarna','kıyma','soğan','sarımsak','domates salçası','tuz','karabiber','zeytinyağı'))
  OR (r.title = 'Spaghetti Bolonez' AND i.name IN ('makarna','kıyma','domates','soğan','sarımsak','zeytinyağı','tuz','karabiber'))
  OR (r.title = 'Makarna' AND i.name IN ('makarna','tuz','su','zeytinyağı'))
  OR (r.title = 'Pirinç Pilavı' AND i.name IN ('pirinç','tereyağı','su','tuz'))
  OR (r.title = 'Şehriyeli Pilav' AND i.name IN ('pirinç','şehriye','tereyağı','su','tuz'))
  OR (r.title = 'İç Pilav' AND i.name IN ('pirinç','kuşbaşı et','soğan','tarçın','tereyağı'))
  OR (r.title = 'Nohutlu Pilav' AND i.name IN ('pirinç','nohut','tereyağı','su','tuz'));

-- Börekler
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Kol Böreği' AND i.name IN ('peynir','maydanoz','yumurta','süt','sıvı yağ'))
  OR (r.title = 'Su Böreği' AND i.name IN ('peynir','maydanoz','yumurta','süt','tereyağı'))
  OR (r.title = 'Gözleme' AND i.name IN ('un','su','tuz','patates','peynir','maydanoz','zeytinyağı'))
  OR (r.title = 'Sigara Böreği' AND i.name IN ('beyaz peynir','maydanoz','kıyma','sıvı yağ'))
  OR (r.title = 'Lahmacun' AND i.name IN ('kıyma','soğan','domates','yeşil biber','maydanoz','biber salçası'));

-- Salatalar
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Çoban Salata' AND i.name IN ('domates','salatalık','yeşil biber','soğan','maydanoz','zeytinyağı','limon','tuz'))
  OR (r.title = 'Mevsim Salata' AND i.name IN ('domates','salatalık','havuç','zeytinyağı','limon','tuz'))
  OR (r.title = 'Çıtır Tavuk Salata' AND i.name IN ('tavuk göğsü','domates','mısır','zeytinyağı','limon','tuz','un','yumurta'));

-- Tatlılar
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Sütlaç' AND i.name IN ('pirinç','süt','şeker','nişasta'))
  OR (r.title = 'Kazandibi' AND i.name IN ('süt','şeker','tavuk göğsü','nişasta'))
  OR (r.title = 'İrmik Helvası' AND i.name IN ('şeker','tereyağı','süt'))
  OR (r.title = 'Revani' AND i.name IN ('yumurta','şeker','yoğurt','un'))
  OR (r.title = 'Baklava' AND i.name IN ('ceviz','şeker','tereyağı'))
  OR (r.title = 'Kadayıf' AND i.name IN ('tereyağı','ceviz'))
  OR (r.title = 'Muhallebi' AND i.name IN ('süt','şeker','nişasta'))
  OR (r.title = 'Havuçlu Kek' AND i.name IN ('havuç','un','yumurta','şeker','sıvı yağ','tarçın','ceviz'));

-- Kahvaltılıklar
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Menemen' AND i.name IN ('yumurta','domates','yeşil biber','soğan','zeytinyağı','tuz','karabiber'))
  OR (r.title = 'Sahanda Yumurta' AND i.name IN ('yumurta','tereyağı','tuz','karabiber'))
  OR (r.title = 'Omlet' AND i.name IN ('yumurta','süt','peynir','soğan','yeşil biber','tereyağı','tuz'))
  OR (r.title = 'Pankek' AND i.name IN ('un','yumurta','süt','şeker','tereyağı','bal'));

-- Atıştırmalıklar ve yan yemekler
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Patates Kızartması' AND i.name IN ('patates','sıvı yağ','tuz'))
  OR (r.title = 'Soğan Halkası' AND i.name IN ('soğan','un','yumurta','süt','sıvı yağ','tuz'))
  OR (r.title = 'Mısır Gevreği Tavuk' AND i.name IN ('tavuk göğsü','mısır','yumurta','un','sıvı yağ','tuz'))
  OR (r.title = 'Patates Püresi' AND i.name IN ('patates','süt','tereyağı','tuz','karabiber'))
  OR (r.title = 'Kuru Fasulye' AND i.name IN ('kuru fasulye','soğan','domates salçası','biber salçası','zeytinyağı','tuz','karabiber'))
  OR (r.title = 'Karnabahar Kızartması' AND i.name IN ('karnabahar','un','yumurta','sıvı yağ','tuz'))
  OR (r.title = 'Patlıcan Kızartması' AND i.name IN ('patlıcan','un','yumurta','sıvı yağ','tuz','yoğurt','sarımsak'))
  OR (r.title = 'Kabak Mücver' AND i.name IN ('kabak','yumurta','un','soğan','dereotu','beyaz peynir','sıvı yağ','tuz'));

-- İçecekler
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Ayran' AND i.name IN ('yoğurt','su','tuz'))
  OR (r.title = 'Limonata' AND i.name IN ('limon','su','şeker','nane'));

-- ============================================================
-- GÖRÜNÜM VE İNDEKSLER
-- ============================================================

CREATE VIEW `recipe_stats` AS
SELECT
  (SELECT COUNT(*) FROM recipes) AS total_recipes,
  (SELECT COUNT(*) FROM ingredients) AS total_ingredients,
  (SELECT COUNT(*) FROM pantry) AS pantry_items;

-- Performans için ek indeksler
ALTER TABLE `recipes` ADD FULLTEXT KEY `ft_recipes_search` (`title`,`tags`,`ingredients_text`);

-- ============================================================
-- BAŞARIYLA TAMAMLANDI
-- ============================================================
SELECT 'Veritabanı başarıyla oluşturuldu!' AS mesaj,
       (SELECT COUNT(*) FROM recipes) AS tarif_sayisi,
       (SELECT COUNT(*) FROM ingredients) AS malzeme_sayisi;