#!/usr/bin/perl -w
###############################################################################
#
# deb_downloader-build (deb-downloader) 06-08-2004 
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

use strict;

use Cwd;
use File::Path;
use File::Copy;


###############################################################################
# Global variables.
###############################################################################

use constant NAME => "deb-downloader-build";
use constant MAIL => "debdownloader\@gmail.com";
use constant VERSION => "0.3.1";
use constant YES => "Y";
use constant NO => "N";

use constant URI_FILE => "deb_downloader_uris.txt";

my %deb_downloader_options = (	
				"debugger"=>"N",
				"file"=>"sources.list", 
				"skip-update"=>"N",
				"install"=>"N", 
				"dist-upgrade"=>"N", 
				"help"=>"N",
				"version"=>"N");
			      
my $sources_list_content = "";
my @sources_list_content_lines = ();
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
	print("  " . NAME . " --help | --version | (--file=filename dist-upgrade|install package1...packagen [--skip-update] [-d|--debug]) \n");
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
# Writting a file which name is in the first param and content in the second one.
#
sub write_file(@) {

	my $filename;
	my $text;

	if (scalar(@_) != 2) {
		return 0;
	}
	
	$filename = shift;
	$text = shift;

	open(FILE,">".$filename) or die return 0;
	print FILE $text;
	close(FILE);

	return 1;

}

#
# Testing if our distro is a Debian and if apt-get is installed.
#
sub is_debian_and_is_ready() {
	
	# Testing if we are executing the script in a Debian distro.
	if (! -e '/etc/debian_version') {
		print("You are not executing this script's option in a Debian.\n");
		return 0;		
	}

	# Testing if apt-get is installed.
	if (! -e '/usr/bin/apt-get') {
		print("apt-get is not installed in your system. Install it and repeat process execution\n");
		return 0;
	}	
	
	return 1;
}

#
# Validating necessary information needed for right script execution.
#
sub validationsOK() {

	my $user;

	# We have to enable one of this actions.
	if ($deb_downloader_options{'install'} eq NO && $deb_downloader_options{'dist-upgrade'} eq NO) {
    	print("install and dist-upgrade options both not activated.\n");
		return 0;
	}

	# Both actions can not be enabled.
	if ($deb_downloader_options{'install'} eq YES && $deb_downloader_options{'dist-upgrade'} ne NO) {
    	print("install and dist-upgrade options both activated.\n");
		return 0;
	}
	
	# Uris file name MUST be provided.
    if (length($deb_downloader_options{'file'}) == 0) {
    	print("sources file has not been provided.\n");
		return 0;
	}

	# We have to execute this script in a Debian or Debian-based distro.
	if (!is_debian_and_is_ready()) {
		return 0;
	}

	# We MUST be root user to execute apt-get update for renewing the control files.
	if ($deb_downloader_options{'skip-update'} eq NO) {
		$user = `whoami`;
	   	debug_print("------>" . $user . "\n");
		chomp($user);
		if ($user ne 'root') {
			print("This script option has to be executed as a root user.\n");
	        return 0;
	    }
	}
																													

	return 1;

}

#
# Read files which contains packages definitions and write them in the
# uris file joining access protocol and file path (I'm not sure if it's 
# enough with apt-get update --print-uris).
#
sub get_resume_files() {

	my $lines;
	my @sources_list_lines;
	my @files;
	my $i;
	my %servers;

	# Read /etc/apt/sources.list and get the servers with its access protocol.
	@sources_list_lines = split("\n", read_file("/etc/apt/sources.list"));
	debug_print("scalar---->".scalar(@sources_list_lines)."\n");
	for($i=0;$i<scalar(@sources_list_lines);$i++) {
		if ($sources_list_lines[$i] =~ /^(?:deb|deb-src) +(ftp|http):\/\/([^\/]+).*/) {
			debug_print("\$1----------------->$1\n");
			debug_print("\$2----------------->$2\n");
			$servers{"$2"} = $1;
		}
	}

	# Read /var/lib/apt/lists files.
	opendir(DIRECTORY,"/var/lib/apt/lists/") or die return 0;
	@files = readdir(DIRECTORY);
	closedir(DIRECTORY);
	debug_print("scalar---->".scalar(@files)."\n");


	# Build lines adding access protocol.
	$lines = "";
	for($i=0;$i<scalar(@files);$i++) {
		debug_print("$files[$i]\n");
		if ($files[$i] =~ /((((?:ftp|http)[^\_]+)\_[^\_]+)+)/) {
			debug_print("\$1----------------->$1\n");
			debug_print("\$2----------------->$2\n");
			debug_print("\$3----------------->$3\n");
			$lines .= "'" . $servers{"$3"} . "://";
			$files[$i] =~ s/\_/\//g;
			$lines .= $files[$i] . "'\n";
		}
	}
	
	# return list.
	debug_print("lines-->$lines\n");
	return $lines;

}

