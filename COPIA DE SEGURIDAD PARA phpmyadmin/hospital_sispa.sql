-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 14-10-2026 a las 02:57:05
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `hospital_sispa`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `registros`
--

CREATE TABLE `registros` (
  `id` int(11) NOT NULL,
  `area` varchar(50) DEFAULT NULL,
  `fecha` varchar(50) DEFAULT NULL,
  `responsable` varchar(255) DEFAULT NULL,
  `estudio` varchar(255) DEFAULT NULL,
  `clasificacion` varchar(50) DEFAULT NULL,
  `edad` int(11) DEFAULT NULL,
  `sexo` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `registros_estudios`
--

CREATE TABLE `registros_estudios` (
  `id` int(11) NOT NULL,
  `area` varchar(50) DEFAULT NULL,
  `fecha` varchar(20) DEFAULT NULL,
  `medico` varchar(150) DEFAULT NULL,
  `estudio` varchar(150) DEFAULT NULL,
  `clasificacion` varchar(50) DEFAULT NULL,
  `edad` int(11) DEFAULT NULL,
  `sexo` varchar(20) DEFAULT NULL,
  `grupo_id` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `registros_estudios`
--

INSERT INTO `registros_estudios` (`id`, `area`, `fecha`, `medico`, `estudio`, `clasificacion`, `edad`, `sexo`, `grupo_id`) VALUES
(68, 'TAC', '13/10/2026', 'T.R. MARIO RAMOS DE LA CRUZ', 'CRANEO SIMPLE', 'EXT', 30, 'HOMBRE', 'acde2146-95be-4aba-b4f5-dfd71d72d98b'),
(69, 'TAC', '13/10/2026', 'T.R. MARIO RAMOS DE LA CRUZ', 'ABD. SUP. SIMPLE', 'EXT', 30, 'HOMBRE', 'acde2146-95be-4aba-b4f5-dfd71d72d98b'),
(70, 'RX', '13/10/2026', 'T.R. ANALLELY MELGAREJO BALTAZAR', 'CRANEO', 'HOSP', 8, 'HOMBRE', '7638e9ba-dead-49c4-b063-54457d240561'),
(73, 'TAC', '13/10/2026', 'T.R. MARIO RAMOS DE LA CRUZ', 'CRANEO SIMPLE', 'EXT', 30, 'HOMBRE', '21656965-9587-4bc7-a374-b9b8ce725a61'),
(74, 'TAC', '13/10/2026', 'T.R. MARIO RAMOS DE LA CRUZ', 'TX S Y C', 'EXT', 30, 'HOMBRE', '21656965-9587-4bc7-a374-b9b8ce725a61'),
(75, 'TAC', '13/10/2026', 'T.R. MARIO RAMOS DE LA CRUZ', 'CRANEO SIMPLE', 'EXT', 55, 'HOMBRE', 'c3e7cb67-b1a8-4747-aa36-2d4088b76140'),
(76, 'TAC', '13/10/2026', 'T.R. MARIO RAMOS DE LA CRUZ', 'TX S Y C', 'EXT', 55, 'HOMBRE', 'c3e7cb67-b1a8-4747-aa36-2d4088b76140'),
(77, 'RX', '13/10/2026', 'T.R. ANALLELY MELGAREJO BALTAZAR', 'MIEMBROS SUP.', 'HOSP', 60, 'HOMBRE', 'f117974d-06fd-48b9-bbd9-7d366a0d435f'),
(78, 'RX', '13/10/2026', 'T.R. ANALLELY MELGAREJO BALTAZAR', 'CRANEO', 'HOSP', 30, 'HOMBRE', '645f66b4-3aef-4a20-a0a4-3a9bb7d343a5'),
(79, 'RX', '13/10/2026', 'T.R. ANALLELY MELGAREJO BALTAZAR', 'COLUMNA', 'HOSP', 30, 'HOMBRE', '645f66b4-3aef-4a20-a0a4-3a9bb7d343a5'),
(85, 'USG', '13/10/2026', 'T.R. BLANCA ISABEL APARICIO ZAPATA', 'ABDOMEN', 'EXT', 45, 'HOMBRE', 'deba8bf0-95cc-490c-8fae-f83fb75f6d96'),
(86, 'USG', '13/10/2026', 'T.R. BLANCA ISABEL APARICIO ZAPATA', 'CUELLO', 'EXT', 45, 'HOMBRE', 'deba8bf0-95cc-490c-8fae-f83fb75f6d96'),
(87, 'USG', '13/10/2026', 'T.R. BLANCA ISABEL APARICIO ZAPATA', 'ABDOMEN', 'EXT', 45, 'HOMBRE', '7eeb751e-fea8-4083-bbc1-2ef663922295'),
(88, 'USG', '13/10/2026', 'T.R. BLANCA ISABEL APARICIO ZAPATA', 'CUELLO', 'EXT', 45, 'HOMBRE', '7eeb751e-fea8-4083-bbc1-2ef663922295'),
(89, 'USG', '13/10/2026', 'T.R. BLANCA ISABEL APARICIO ZAPATA', 'ABDOMEN', 'EXT', 56, 'HOMBRE', '9cdb7636-4b32-49b0-bce7-64f077d8a61c'),
(90, 'USG', '13/10/2026', 'T.R. BLANCA ISABEL APARICIO ZAPATA', 'CUELLO', 'EXT', 56, 'HOMBRE', '9cdb7636-4b32-49b0-bce7-64f077d8a61c');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `registros`
--
ALTER TABLE `registros`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `registros_estudios`
--
ALTER TABLE `registros_estudios`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `registros`
--
ALTER TABLE `registros`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `registros_estudios`
--
ALTER TABLE `registros_estudios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=91;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
