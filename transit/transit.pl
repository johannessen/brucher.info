#! /usr/bin/env perl

use utf8;
use Mojolicious::Lite;
use Mojo::mysql;

helper mysql => sub {
	state $mysql = Mojo::mysql->new('mysql://root@localhost/vrs')->strict_mode(1);
};

my $q1 = <<END;
SELECT
#	start_s.name AS from_stop,
	start_s.hafas AS from_hafas,
	MAX(start_st.departure_time) AS dep,
#	end_s.name AS to_stop,
	end_s.hafas AS to_hafas,
	MIN(end_st.arrival_time) AS arr,
	r.route_short_name AS route,
	t.trip_headsign AS direction,
#	t.trip_id,
#	c.service_id,
#	(SELECT stop_id FROM brucher_stop_times WHERE trip_id = t.trip_id AND stop_id = 4227 LIMIT 1) AS add_stop1,
	((SELECT stop_id FROM brucher_stop_times WHERE trip_id = t.trip_id AND stop_id = 4227 LIMIT 1) IS NULL) AS express,
#	(SELECT stop_id FROM brucher_stop_times WHERE trip_id = t.trip_id AND stop_id = 4230 LIMIT 1) AS add_stop2,
	((SELECT stop_id FROM brucher_stop_times WHERE trip_id = t.trip_id AND stop_id = 4230 LIMIT 1) IS NOT NULL) AS vialoop
FROM brucher_trips t 
INNER JOIN brucher_routes r ON t.route_id = r.route_id
INNER JOIN brucher_stop_times start_st ON t.trip_id = start_st.trip_id
INNER JOIN nice_stops start_s ON start_st.stop_id = start_s.stop_id
INNER JOIN brucher_stop_times end_st ON t.trip_id = end_st.trip_id
INNER JOIN nice_stops end_s ON end_st.stop_id = end_s.stop_id
INNER JOIN nice_services c ON c.service_id = t.service_id
WHERE start_st.departure_time < end_st.arrival_time
	AND start_st.stop_id = ?
	AND end_st.stop_id = ?
	AND c.`date` = ?
GROUP BY t.trip_id, t.trip_headsign, start_s.hafas, end_s.hafas, r.route_short_name, c.service_id
#ORDER BY ANY_VALUE(start_st.departure_time), ANY_VALUE(end_st.arrival_time), ANY_VALUE(express) DESC, ANY_VALUE(vialoop)
ORDER BY start_st.departure_time, end_st.arrival_time, express DESC, vialoop
END

# Note that MySQL 5.7 requires the presence of ANY-VALUE in the ORDER BY clause, while MySQL 5.5 requires its absence!

my $time_shift = 3*60;  # let's assume the daily schedule rollover to happen at 0300
my $time_soon = 70;

get '/' => sub {
	my $c  = shift;
	my $db = $c->mysql->db;
	
	my @route = (4226, 4113);
	@route = reverse @route if $c->param('dir') && $c->param('dir') =~ m/^r$/i;
	my (undef, $minute, $hour, $day, $month, $year, undef, undef, undef) = localtime time - $time_shift * 60;
	my $date = sprintf "%02d", ($c->param('date') || $day);
	$date = sprintf "%02d", $day unless $date != 0;
	$date = substr(sprintf("%04d%02d%02d", $year + 1900, $month + 1, $day), 0, 8 - length $date) . $date if length $date < 8;
	my $time_now = $hour * 60 + $minute + $time_shift;
	my $time_first = 0;
	my $soon_count = 0;
	my $hash = $db->query($q1, @route, $date)->hashes;
	for my $item (@$hash) {
		$item->{dep} =~ m/^([0-9][0-9]):([0-9][0-9])/;
		my $time_dep = $1 * 60 + $2;
		$time_first ||= $time_dep if $time_dep >= $time_now;
#		$item->{status} = $time_dep < $time_now ? 'past' : $time_dep <= $time_now + $time_soon || $time_dep <= $time_first + $time_soon || $soon_count < 2 ? 'soon' : '';  # first soon condition prolly is "don't care"
		$item->{status} = $time_dep < $time_now ? 'past' : $time_dep <= $time_first + $time_soon || $soon_count < 2 ? 'soon' : '';
		$soon_count++ if $item->{status} eq 'soon';
		$item->{dep} =~ s/:00$//;
		$item->{dep} =~ s/^24:/00:/;
		$item->{dep} =~ s/^25:/01:/;
		$item->{dep} =~ s/^26:/02:/;
	}
	$c->render(
		template => 'transit',
		format => 'html',
		hash => $hash,
#		date => $date,
	);
	
};

get '/impressum' => sub {
	my $c  = shift;
	$c->render;
};

app->start;