#
# Build uris list for downloading packages with deb-downloader-download.
#
sub build_list() {

	my $uris;
	my @uris_list;
	my $i;
	my $question;
	my $RC;


   # Checking if all information is available.
	if (!validationsOK()) {
		return 0;
	}
									  

	# Executing update for renewing control files if skip update option is not enabled.									  
	if ($deb_downloader_options{'skip-update'} eq NO) {
		if (system("/usr/bin/apt-get update") ne "0") {
			print("Error executing apt-get update. Check it manually.\n");
			return 0;
		}
	}

	# Getting the resume (control) files needed.
	$uris = get_resume_files();

	# Executing the apt-get option (update something or dist-upgrade) with --print-uris option
	# enabled for getting the needed uris.
	if ($deb_downloader_options{'dist-upgrade'} eq YES) {
	    debug_print("doing dist-upgrade.\n");
		$RC = system("/usr/bin/apt-get dist-upgrade --assume-yes --print-uris  > " . URI_FILE);
	}
	else {
	    debug_print("doing install.\n");
		debug_print("packages to download --> " . $deb_downloader_options{'install'} . "\n");
		$RC = system("/usr/bin/apt-get install $deb_downloader_options{'install'} --assume-yes --print-uris  > " . URI_FILE);
	}
	
	if ($RC ne "0") {
			unlink URI_FILE;
			print("Error getting packages list. Check it manually.\n");
			return 0;
	}

	#Parsing and getting the uris.
	@uris_list = split(/\n+/, read_file(URI_FILE));
	unlink URI_FILE;
	debug_print("scalar uris ---> " . scalar(@uris_list) . "\n");
	for($i=0;$i<scalar(@uris_list);$i++) {
	    debug_print("+----------> $uris_list[$i]\n");
		if ($uris_list[$i] =~ /^\'(?:http|ftp):\/\/[^\/]*\/[^ ]*\/[^ \/]+\.deb\' [^ ]* [^ ]* [^ ]*/) {
			$uris .= $uris_list[$i] . "\n";
		}
	}

	# Saving the uris in the ouput file.
	if (-e $deb_downloader_options{'file'}) {
		print("File named $deb_downloader_options{'file'} already exists. Do you want to overwrite it (y/N) ?");
		$question = <STDIN>;
		chomp($question);
		debug_print("\$question---->$question\n");
		if (uc($question) ne YES) {
			print("Proces stopped by user.\n");
			return 1;
		}
		
	}
	
	write_file($deb_downloader_options{'file'}, $uris);
	
	
	return 1;
	
}

#
# Parameters validation.
#
sub validate_and_get_parameters(@) {
	
	my $i;
	my $packages_to_install = "";
	
	if (scalar(@_) == 0) {
		return 0;
	}

	$i=0;
	while($i<scalar(@_)) {
		debug_print("--->  $_[$i]" . "  ------"  ."\n");
		if ($_[$i] =~ /^(?:-d|--debug)$/) {
			$deb_downloader_options{'debugger'} = YES;
		}
		elsif ($_[$i] =~ /--file=((?:[^ ]*\+?)+)/) {
			debug_print("Files-->$1\n");
			$deb_downloader_options{'file'} = $1;	
		}
		elsif ($_[$i] eq "--skip-update") {
			$deb_downloader_options{'skip-update'} = YES;
		}
		elsif ($_[$i] eq "--help") {
			$deb_downloader_options{'help'} = YES;
		}
		elsif ($_[$i] eq "dist-upgrade") {
			$deb_downloader_options{'dist-upgrade'} = YES;
		}
		elsif ($_[$i] eq "install") {
			while ($i+1<scalar(@ARGV) && !($ARGV[$i+1] =~ /^(-d|--debug|--file=.*|--skip-update|--help|dist-upgrade|--version)$/)) {
				$i++;
				$packages_to_install .= " " . $ARGV[$i];
			}

			if (length($packages_to_install) != 0) {
				$deb_downloader_options{'install'} = $packages_to_install;
			}
			else {
				print("install option without packages.\n");
				return 0;
			}
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

# Options required processing.

if ($deb_downloader_options{'help'} eq YES) {
	print_usage();
}
elsif ($deb_downloader_options{'version'} eq YES) {
	print_version();
}
else {
	if (!build_list()) {
		print("\nPackages list built NOK :-(\n\n");
		deb_downloader_exit(1);
	}
	print("\nPackages list built OK :-)\n\n");
}

deb_downloader_exit(0);
