#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Data::Dumper;

#https://www.speechpad.com/captions/srt
#Read in the SRT file:
#Each subtitle group consists of three parts:
#1. the subtitle number (a sequential number beginning with 1)
#2. two timecodes indicating when the subtitle should appear and disappear (start and end times)
#3. the text of the subtitle
#Example:
# 1
# 00:00:00,498 --> 00:00:02,827
# - Here's what I love most
# about food and diet.
#
#Timecodes have the following format:
#
#hours:minutes:seconds,milliseconds
#example
#01:07:32,053 --> 01:07:35,500


my $file = $ARGV[0]?$ARGV[0]:die "no file passed, please provide a file"; #expected file name format: filename.srt
my @filename = split('[.]',$file);
if(!($filename[1] eq "srt" || $filename[1] eq "SRT")) {
	die "file format is not srt";
}

#check for errors in time stamp format
if ( !($ARGV[1] =~ m/^'((?:-)*)(\d{2}:\d{2}:\d{2},\d{3})'$/gm) ){ 
	die "your time passed in does not match format 00:00:00,000"
}
my $signed = $1;
my @shift_time = split('[:,]', $2); #expected shift time format: 00:00:00,000

sub time_shift {
	my ($time) = @_;
	my @spl = split('[:,]', $time);
	#add the @shift_time to the time_stamp then return the results;
	my ($milliseconds, $seconds, $minutes, $hours);
	if($signed eq "-") {
		$milliseconds = $spl[3] - $shift_time[3];
		if($milliseconds < 0) {
			$milliseconds = 1000 + $milliseconds;
			$seconds -= 1;
		}
		$seconds += $spl[2] - $shift_time[2];
		if($seconds < 0) {
			$seconds = 60 + $seconds;
			$minutes -= 1;
		}
		$minutes += $spl[1] - $shift_time[1];
		if($minutes < 0) {
			$minutes = 60 + $minutes;
			$hours -= 1;
		}
		$hours += $spl[0] - $shift_time[0];
		if($hours < 0) {
			die "can't shift past 0 hours.";
		}
	} else {
		$milliseconds = $spl[3] + $shift_time[3];
		if($milliseconds >= 1000) {
			$milliseconds -= 1000;
			$seconds += 1;
		}
		$seconds += $spl[2] + $shift_time[2];
		if($seconds >= 60) {
			$seconds -= 60;
			$minutes += 1;
		}
		$minutes += $spl[1] + $shift_time[1];
		if($minutes >= 60) {
			$minutes -= 60;
			$hours += 1;
		}
		$hours += $spl[0] + $shift_time[0];
		if($hours >= 99) {
			die "can't shift past 99 hours.";
		}
	}
	return sprintf("%02d", $hours) . ":" . sprintf("%02d", $minutes) . ":" . sprintf("%02d", $seconds) . "," . sprintf("%03d", $milliseconds);
}

#Read file text into srt_file_str
open my $input, '<', $file or die "can't open $file: $!";
my $srt_file_str;
while (<$input>) {

    chomp;
    # do something with $_
	$srt_file_str .= $_ . "\n";
}
close $input or die "can't close $file: $!";

#create an array of triplets
my @content;
while($srt_file_str =~ m/(^\d+$)\s*(^\d+:\d+:\d+,\d+\s+-->\s+\d+:\d+:\d+,\d+$)\s*((?:.(?!^\d+$))*)/sgm) {
	push(@content, [$1,$2,$3]);
}

#Shift all the time stamps
for(@content){
	#process timecode shift
	#Timecodes have the following format:
	#
	#hours:minutes:seconds,milliseconds
	#example
	#01:07:32,053 --> 01:07:35,500
	@$_[1] =~ m/(^\d+:\d+:\d+,\d+)\s+-->\s+(\d+:\d+:\d+,\d+$)/sgm;
	@$_[1] = time_shift($1) . " --> " . time_shift($2);
}

my $outputFilename = $filename[0] . "-resync.srt";
open my $fh, '>', $outputFilename or die "Cannot open $outputFilename: $!";

# Loop over the array and print to output file
foreach (@content)
{
	foreach(@$_) {
		print $fh "$_\n"; # Print each entry in our array to the file
	}
}
close $fh or die "can't close $fh: $!";