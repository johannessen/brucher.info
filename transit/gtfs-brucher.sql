
/*!40101 SET NAMES utf8 */;
DROP TABLE IF EXISTS nice_stops;
CREATE TABLE nice_stops (
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL,
    stop_id INT(12) NOT NULL,
    hafas VARCHAR(6),
    brucher TINYINT(1)
) ENGINE=MyISAM;
INSERT INTO nice_stops (name, stop_id, brucher, hafas)
VALUES
	('Marienheide',4113,NULL,'70483'),
	('Stülinghausen',4227,1,'442223'),
	('Rodt',4226,1,'442224'),
	('Gemeindezentrum',4230,1,'442238'),
	('Gummersbach',3883,NULL,'GM'),
	('Wipperfürth',3416,NULL,NULL),
	('Hückeswagen',2955,NULL,'445100'),
	('Hückeswagen',3611,NULL,'444212'),
	('Hückeswagen',3613,NULL,'444210'),
	('Hückeswagen',3615,NULL,'444207'),
	('Remscheid-Lennep',4013,NULL,NULL),
	('Holzwipper',4240,NULL,NULL),
	('Müllenbach',4233,NULL,NULL),
	('Köln',36,NULL,'3392'),
	('Lüdenscheid',10588,NULL,'3782'),
	('Brügge',10894,NULL,'1213'),
	('Kierspe',4107,NULL,NULL),
	('Meinerzhagen',7892,NULL,'3950'),
	('Dieringhausen',3874,NULL,'363'),
	('Ründeroth',3862,NULL,'5218'),
	('Engelskirchen',3857,NULL,'1789');

\! echo "Create optimised tables ...";

\! echo "... brucher_routes";

DROP TABLE IF EXISTS brucher_routes;
CREATE TABLE brucher_routes LIKE routes;
INSERT INTO brucher_routes
SELECT r.*
FROM routes r
LEFT JOIN trips t USING (route_id)
LEFT JOIN stop_times st USING (trip_id)
LEFT JOIN nice_stops n USING (stop_id)
WHERE n.brucher = 1
GROUP BY route_id;

\! echo "... brucher_agency";

DROP TABLE IF EXISTS brucher_agency;
CREATE TABLE brucher_agency LIKE agency;
INSERT INTO brucher_agency
SELECT a.*
FROM agency a
LEFT JOIN routes r USING (agency_id)
WHERE route_id IN (SELECT route_id FROM brucher_routes)
GROUP BY agency_id;

\! echo "... brucher_trips";

DROP TABLE IF EXISTS brucher_trips;
CREATE TABLE brucher_trips LIKE trips;
INSERT INTO brucher_trips
SELECT t.*
FROM trips t
LEFT JOIN routes USING (route_id)
WHERE route_id IN (SELECT route_id FROM brucher_routes);

\! echo "... brucher_calendar";

DROP TABLE IF EXISTS brucher_calendar;
CREATE TABLE brucher_calendar LIKE calendar;
INSERT INTO brucher_calendar
SELECT c.*
FROM calendar c
LEFT JOIN trips USING (service_id)
LEFT JOIN routes USING (route_id)
WHERE route_id IN (SELECT route_id FROM brucher_routes)
GROUP BY service_id;

\! echo "... brucher_calendar_dates";

DROP TABLE IF EXISTS brucher_calendar_dates;
CREATE TABLE brucher_calendar_dates LIKE calendar_dates;
INSERT INTO brucher_calendar_dates
SELECT cd.*
FROM calendar_dates cd
WHERE service_id IN (SELECT service_id FROM brucher_calendar);

\! echo "... brucher_stop_times";

DROP TABLE IF EXISTS brucher_stop_times;
CREATE TABLE brucher_stop_times LIKE stop_times;
INSERT INTO brucher_stop_times
SELECT st.*
FROM stop_times st
WHERE trip_id IN (SELECT trip_id FROM brucher_trips);

\! echo "... brucher_stops";

DROP TABLE IF EXISTS brucher_stops;
CREATE TABLE brucher_stops LIKE stops;
INSERT INTO brucher_stops
SELECT s.*
FROM stops s
WHERE stop_id IN (SELECT stop_id FROM brucher_stop_times);

