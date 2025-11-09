-- SAFE RESET + CREATE for dolap_db
-- Fixes error #1451 by disabling FK checks and dropping children first
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS=0;

-- Drop view first if exists
DROP VIEW IF EXISTS `recipe_stats`;

-- Drop child tables first (order matters)
DROP TABLE IF EXISTS `recipe_ingredients`;
DROP TABLE IF EXISTS `user_favorites`;
DROP TABLE IF EXISTS `pantry_items`; -- legacy table name if it exists
DROP TABLE IF EXISTS `pantry`;
DROP TABLE IF EXISTS `recipes`;
DROP TABLE IF EXISTS `ingredients`;

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;


-- Akıllı Yemek Öneri Sistemi - Tam Şema
-- Güvenli: InnoDB, utf8mb4, FK'lar ve indeksler
-- Çalıştırma: phpMyAdmin > Import ile bu dosyayı seçin

-- 1) Veritabanı
CREATE DATABASE IF NOT EXISTS `dolap_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `dolap_db`;

-- 2) Tablo: ingredients
DROP TABLE IF EXISTS `ingredients`;
CREATE TABLE `ingredients` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `ux_ingredients_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3) Tablo: recipes
DROP TABLE IF EXISTS `recipes`;
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
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `ix_recipes_title` (`title`),
  KEY `ix_recipes_difficulty` (`difficulty`),
  KEY `ix_recipes_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4) Tablo: recipe_ingredients
DROP TABLE IF EXISTS `recipe_ingredients`;
CREATE TABLE `recipe_ingredients` (
  `recipe_id` INT NOT NULL,
  `ingredient_id` INT NOT NULL,
  PRIMARY KEY (`recipe_id`,`ingredient_id`),
  CONSTRAINT `fk_ri_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ri_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5) Tablo: pantry (tekil ingredient_id)
DROP TABLE IF EXISTS `pantry`;
CREATE TABLE `pantry` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `ingredient_id` INT NOT NULL,
  `added_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `ux_pantry_ingredient` (`ingredient_id`),
  CONSTRAINT `fk_pantry_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6) Tablo: user_favorites (session tabanlı)
DROP TABLE IF EXISTS `user_favorites`;
CREATE TABLE `user_favorites` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `session_id` VARCHAR(100) NOT NULL,
  `recipe_id` INT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `ix_uf_session` (`session_id`),
  KEY `ix_uf_recipe` (`recipe_id`),
  CONSTRAINT `fk_uf_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7) Tohum veriler (malzemeler)
INSERT INTO `ingredients` (`name`) VALUES
('domates'), ('soğan'), ('sarımsak'), ('zeytinyağı'), ('tuz'), ('biber'),
('biber salçası'), ('domates salçası'), ('un'), ('şeker'), ('yumurta'),
('süt'), ('yoğurt'), ('limon'), ('maydanoz'), ('nane'), ('kıyma'),
('tavuk'), ('pirinç'), ('bulgur'), ('makarna'), ('patates'), ('havuç'),
('bezelye'), ('mısır'), ('peynir'), ('tereyağı'), ('sıvıyağ'), ('kırmızı mercimek'),
('kimyon'), ('kuru soğan'), ('yeşil biber'), ('kırmızı biber'), ('salça'), ('su')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 8) Tohum veriler (tarifler)
INSERT INTO `recipes`
(`title`,`ingredients_text`,`instructions`,`prep_minutes`,`calories`,`difficulty`,`tags`,`image_url`) VALUES
('Domates Çorbası',
 'domates, soğan, sarımsak, zeytinyağı, tuz, biber, un, tereyağı',
 '1) Soğan ve sarımsağı zeytinyağında kavurun.\n2) Domatesleri ekleyip pişirin.\n3) Un ve tereyağı ile kıvam verin.\n4) Tuz ve biberle tatlandırın.',
 30,180,'kolay','çorba,vejetaryen,pratik','https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'),
('Tavuk Sote',
 'tavuk, soğan, sarımsak, yeşil biber, domates, zeytinyağı, tuz, biber',
 '1) Tavuğu yüksek ateşte soteleyin.\n2) Sebzeleri ekleyin.\n3) Kısık ateşte yumuşayana kadar pişirin.',
 45,320,'orta','ana yemek,tavuk,pratik','https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400'),
('Mercimek Çorbası',
 'kırmızı mercimek, soğan, havuç, patates, zeytinyağı, tuz, kimyon, limon',
 '1) Mercimek ve sebzeleri haşlayın.\n2) Blenderdan geçirin.\n3) Kimyon ve limonla servis edin.',
 40,220,'kolay','çorba,vejetaryen,sağlıklı','https://images.unsplash.com/photo-1585938381612-c19e5359f15e?w=400'),
('Makarna',
 'makarna, tuz, su, zeytinyağı',
 '1) Tuzu eklediğiniz suyu kaynatın.\n2) Makarnayı paketteki süre kadar haşlayın.\n3) Süzün, zeytinyağı ile karıştırın.',
 15,280,'kolay','pratik,makarna,vejetaryen','https://images.unsplash.com/photo-1555949258-eb67b1ef0ce2?w=400'),
('Kıymalı Makarna',
 'makarna, kıyma, soğan, sarımsak, domates salçası, tuz, biber, zeytinyağı',
 '1) Makarnayı haşlayın.\n2) Kıymayı soğan ve sarımsakla kavurun.\n3) Salçayı ekleyin, sosu makarnayla birleş tirin.',
 25,350,'kolay','makarna,et,pratik','https://images.unsplash.com/photo-1608897013039-887f21d8cbfb?w=400');

-- 9) Tarif-malzeme ilişkileri
-- Not: Basitliği korumak için INSERT ... SELECT yapısı kullanıldı.
INSERT IGNORE INTO `recipe_ingredients` (`recipe_id`, `ingredient_id`)
SELECT r.id, i.id FROM recipes r JOIN ingredients i
  ON (r.title = 'Domates Çorbası' AND i.name IN ('domates','soğan','sarımsak','zeytinyağı','tuz','biber','un','tereyağı'))
  OR (r.title = 'Tavuk Sote' AND i.name IN ('tavuk','soğan','sarımsak','yeşil biber','domates','zeytinyağı','tuz','biber'))
  OR (r.title = 'Mercimek Çorbası' AND i.name IN ('kırmızı mercimek','soğan','havuç','patates','zeytinyağı','tuz','kimyon','limon'))
  OR (r.title = 'Makarna' AND i.name IN ('makarna','tuz','su','zeytinyağı'))
  OR (r.title = 'Kıymalı Makarna' AND i.name IN ('makarna','kıyma','soğan','sarımsak','domates salçası','tuz','biber','zeytinyağı'));

-- 10) Görünüm: Basit istatistikler (opsiyonel)
DROP VIEW IF EXISTS `recipe_stats`;
CREATE VIEW `recipe_stats` AS
SELECT
  (SELECT COUNT(*) FROM recipes) AS total_recipes,
  (SELECT COUNT(*) FROM ingredients) AS total_ingredients;

-- 11) Önerilen indeksler (opsiyonel ama hızlı arama için iyi)
-- ingredients.name zaten UNIQUE
-- recipes.title, recipes.difficulty üzerinde indeksler var
-- LIKE aramaları için FULLTEXT isterseniz (MySQL 5.6+ InnoDB destekler):
-- ALTER TABLE `recipes` ADD FULLTEXT KEY `ft_recipes_title_tags` (`title`,`tags`);
