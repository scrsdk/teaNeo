-- phpMyAdmin SQL Dump
-- version 4.9.7
-- https://www.phpmyadmin.net/
--
-- Хост: localhost
-- Время создания: Апр 01 2026 г., 18:24
-- Версия сервера: 5.7.21-20-beget-5.7.21-20-1-log
-- Версия PHP: 5.6.40

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `q97902ug_app`
--

-- --------------------------------------------------------

--
-- Структура таблицы `contacts`
--
-- Создание: Мар 29 2026 г., 17:15
--

DROP TABLE IF EXISTS `contacts`;
CREATE TABLE `contacts` (
  `id` int(11) NOT NULL,
  `owner_username` varchar(50) NOT NULL,
  `contact_username` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Структура таблицы `messages`
--
-- Создание: Мар 29 2026 г., 17:15
-- Последнее обновление: Мар 29 2026 г., 17:35
--

DROP TABLE IF EXISTS `messages`;
CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `sender` varchar(50) DEFAULT NULL,
  `receiver` varchar(50) DEFAULT NULL,
  `message` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) DEFAULT '0',
  `is_pinned` tinyint(1) DEFAULT '0',
  `is_edited` tinyint(1) DEFAULT '0',
  `reply_to_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `messages`
--

INSERT INTO `messages` (`id`, `sender`, `receiver`, `message`, `created_at`, `is_read`, `is_pinned`, `is_edited`, `reply_to_id`) VALUES
(1, 'melisov', 'Избранное', '12345678', '2026-03-29 16:44:41', 0, 0, 0, NULL),
(2, 'melisov', 'Избранное', '567657567', '2026-03-29 16:49:14', 0, 0, 0, NULL),
(3, 'melisov', 'Избранное', 'tyjytjytjyjtyj', '2026-03-29 16:53:23', 0, 0, 0, NULL),
(4, 'melisov', 'Избранное', 'tyjtyjytj', '2026-03-29 16:53:24', 0, 0, 0, NULL),
(5, 'melisov', 'Избранное', 'tjyytjytjtj', '2026-03-29 16:53:28', 0, 0, 0, NULL),
(6, 'melisov', 'Избранное', 'ijhkghgkhkjh', '2026-03-29 16:56:43', 0, 0, 0, NULL),
(7, '12345', 'melisov', 'hello', '2026-03-29 17:01:51', 0, 0, 0, NULL),
(8, 'melisov', '12345', 'ghnhgnh', '2026-03-29 17:13:06', 0, 0, 0, NULL),
(11, '123455', 'melisov', 'dddddddd9999', '2026-03-29 17:34:50', 0, 1, 1, NULL),
(12, '123455', 'melisov', '8989', '2026-03-29 17:35:15', 0, 0, 0, 11);

-- --------------------------------------------------------

--
-- Структура таблицы `users`
--
-- Создание: Мар 29 2026 г., 16:12
-- Последнее обновление: Апр 01 2026 г., 15:20
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `verify` tinyint(1) DEFAULT '0',
  `contact_id` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Дамп данных таблицы `users`
--

INSERT INTO `users` (`id`, `phone`, `username`, `password`, `verify`, `contact_id`) VALUES
(1, '+7 0000', 'melisov', '$2y$10$u.wlNcjptBmQpzWs0MFgq.yXRVJXHcSEO9iL2ZXzTPInoCSQYSUWq', 0, NULL),
(4, '+ 70000', '12345', '$2y$10$r24XQYS0jF4ueib95Ah/lOr2U3F0xgEtFzrhq4LxusEy8GYF7CqnK', 0, NULL),
(5, '70000', '123455', '$2y$10$ZvdPjfAgBVSPBc139KMmgOQOTFYES.Y.nYt0Q57pu4JqfCgzO87su', 0, NULL),
(6, '700000', 'test', '$2y$10$zD1Psz3bBqq6R6bDTGk6ieudrSL72p3vBKqThy8zKDK40qejmvpT2', 0, NULL);

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `contacts`
--
ALTER TABLE `contacts`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `contacts`
--
ALTER TABLE `contacts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT для таблицы `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