\! echo "... brucher_transfers";

DROP TABLE IF EXISTS brucher_transfers;
CREATE TABLE brucher_transfers LIKE transfers;
INSERT INTO brucher_transfers
SELECT t.*
FROM transfers t
WHERE to_stop_id IN (SELECT stop_id FROM brucher_stops)
AND from_stop_id IN (SELECT stop_id FROM brucher_stops);

\! echo "Optimizing tables ...";

DROP TABLE agency;
DROP TABLE calendar_dates;
DROP TABLE calendar;
DROP TABLE routes;
DROP TABLE stop_times;
DROP TABLE stops;
DROP TABLE transfers;
DROP TABLE trips;

\! echo "Caching headsigns ...";

# Note that MySQL 5.7 requires the presence of ANY-VALUE in the SELECT clause, while MySQL 5.5 requires its absence!

DROP view IF EXISTS headsigns1;
create view headsigns1 as
SELECT trip_id, ANY_VALUE(stop_id), MAX(stop_sequence) stop_sequence
#SELECT trip_id, stop_id, MAX(stop_sequence) stop_sequence
FROM brucher_stop_times
group by trip_id;
DROP view IF EXISTS headsigns2;
create view headsigns2 as
select s.name AS stop_name, st.trip_id from nice_stops s
right join brucher_stop_times st on s.stop_id = st.stop_id
inner join headsigns1 h on st.trip_id = h.trip_id
where h.stop_sequence = st.stop_sequence;

UPDATE brucher_trips t, headsigns2 h
SET t.trip_headsign = if(locate(',',h.stop_name),left(h.stop_name,locate(',',h.stop_name) - 1),if(locate(' ',h.stop_name),left(h.stop_name,locate(' ',h.stop_name) - 1),h.stop_name))
WHERE t.trip_id = h.trip_id;
DROP view headsigns1;
DROP view headsigns2;

\! echo "Caching services ...";

DROP TABLE IF EXISTS nice_services;
CREATE TABLE `nice_services` (
	`service_id` int(12) unsigned NOT NULL,
	`date` int(8) unsigned ,
	`week_day` tinyint(1) unsigned ,
	PRIMARY KEY (`service_id`, `date`),
    KEY `service_id` (`service_id`),
    KEY `date` (`date`)
) ENGINE=MyISAM;

drop procedure if exists load_foo_test_data;
delimiter $
create procedure load_foo_test_data()
begin

declare v_date date default NULL;
declare v_date_str int(8) unsigned default NULL;
declare v_end_date date default NULL;

set v_date = STR_TO_DATE((SELECT min(start_date) FROM brucher_calendar), '%Y%m%d');
set v_end_date = STR_TO_DATE((SELECT max(end_date) FROM brucher_calendar), '%Y%m%d');

while v_date <= v_end_date do
	set v_date_str = date_format(v_date, '%Y%m%d');
	
	insert into nice_services (service_id, `date`, week_day)
	SELECT service_id, v_date_str, weekday(v_date)
	FROM brucher_calendar
	WHERE start_date <= v_date_str
	AND end_date >= v_date_str
	AND (monday = 1 AND weekday(v_date) = 0
		OR tuesday = 1 AND weekday(v_date) = 1
		OR wednesday = 1 AND weekday(v_date) = 2
		OR thursday = 1 AND weekday(v_date) = 3
		OR friday = 1 AND weekday(v_date) = 4
		OR saturday = 1 AND weekday(v_date) = 5
		OR sunday = 1 AND weekday(v_date) = 6)
	AND service_id NOT IN (
		SELECT service_id
		FROM brucher_calendar_dates
		WHERE `date` = v_date_str
		AND exception_type = 2
	);
	
	insert into nice_services (service_id, `date`, week_day)
	SELECT service_id, v_date_str, weekday(v_date)
	FROM brucher_calendar_dates
	WHERE `date` = v_date_str
	AND exception_type = 1;

	set v_date=date_add(v_date,interval 1 day);
end while;

end $
delimiter ;
call load_foo_test_data();
drop procedure load_foo_test_data;

select * from nice_services order by `date` limit 8;

\! echo "Done.";
