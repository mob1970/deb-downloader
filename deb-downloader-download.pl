#!/usr/bin/perl -w
###############################################################################
#
# deb_downloader-download (deb-downloader) 06-08-2004 
#
#	Utility for downloading packages in a computer with no Debian 
#       installed and apt-get then in our favourite flavour of Debian.
#
# Copyright (C) 2004 Miquel Oliete <debdownloader@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
#
###############################################################################

###############################################################################
#
# History : 
#
# 	06-08-2004 - deb_downloader init.
# 	07-08-2004 - http and ftp transmission implementation.
# 	11-09-2004 - deb_downloader version 0.1.7.
# 	18-09-2004 - deb_downloader version 0.1.8.
# 	19-09-2004 - deb_downloader version 0.1.9.
# 	20-09-2004 - deb_downloader version 0.1.10.
# 	21-09-2004 - deb_downloader version 0.1.11.
# 	06-10-2004 - deb_downloader version 0.1.12.
# 	07-10-2004 - deb_downloader version 0.1.13.
# 	10-10-2004 - deb_downloader version 0.1.14.
# 	19-10-2004 - deb_downloader version 0.1.15.
#
# 	27-02-2005 - deb_downloader version 0.3.1.
#
#
###############################################################################

###############################################################################
#
# Notes : 
# 
###############################################################################

use strict;

use Net::HTTP;
use HTTP::Status;
use Net::FTP;

use Cwd;
use File::Path;
use File::Copy;


###############################################################################
# Global variables.
###############################################################################

use constant NAME => "deb-downloader-download";
use constant MAIL => "debdownloader\@gmail.com";
use constant VERSION => "0.3.1";
use constant YES => "Y";
use constant NO => "N";

my %deb_downloader_options = (	
				"debugger"=>"N",
				"skip-downloaded"=>"N",				
				"file"=>"", 
				"dd-root"=>"./dd-root/",
				"help"=>"N",
				"version"=>"N");
			      
my $sources_list_content = "";
my @sources_list_lines = ();
my $execution_directory = "";

###############################################################################
# Functions.
###############################################################################

#
# Printing deb-downloader version.
#
sub print_version() {

	print("\n");
	print(NAME . " " . VERSION . " Copyright (C) 2004 Miquel Oliete <" . MAIL . ">\n");
	print("\n");
	print("This program is free software; you can redistribute it and/or modify\n");
	print("it under the terms of the GNU General Public License as published by\n");
	print("the Free Software Foundation; version 2 of the License.\n");
	print("\n");

}

#
# Printing deb-downloader usage.
#
sub print_usage() {

	print_version();
	print("\n");
	print("Usage : \n");
	print("\n");
	print("  " . NAME . " --help | --version | --file=file1...filen [--dd-root=directory] [-d|--debug] [--skip-downloaded]  \n");
	print("\n");
	
}

#
# Printing text if execution is in debug mode.
#
sub debug_print($) {
	
	if ($deb_downloader_options{'debugger'} eq YES) {
		print(shift);
	}
	
}

#
# Exiting from deb-downloader (normal and abnormal ending).
#
sub deb_downloader_exit($) {

	my $exit_code;

	$exit_code = shift;
	cwd($execution_directory);
	if ($exit_code != 0) {
		print_usage();
	}
	exit($exit_code);
}

#
# Formatting the file size in KB, MB, GB or even TB :-).
#
sub human_printing($) {

	my $bytes;
	my @unit = ('Bytes', 'KBytes', 'MBytes', 'GBytes', 'TBytes');
	my $counter;

	$bytes = shift;
	
	if (length($bytes) == 0) {
		return 0;
	}

	$counter = 0;
	while(($bytes / (1024 ** $counter)) >= 1024) {
		$counter++;
	}

	# Formatting the output with precision two.
	return sprintf("%.2f", $bytes / (1024 ** ($counter))) . " " . $unit[$counter];

}

#
# Reading the file which name is in param.
#
sub read_file($) {

	my $filename;
	my $text;

	$filename = shift;

	debug_print("filename--->$filename\n");
	if (! -e $filename) {
		return 0;
	}
	
	open(FILE,$filename) or die return 0;

	$text = "";
	while(<FILE>) {
		$text .= $_;
	}	
	
	close(FILE);
	
	return $text;	
	
}

#
# Validating necessary information needed for right script execution.
#
sub validationsOK() {

	# Checking if sources filenames are provided.
    if (length($deb_downloader_options{'file'}) == 0) {
    	print("sources file has not been provided.\n");
		return 0;
	}

	# Checking if download directory is provided.
	if (length($deb_downloader_options{'dd-root'}) == 0) {
		print("root directory has not been filled.\n");
		return 0;
	}
					 
	return 1;

}

