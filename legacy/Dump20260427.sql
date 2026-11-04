CREATE DATABASE  IF NOT EXISTS `day05` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `day05`;
-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: day05
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `address` varchar(100) DEFAULT NULL,
  `email` varchar(60) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customers`
--

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;
INSERT INTO `customers` VALUES (1,'김민준','010-1234-5678','부산시 해운대구 우동 101','minjun@email.com','2026-04-22 19:15:01'),(2,'이서연','010-2345-6789','부산시 수영구 광안동 202','seoyeon@email.com','2026-04-22 19:15:01'),(3,'박지호','010-3456-7890','부산시 남구 대연동 303',NULL,'2026-04-22 19:15:01'),(4,'최수아','010-4567-8901','부산시 동래구 온천동 404','sua@email.com','2026-04-22 19:15:01'),(5,'정우진','010-5678-9012','부산시 부산진구 전포동 505','woojin@email.com','2026-04-22 19:15:01'),(6,'강하은','010-6789-0123','부산시 연제구 거제동 606',NULL,'2026-04-22 19:15:01'),(7,'조현서','010-7890-1234','부산시 사하구 하단동 707','hyunseo@email.com','2026-04-22 19:15:01'),(8,'윤도윤','010-8901-2345','부산시 북구 구포동 808','doyoon@email.com','2026-04-22 19:15:01'),(9,'임지아','010-9012-3456','부산시 강서구 명지동 909',NULL,'2026-04-22 19:15:01'),(10,'한준서','010-0123-4567','부산시 기장군 일광읍 010','junser@email.com','2026-04-22 19:15:01');
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menus`
--

