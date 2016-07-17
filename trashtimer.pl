#!/usr/bin/perl

# License:		GPLv3 - see license file or http://www.gnu.org/licenses/gpl.html
# Program-version:	1.0, (17th July 2016)
# Description:		Clear out files in trash after defined time
# Contact:		Dominik Bernhardt - domasprogrammer@gmail.com or https://github.com/DomAsProgrammer

use strict;
use warnings;
#use diagnostics; # whyle programming/debugging
use Cwd 'realpath';
use Getopt::Long qw(:config no_ignore_case bundling);
use File::Path qw(remove_tree);
use Env;
use File::Basename;

### Program ###

my @time	= ();
my $Trashdir	= "$ENV{HOME}/.local/share/Trash";
my $help	= '';
my $year	= '';
my $month	= '';
my $week	= '';
my $day		= '';
my @list	= ();

GetOptions (
		't|time=s'		=> \@time,
		'd|directory=s'		=> \$Trashdir,
		'h|help'		=> \$help )
			|| usage(1);

# Help
if ( $help ) { usage(0); }

# Check if folder Trash and subfolders exists
if ( ! -d $Trashdir || ! -d "$Trashdir/info" || ! -d "$Trashdir/files" ) {
	print STDERR "\"$Trashdir\" didn't look like the Trash/ folder!\n";
	if ( -d $Trashdir ) {
		if ( ! -d "$Trashdir/info" )  { print STDERR "\t(there is no directory named info/)\n"; }
		if ( ! -d "$Trashdir/files" ) { print STDERR "\t(there is no directory named files/)\n"; }
		}
	usage(2);
	}

# Set up the time string or default
my $time = join('', @time);
if ( ! ($time) ) { 
	$time = "1m";
	}

# Test time string and split up time specifications
if ( $time !~ m/([0-9]{1,2}y)|([0-9]{1,2}m)|([1-3]w)|([1-6]d)/i ) {
	print STDERR "Time information \"$time\" is invalid!\n";
	}
else {
	$year = ($time =~ m/([0-9]{1,2}y)/i)[0];
	if ( $year ) { $year =~ s/y//i; }
	else { $year = 0; }

	$month = ($time =~ m/([0-9]{1,2}m)/i)[0];
	if ( $month ) { $month =~ s/m//i; }
	else { $month = 0; }

	$week = ($time =~ m/([1-3]w)/i)[0];
	if ( $week ) { $week =~ s/w//i; }
	else { $week = 0; }

	$day = ($time =~ m/([1-6]d)/i)[0];
	if ( $day ) { $day =~ s/d//i; }
	else { $day = 0; }
	}

# Calculate time
my $countdown = ($year * 365 + $month * 30 + $week * 7 + $day) * 24 * 60 ** 2;	# time difference in format of time module
if ( $countdown <= 0 ) {
	print STDERR "You have set time to zero. If you want this use your GUI's function to clear trash!\n";
	usage(3);
	}

# Collect informations about time
foreach my $file ( glob("\"$Trashdir\"/info/*\.trashinfo") ) {
	push(@list, {	'deltime'	=> getdeltime($file),			# time from deletion in form of time module
			'infofile'	=> "$file",				# file in pos
			'originalfile'	=> getoriginal($file, $Trashdir)	# real deleted file
			}
		);
	}
	
my $now = time;			# calculation time
foreach my $element ( @list ) {
		# Is the file older as the maximal time?
		if ( ($now - ${$element}{'deltime'}) > $countdown ) {
		my $logdate = localtime(time);	# human readable time for log
			# Delete original if it is a folder and log
			if ( -d ${$element}{'originalfile'} ) {
				print "$logdate : Deleted original folder: ${$element}{'originalfile'}\n";
				remove_tree(${$element}{'originalfile'}) || die "Can't delete folder \"${$element}{'originalfile'}\"!\n"; 
				}
			# Delete original if it is a file and log
			elsif ( -e ${$element}{'originalfile'} || -l ${$element}{'originalfile'} ) {
				print "$logdate : Deleted original file: ${$element}{'originalfile'}\n";
				unlink(${$element}{'originalfile'}) || die "Can't delete file \"${$element}{'originalfile'}\"!\n"; 
				}
			# Delete infofile and log
			if ( -e ${$element}{'infofile'} ) {
				print "$logdate : Deleted info file: ${$element}{'infofile'}\n";
				unlink(${$element}{'infofile'}) || die "Can't delete file \"${$element}{'infofile'}\"!\n"; 
				}
			}
	}

exit(0);

### Subfunktions ###
sub usage {
	my $level	= shift;
	my $out		= '';
	if ( $level > 0 ) { $out = *STDERR; }
	else { $out = *STDOUT; }
	print $out "\nUsage: $0 [--time 10y11m3w6d] [--dir $ENV{HOME}/.local/share/Trash] [--help]\n\n",
		"\t--time, -t\n",
		"\t\tmust be integer with following y, m, w, or d. (combinable) Default is 30 days\n",
		"\t\t1y = 365d, 1m = 30d, 1w = 7d\n\n",
		"\t--directory, -d\n",
		"\t\tmust be the folder where Trash's info/ and files/ folders are stored. Default is ~/.local/share/Trash\n\n",
		"\t--help, -h\n",
		"\t\tshow this help\n\n";
	exit($level);
	}

sub getdeltime {
	my $infofile = shift;
	return((stat($infofile))[9]);
	}

sub getoriginal {
	my $infofile	= shift;
	my $dir		= shift;
	my $original	= '';
	$infofile 	= (fileparse($infofile, qr/\.[^.]*/))[0];
	$original	= "$dir/files/$infofile";
	if ( -e $original || -l $original ) { return($original); }
	else {
		print STDERR "No file or folder \"$original\" found!\n";
		exit(5);
		}
	}

#EOF
exit(0)
