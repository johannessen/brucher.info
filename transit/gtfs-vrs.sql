# based on https://github.com/mauryquijada/gtfs-mysql

DROP TABLE IF EXISTS agency;
DROP TABLE IF EXISTS calendar;
DROP TABLE IF EXISTS calendar_dates;
DROP TABLE IF EXISTS feed_info;
DROP TABLE IF EXISTS frequencies;
DROP TABLE IF EXISTS routes;
DROP TABLE IF EXISTS shapes;
DROP TABLE IF EXISTS stops;
DROP TABLE IF EXISTS stop_times;
DROP TABLE IF EXISTS transfers;
DROP TABLE IF EXISTS trips;


CREATE TABLE `agency` (
    agency_id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    agency_name VARCHAR(255) NOT NULL,
    agency_url VARCHAR(255) NOT NULL,
    agency_timezone VARCHAR(100) NOT NULL,
    agency_lang VARCHAR(100),
    agency_phone VARCHAR(100),
    agency_fare_url VARCHAR(255)
) ENGINE=MyISAM;

CREATE TABLE `calendar_dates` (
    service_id INT(12) NOT NULL,
    `date` VARCHAR(8) NOT NULL,
    exception_type TINYINT(2) NOT NULL,
    KEY `exception_type` (exception_type),
    id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT
) ENGINE=MyISAM;

CREATE TABLE `calendar` (
    service_id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    monday TINYINT(1) NOT NULL,
    tuesday TINYINT(1) NOT NULL,
    wednesday TINYINT(1) NOT NULL,
    thursday TINYINT(1) NOT NULL,
    friday TINYINT(1) NOT NULL,
    saturday TINYINT(1) NOT NULL,
    sunday TINYINT(1) NOT NULL,
    start_date VARCHAR(8) NOT NULL,	
    end_date VARCHAR(8) NOT NULL
) ENGINE=MyISAM;

CREATE TABLE `feed_info` (
    feed_publisher_name VARCHAR(100),
    feed_publisher_url VARCHAR(255),
    feed_lang VARCHAR(100),
    feed_start_date VARCHAR(8),
    feed_end_date VARCHAR(8),
    feed_version VARCHAR(100),
    id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT
) ENGINE=MyISAM;

CREATE TABLE `frequencies` (
    trip_id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    start_time VARCHAR(8) NOT NULL,
    end_time VARCHAR(8) NOT NULL,
    headway_secs INT(5) NOT NULL,
    exact_times TINYINT(1)
) ENGINE=MyISAM;

CREATE TABLE `routes` (
    route_id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    agency_id INT(12),
    route_short_name VARCHAR(50) NOT NULL,
    route_long_name VARCHAR(255) NOT NULL,
    route_desc VARCHAR(255),
    route_type VARCHAR(2) NOT NULL,
    route_url VARCHAR(255),
    route_color VARCHAR(255),
    route_text_color VARCHAR(255),
    KEY `agency_id` (agency_id),
    KEY `route_type` (route_type)
) ENGINE=MyISAM;

CREATE TABLE `shapes` (
    shape_id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    shape_pt_lat DECIMAL(8,6) NOT NULL,
    shape_pt_lon DECIMAL(8,6) NOT NULL,
    shape_pt_sequence INT(5) NOT NULL,
    shape_dist_traveled DECIMAL(6,3)
) ENGINE=MyISAM;

CREATE TABLE `stop_times` (
    trip_id VARCHAR(50) NOT NULL,
    arrival_time VARCHAR(8) NOT NULL,
    departure_time VARCHAR(8) NOT NULL,
    stop_id INT(12) NOT NULL,
    stop_sequence INT unsigned NOT NULL,
    stop_headsign VARCHAR(50),
    pickup_type VARCHAR(2),
    drop_off_type VARCHAR(2),
    shape_dist_traveled DECIMAL(6,3),
    KEY `stop_id` (stop_id),
    KEY `stop_sequence` (stop_sequence),
    KEY `pickup_type` (pickup_type),
    KEY `drop_off_type` (drop_off_type),
    id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT
) ENGINE=MyISAM;

CREATE TABLE `stops` (
    stop_id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    stop_code VARCHAR(50),
    stop_name VARCHAR(255) NOT NULL,
    stop_desc VARCHAR(255),
    stop_lat DECIMAL(10,6) NOT NULL,
    stop_lon DECIMAL(10,6) NOT NULL,
    zone_id VARCHAR(255),
    stop_url VARCHAR(255),
    location_type TINYINT(1),
    parent_station VARCHAR(100),
    stop_timezone VARCHAR(50),
    KEY `zone_id` (zone_id),
    KEY `stop_lat` (stop_lat),
    KEY `stop_lon` (stop_lon),
    KEY `location_type` (location_type),
    KEY `parent_station` (parent_station)
) ENGINE=MyISAM;

CREATE TABLE `transfers` (
    from_stop_id INT(12) NOT NULL,
    to_stop_id INT(12) NOT NULL,
    transfer_type TINYINT(1) NOT NULL,
    min_transfer_time INT(5),
    id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT
) ENGINE=MyISAM;

CREATE TABLE `trips` (
    route_id INT(12) NOT NULL,
    service_id INT(12) NOT NULL,
    trip_id VARCHAR(50) NOT NULL,
    trip_headsign VARCHAR(255),
    direction_id TINYINT(1), #0 for one direction, 1 for another.
    block_id VARCHAR(100),
    shape_id INT(12),
    id INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    KEY `trip_id` (trip_id),
    KEY `service_id` (service_id),
    KEY `direction_id` (direction_id),
    KEY `block_id` (block_id),
    KEY `shape_id` (shape_id)
) ENGINE=MyISAM;