#
# Getting the uris to download reading the sources files.
#
sub get_uris_to_download($) {

	my @sources;
	my $work;
	my $contents = "";
	my $i;

	# Splitting the names (format name1 name2 name 3 and so on) in an array.
	@sources = split(" ", shift);
	
	# Debugger code (just printing the filenames).
	if ($deb_downloader_options{'debugger'} eq YES) {
		for($i=0;$i<scalar(@sources);$i++) {
			debug_print("Source $i --> $sources[$i]\n");
		}
	}

	for($i=0;$i<scalar(@sources);$i++) {
	
		# Checking if the sources file provided exists.
		if (! -e $sources[$i]) {
			print("File $sources[$i] not found.\n");
			return 0;
		}
	
		# Joining all read uris for removing duplicates a sorting.
		$work = read_file($sources[$i]);
		$contents .= $work;
		
	}
	
	
	# Returning uris sorted and duplicates removed.
	return remove_duplicates_and_sort(split("\n", $contents));

}

#
# Removing duplicated uris joined from diferent uris files and sort the file uris alphabetically.
#
sub remove_duplicates_and_sort(@) {

	my @uris_to_process;
	my %uris = ();
	my $i;

	@uris_to_process = @_;
	
	# Removing duplicated values using a hash table (maybe it could be better, but it works Ok).
	for($i=0;$i<scalar(@uris_to_process);$i++) {
		# Checking if it's a valid uri using regular expressions.	
		if ($uris_to_process[$i] =~ /((?:ftp|http):\/\/.*)/) {
			$uris{$uris_to_process[$i]} = "";
		}
		else {
			print("Error processing line--->$uris_to_process[$i]\n");
			return 0;
		}	
		
	}

	# Sorting uris.
    @uris_to_process = sort keys(%uris);

	if ($deb_downloader_options{'debugger'} eq YES) {
		debug_print("Number of uris to process-->".scalar(@uris_to_process)."\n");
		debug_print("\n");
		debug_print("Files without duplicates.\n");
		debug_print("Init of files without duplicates ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
		for($i=0;$i<scalar(@uris_to_process);$i++) {
			debug_print("File --->$uris_to_process[$i]\n");
		}
		debug_print("End of files without duplicates ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
	}
	
	return @uris_to_process;

}

#
# Splits and return server part from an uri entered by parameter.
#
sub get_server_protocol($) {

	my $line = shift;

	debug_print("Line-->$line\n");

	if ($line =~ /^\'((?:http|ftp):\/\/[^\/]*)\/[^ ]*\/[^ \/]+\.deb\' [^ ]* [^ ]* [^ ]*/) {
		return $1;
	}
	elsif ($line =~ /^\'((?:http|ftp):\/\/[^\/]*)\/[^ ]*\/[^ \/]+\'/) {
		return $1;
	}
	else {
		print("Incorrect sources.list line.\n");
		print("Program ended abnormally.\n");
		deb_downloader_exit(1);
	}
	
}

#
# Downloading packages read in the file filled in --file option.
# This function implements a programming structure called "control breaking". 
# The uris are ordered alphabetically by server, so we break the flow for every
# diferent server and call the download function once per server.
#
sub download_packages() {
	
	my $i;
	my $j;
	my $pwd;
	my $old_line;
	my @file_lines;

	$|=1;

	# Creating the download directory if it doesn't exist.
	if (! -e $deb_downloader_options{'dd-root'}) {
		print("Creating deb-download root directory " . $deb_downloader_options{'dd-root'}  . "...");
		mkpath($deb_downloader_options{'dd-root'}) or die return 0;
		print("done\n");
	}

	# Going into the download directory.
	print("Changing to deb-downloader root directory called " . $deb_downloader_options{'dd-root'} . "...");
	chdir($deb_downloader_options{'dd-root'});
	print("done\n");				
			
	$i = 0; # Counter used for processing all uris recollected.
	# While we have uris to process ...
	while($i<scalar(@sources_list_lines)) {
		debug_print("source_line---------> $sources_list_lines[$i] \n");
		$old_line = $sources_list_lines[$i];
		@file_lines = ();
		$j = 0; # Counter used for getting all the server uris.
		debug_print("old value ----> $old_line \n");
		# While we have uris to process and the uri's server part doesn't change ...
		while($i<scalar(@sources_list_lines) && 
			get_server_protocol($sources_list_lines[$i]) eq get_server_protocol($old_line)) {
			debug_print("source_line--->$sources_list_lines[$i]\n");
			$sources_list_lines[$i] =~ /^\'(?:ftp|http):\/\/(.*)/;
			$file_lines[$j] = $1;
			$j++;
			$i++;
		}

		# If the uri contains http uris, download files using http protocol.
		if ($old_line =~ /^\'http:\/\/([^\/]*)(\/[^ ]*\/)([^ \/]+)\'/) {
			if (!http_download($1, @file_lines)) {
				return 0;
			}
		}
		# If the uri contains ftp uris, download files using ftp protocol.		
		elsif ($old_line =~ /^\'ftp:\/\/([^\/]*)(\/[^ ]*\/)([^ \/]+)\'/) {
			if (!ftp_download($1, @file_lines)) {
				return 0;
			}			
		}		
		# else error (only http and ftp protocol suported).
		else {
			return 0;
		}
	}
	
	
	return 1;
}

#
# Files downloading using http protocol and Net::Http module. Each execution 
# of this function uses only one server (list is sorted by server).
#
sub http_download(@) {
	
	my $pwd;
	my $i;
	my $http_connection;
	my $code;
	my $mess;
	my %h;
	my $host_name;
	my @lines;
	my $target_directory;
	my $internal_buffer;
	my $deb_file;
	my $number_of_bits;
	
	$host_name = shift;
	@lines = @_;	
	
	debug_print("http\$host_name-->$host_name\n");	
	debug_print("http\$host_file-->".join("\n", @lines)."\n");	
	
	print("\nProtocol used with server $host_name : http.\n\n");
	
	$pwd = getcwd();
	
	for($i=0;$i<scalar(@lines);$i++) {
	
		$http_connection = Net::HTTP->new(Host => $host_name) || print("Error openning $host_name http_connection\n") && return 0;
		debug_print("----->$lines[$i]\n");
		if ($lines[$i] =~ /([^\/]*)(\/[^ ]*\/)([^ \/]+\.deb)\' ([^ ]*) ([^ ]*) ([^ ]*)/) {
			$deb_file = 1;
		}
		elsif($lines[$i] =~ /([^\/]*)(\/[^ ]*\/)([^ \/]+)\'/) {
			$deb_file = 0;
		}
		
		$target_directory = substr($2, 1, length($2)-1);
		
		# If file exists and skip-downloaded is enabled goes to else option (skip the downloading).
		if ($deb_downloader_options{'skip-downloaded'} eq NO || !-e $pwd.$2.$3) {
			if (! -d $pwd.$2) {
				print("Creating new directory $target_directory...");
				mkpath($target_directory) or die return 0;
				print("done\n");
			}
			
			print("Changing to $target_directory directory ...");
			chdir($target_directory);
			print("done\n");				
			
			print("Downloading file $2$3 " . (($deb_file) ? "(" . human_printing($5) . ")" : "") . "...");
			
			$http_connection->write_request(GET => $2.$3, 'User-Agent' => "Mozilla/5.0");
			($code, $mess, %h) = $http_connection->read_response_headers;
			
			if ($code == RC_NOT_FOUND) {
		   		print("not done\n");
		   		print("File $3 doesn't exists in http server $host_name \n");
		   		print("Execute this script with build option again in your Debian.\n");
		   		return 0;
			}
			elsif ($code != RC_OK) {
		   		print("Error in http get request with file $3 in server $host_name.\n");
		   		return 0;				
			}
			
			open(DEBFILE,">$3") or die "Error opening output file $3.\n";
			binmode(DEBFILE);
			
			while (($number_of_bits = $http_connection->read_entity_body($internal_buffer, 1024)) > 0) {
				print DEBFILE $internal_buffer;
			}

			close(DEBFILE);	
			
			if ($number_of_bits < 0) {
		   		print("Error in http data transference with file $3.\n");
		   		unlink $3;
		   		return 0;				
			}
			
			print("done\n\n");
	
			chdir($pwd);
		}	
		else {
			print("File " . $pwd . $2 . $3 . " already downloaded\n");
		}
					
	}
	
	return 1;

}

#
# Files downloading using ftp protocol and Net::Ftp module. Each execution 
# of this function uses only one server (list is sorted by server).
#
sub ftp_download(@) {
	
	my $pwd;
	my $i;
	my $ftp_connection;
	my $host_name;
	my @lines;
	my $target_directory;
	my @files;
	my $deb_file;
			
	$host_name = shift;
	@lines = @_;	
	
	debug_print("ftp\$host_name-->$host_name\n");	
	debug_print("ftp\$host_file-->".join("\n", @lines)."\n");	

	print("\nProtocol used with server $host_name : ftp.\n\n");

	$pwd = getcwd();

	# Openinig the ftp connection with host.
	$ftp_connection = Net::FTP->new($host_name, Debug => 0) || print("\nError openning $host_name ftp connection.") && return 0;
		
	# Login as anonymous in the host.
	$ftp_connection->login("anonymous",'-anonymous@') || print("\nError logging to $host_name ftp_connection.") && return 0;
	
	# Setting the transmission in binary mode.	
	$ftp_connection->binary() || print("\nError setting tranference mode to binary.") && return 0;

	
	for($i=0;$i<scalar(@lines);$i++) {
		debug_print("----->$lines[$i]\n");
		if ($lines[$i] =~ /([^\/]*)(\/[^ ]*\/)([^ \/]+\.deb)\' ([^ ]*) ([^ ]*) ([^ ]*)/) {
			$deb_file = 1;
		}
		elsif($lines[$i] =~ /([^\/]*)(\/[^ ]*\/)([^ \/]+)\'/) {
			$deb_file = 0;
		}
		
		# If file exists and skip-downloaded is enabled goes to else option (skip the downloading).
		if ($deb_downloader_options{'skip-downloaded'} eq NO || !-e $pwd.$2.$3) {
		
			$target_directory = substr($2, 1, length($2)-1);
			if (! -d $pwd.$2) {
				print("Creating new directory $target_directory...");
				mkpath($target_directory) or die return 0;
				print("done\n");
			}
			
			print("Changing to $target_directory directory ...");
			chdir($target_directory);
			print("done\n");
			
			print("Downloading file $2$3 " . (($deb_file) ? "(" . human_printing($5) . ")" : "") . "...");
			
			# Checking if the file is available in the server.
		   	@files = $ftp_connection->ls($2.$3);
		   	if (scalar(@files) == 0) {
		   		print("not done\n");
		   		print("File $3 doesn't exists in ftp server $host_name \n");
		   		print("Execute this script with build option again in your Debian.\n");
		   		return 0;
		   	}
		   	
			if (!defined $ftp_connection->get($2.$3)) {
		   		unlink $3;			
				print("\nError in ftp data transference with file $3.");							
				return 0;
		   	}
		   	
			print("done\n\n"); 
			
			chdir($pwd);					
			
		}
		else {
			print("File " . $pwd . $2 . $3 . " already downloaded\n");
		}
		
	}
	
	$ftp_connection->quit;
    	
    return 1;
    
}

#
# Parameters validation.
#
sub validate_and_get_parameters(@) {
	
	my $files_with_uris = "";
	my $i;
	
	if (scalar(@_) == 0) {
		return 0;
	}
	
	$i=0;
	while($i<scalar(@_)) {
		debug_print("--->  $_[$i]" . "  ------"  ."\n");
		if ($_[$i] =~ /^(?:-d|--debug)$/) {
			$deb_downloader_options{'debugger'} = YES;
		}
		elsif ($_[$i] =~ /--file=(.*)/) {
			if (length($1) != 0) {
				$files_with_uris .= " " . $1;
			}
			while ($i+1<scalar(@ARGV) && !($ARGV[$i+1] =~ /^(-d|--debug|--dd-root=.*|--skip-downloaded|--help|--version)$/)) {
				$i++;
				$files_with_uris .= " " . $ARGV[$i];
			}

			debug_print("\$files_with_uris --> $files_with_uris\n");
				
			if (length($files_with_uris) != 0) {
				$deb_downloader_options{'file'} = $files_with_uris;	
			}
			else {
				print("files with uris not informed.\n");
				return 0;
			}
		}
		elsif ($_[$i] =~ /--dd-root=((?:[^ ]*\+?)+)/) {
			$deb_downloader_options{'dd-root'} = $1;
			if ($deb_downloader_options{'dd-root'} =~ /.*[^\/]/) {
				$deb_downloader_options{'dd-root'} .= '/';
			}
							
		}
		elsif ($_[$i] eq "--skip-downloaded") {
			$deb_downloader_options{'skip-downloaded'} = YES;
		}		
		elsif ($_[$i] eq "--help") {
			$deb_downloader_options{'help'} = YES;
		}
		elsif ($_[$i] eq "--version") {
			$deb_downloader_options{'version'} = YES;
		}
		else {
			return 0;
		}
		$i++;
	}
	
	return 1;	
	
}

###############################################################################
# Main body
###############################################################################

$execution_directory = getcwd();

if (!validate_and_get_parameters(@ARGV)) {
	print("Error in parameters.\n");
	deb_downloader_exit(1);	
}

# Action to do.

if ($deb_downloader_options{'help'} eq YES) {
	print_usage();
}
elsif ($deb_downloader_options{'version'} eq YES) {
	print_version();
}
else {
	# Validating if the entered parameters are enough and are OK.
    if (!validationsOK()) {
		deb_downloader_exit(1);		
	}	
	
	# Getting source files contents, parsing sources.list getting only the ftp 
	# and http uris for downloading, sorted and duplicates removed.
	@sources_list_lines = get_uris_to_download($deb_downloader_options{'file'});
	
	# Downloading packages in dd-root directory.
	if (!download_packages()) {
		print("\nPackages downloaded NOK :-(\n\n");
		deb_downloader_exit(1);		
	}		
	
	print("\nPackages downloaded OK :-)\n\n");
}

deb_downloader_exit(0);