DROP TABLE IF EXISTS `menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menus` (
  `id` int NOT NULL AUTO_INCREMENT,
  `restaurant_id` int NOT NULL,
  `name` varchar(40) NOT NULL,
  `price` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menus`
--

LOCK TABLES `menus` WRITE;
/*!40000 ALTER TABLE `menus` DISABLE KEYS */;
INSERT INTO `menus` VALUES (1,1,'후라이드 치킨',16000),(2,1,'양념 치킨',17000),(3,1,'간장 치킨',18000),(4,2,'불고기 피자',22000),(5,2,'콤비네이션 피자',23000),(6,3,'짜장면',6000),(7,3,'짬뽕',7000),(8,3,'탕수육',18000),(9,4,'삼겹살 2인분',28000),(10,4,'항정살 2인분',33000),(11,5,'떡볶이',5000),(12,5,'순대',4500),(13,5,'튀김 세트',6000),(14,6,'연어 회덮밥',15000),(15,6,'참치 회덮밥',13000),(16,7,'스모크 버거',10000),(17,7,'치즈 버거',9000),(18,8,'치즈 돈까스',12000),(19,8,'로스 돈까스',10000),(20,9,'돼지 국밥',9000),(21,9,'내장 국밥',9500),(22,10,'매운 떡볶이',5500),(23,10,'치즈 떡볶이',6500);
/*!40000 ALTER TABLE `menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `restaurant_id` int NOT NULL,
  `menu_id` int NOT NULL,
  `quantity` int DEFAULT '1',
  `total_price` int NOT NULL,
  `order_date` datetime DEFAULT NULL,
  `delivery_fee` int DEFAULT '3000',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES (1,1,1,1,1,16000,'2025-01-03 12:10:00',3000),(2,2,9,20,1,9000,'2025-01-05 18:30:00',2000),(3,3,3,6,1,6000,'2025-01-07 19:00:00',2000),(4,4,9,21,1,9500,'2025-01-09 19:30:00',2000),(5,5,5,11,1,5000,'2025-01-11 20:00:00',2000),(6,6,6,14,1,15000,'2025-01-13 12:45:00',3000),(7,7,7,16,1,10000,'2025-01-15 11:30:00',2500),(8,8,8,18,1,12000,'2025-01-17 13:00:00',2500),(9,9,9,20,1,9000,'2025-01-19 19:30:00',2000),(10,10,10,22,1,5500,'2025-01-21 21:00:00',2000),(11,1,1,2,1,15000,'2025-01-23 18:00:00',3000),(12,2,1,3,1,9000,'2025-01-25 12:30:00',3000),(13,3,5,12,1,4500,'2025-01-27 21:30:00',2000),(14,4,2,5,1,9000,'2025-02-02 18:30:00',3000),(15,5,3,7,1,7000,'2025-02-04 19:00:00',2000),(16,6,1,1,1,16000,'2025-02-06 12:00:00',3000),(17,7,6,15,1,13000,'2025-02-08 12:30:00',3000),(18,8,7,17,1,9000,'2025-02-10 11:00:00',2500),(19,9,8,19,1,10000,'2025-02-12 13:30:00',2500),(20,10,9,20,1,9000,'2025-02-14 19:00:00',2000),(21,1,10,23,1,6500,'2025-02-16 20:00:00',2000),(22,2,1,2,1,17000,'2025-02-18 18:00:00',3000),(23,3,5,13,1,6000,'2025-02-20 21:00:00',2000),(24,4,9,21,1,9500,'2025-02-22 19:30:00',2000),(25,5,2,4,1,9000,'2025-02-24 18:30:00',3000),(26,6,3,8,1,9000,'2025-02-26 19:00:00',2000),(27,7,1,3,1,9000,'2025-03-02 18:00:00',3000),(28,8,9,20,1,9000,'2025-03-04 19:00:00',2000),(29,9,6,14,1,15000,'2025-03-06 12:30:00',3000),(30,10,7,16,1,10000,'2025-03-08 11:30:00',2500),(31,1,8,18,1,12000,'2025-03-10 13:00:00',2500),(32,2,10,22,1,5500,'2025-03-12 21:00:00',2000),(33,3,2,5,1,23000,'2025-03-14 18:30:00',3000),(34,4,1,1,1,16000,'2025-03-16 12:00:00',3000),(35,5,9,21,1,9500,'2025-03-18 19:30:00',2000),(36,6,5,11,2,10000,'2025-03-20 20:30:00',2000),(37,7,6,15,1,13000,'2025-03-22 12:45:00',3000),(38,8,3,6,1,6000,'2025-03-24 19:00:00',2000),(39,9,1,2,1,17000,'2025-03-28 18:00:00',3000),(40,10,1,1,1,16000,'2025-04-01 12:00:00',3000),(41,1,9,20,1,9000,'2025-04-03 19:00:00',2000),(42,2,7,17,1,9000,'2025-04-05 11:00:00',2500),(43,3,6,14,3,45000,'2025-04-07 13:00:00',3000),(44,4,8,19,1,10000,'2025-04-09 13:00:00',2500),(45,5,2,4,1,9000,'2025-04-11 18:30:00',3000),(46,6,10,23,1,6500,'2025-04-13 20:30:00',2000),(47,7,1,3,1,9000,'2025-04-15 18:00:00',3000),(48,8,9,21,1,9500,'2025-04-17 19:30:00',2000),(49,9,5,12,1,4500,'2025-04-19 21:30:00',2000),(50,10,9,20,1,9000,'2025-04-21 12:00:00',2000);
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `restaurants`
--

DROP TABLE IF EXISTS `restaurants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `restaurants` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `category` varchar(20) NOT NULL,
  `address` varchar(100) DEFAULT NULL,
  `rating` decimal(2,1) DEFAULT '4.0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `restaurants`
--

LOCK TABLES `restaurants` WRITE;
/*!40000 ALTER TABLE `restaurants` DISABLE KEYS */;
INSERT INTO `restaurants` VALUES (1,'해운대 치킨집','치킨','부산시 해운대구 우동 1번길',4.5),(2,'광안리 피자','피자','부산시 수영구 광안해변로 2',4.2),(3,'남포 짜장면','중식','부산시 중구 남포동 3번길',4.0),(4,'서면 삼겹살','한식','부산시 부산진구 서면로 4',4.7),(5,'동래 분식','분식','부산시 동래구 온천천로 5',3.9),(6,'기장 회덮밥','일식','부산시 기장군 기장읍 6번길',4.6),(7,'해운대 버거','패스트푸드','부산시 해운대구 해운대로 7',4.1),(8,'수영 돈까스','일식','부산시 수영구 수영로 8',4.3),(9,'부산진 국밥','한식','부산시 부산진구 가야대로 9',4.4),(10,'사직 떡볶이','분식','부산시 동래구 사직로 10',3.8);
/*!40000 ALTER TABLE `restaurants` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-27 19:19:04
