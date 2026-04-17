CREATE TABLE IF NOT EXISTS `custom_level_stats` (
  `guid` int(10) unsigned NOT NULL,
  `str` int(10) unsigned NOT NULL DEFAULT '0',
  `agi` int(10) unsigned NOT NULL DEFAULT '0',
  `sta` int(10) unsigned NOT NULL DEFAULT '0',
  `int` int(10) unsigned NOT NULL DEFAULT '0',
  `spi` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
