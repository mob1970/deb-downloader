#!/usr/bin/perl -w
###############################################################################
#
# deb_downloader-install (deb-downloader) 06-08-2004 
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

use constant NAME => "deb-downloader-install";
use constant MAIL => "debdownloader\@gmail.com";
use constant VERSION => "0.3.1";
use constant YES => "Y";
use constant NO=> "N";
use constant DEFAULT_OUTPUT_DIRECTORY => '/var/cache/apt/archives/';
use constant URI_FILE => "deb_downloader_uris.txt";

my %deb_downloader_options = (	
				"debugger"=>"N",
				"file"=>"", 		
				"skip-action"=>"N", 						
				"dist-upgrade"=>"N", 
				"copy-files"=>"N", 
				"install"=>"N", 
				"mirror-format"=>"N", 
				"dd-root"=>"./dd-root/",
				"output-directory"=> DEFAULT_OUTPUT_DIRECTORY,
				"help"=>"N",
				"version"=>"N");
			      
my $execution_directory = "";
my $rcOK = 0;

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
	print("  " . NAME . " --help | --version | (copy-files|dist-upgrade|install package1 packagen) [--file=filename] [--dd-root=directory] [--mirror-format]  [-d|--debug] [--skip-action]  \n");
	print("\n");
	
}

#
# Printing text if execution is in debug mode (-d or --debug option, useful for resolving bugs).
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
# Method for reading the file which name is in param.
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
# Obtaining the needed uris from the content of a string (from file or apt-get output).
#
sub obtain_uris($) {
	
	my $output_uris;
	my @uris_list;
	my @needed_uris;
	my $i;

	$output_uris = shift;
	debug_print("output uris ---> " . $output_uris . "\n");
	
	@uris_list = split(/\n+/, $output_uris);
	debug_print("scalar uris ---> " . scalar(@uris_list) . "\n");
    
	for($i=0;$i<scalar(@uris_list);$i++) {
		debug_print("+----------> $uris_list[$i]\n");
		if ($uris_list[$i] =~ /^'(?:http|ftp):\/\/[^\/]*\/[^ ]*\/[^ \/]+\.deb' [^ ]* [^ ]* [^ ]*/) {
	    	debug_print("choosen uri ----------> $uris_list[$i]\n");
			$needed_uris[scalar(@needed_uris)] = $uris_list[$i];
		}
	}	

	debug_print("Number of choosen uris --> " . scalar(@needed_uris) . "\n");

	return @needed_uris;
	
}

#
# Checking if all .deb files needed are included in directory structure.
#
sub are_all_needed_files_downloaded(@) {

	my @uris_list;
	my $root_directory;
	my $i;

	$root_directory = shift;
	debug_print("\$root_directory after ----> $root_directory\n");

	@uris_list = shift;
	for($i=0;$i<scalar(@uris_list);$i++) {
		if ($uris_list[$i] =~ /^'(?:http|ftp):\/\/[^\/]*\/([^ ]*\/[^ \/]+.*)' ([^ ]*) [^ ]* [^ ]*/) {
			debug_print("file---->$root_directory$1.\n");
			if (! -e "$root_directory$1") {
			   print("Missing file $1.\n");
				return 0;
			}
		}
		elsif ($uris_list[$i] =~ /^'(?:http|ftp):\/\/[^\/]*\/([^ ]*\/[^ \/]+.*)'/) {
			debug_print("file---->$root_directory$1.\n");
			if (! -e "$root_directory$1") {
				print("Missing file $1.\n");
				return 0;
			}
		}
	}
	
	return 1;

}

#
# Copying the .deb files from source directory to target directory.
#
sub copy_files {

	my $source_directory;
	my $target_directory;
	my @files;
	my $i;
	my $pathname;
	my $filename;
	my $control_line;

	$source_directory = shift;
	$target_directory = shift;
	@files = @_;
	debug_print("source_directory--->$source_directory\n");
	debug_print("target_directory--->$target_directory\n");

	for($i=0;$i<scalar(@files);$i++) {
		if ($files[$i] =~ /^\'(?:http|ftp):\/\/[^\/]*\/([^ ]*\/)([^ \/]+.*)' ([^ ]*) [^ ]* [^ ]*/) {
			$pathname = $1;
			$filename = $2;
			$control_line = 0;
		}
		elsif ($files[$i] =~ /^\'(?:http|ftp):\/\/[^\/]*\/([^ ]*\/[^ \/]+.*)'/) {
			$pathname = $1;
			$filename = $2;
			$control_line = 1;
		}
		else {
			print("Error processing line $files[$i].\n");
			return 0;
		}
		
		debug_print("source --->$deb_downloader_options{'dd-root'}$pathname$filename\n");
		debug_print("target --->$target_directory$filename\n");
        
		if ($deb_downloader_options{'mirror-format'} eq YES) {
        	# Creating the needed directory if it doesn't exist.
			if (! -e "$target_directory$pathname") {
		    	print("Creating new directory $target_directory$pathname...");
				mkpath($target_directory.$pathname) or die return 0;
		 	    print("done\n");
			}
            # Copying the file in the directory created before.
	       	print("Copying file $target_directory$pathname$filename...");
			copy("$deb_downloader_options{'dd-root'}$pathname$filename", "$target_directory$pathname$filename");
			print("done\n");
		}
		else {
        	# Copying the file (we don't copy the control file because mirror-format option is not activated).
			if (!$control_line) {
		       	print("Copying file $target_directory$filename...");
				copy("$deb_downloader_options{'dd-root'}$pathname$filename", "$target_directory$filename");
				print("done\n");
			}
		}
	}

	
	return 1;
}

#
# Validations done before dist-upgrade the distro, install packages or just copy file.
#
sub common_validations() {

	my $user;

	# Testing if dd-root directory has been filled.
	if (length($deb_downloader_options{'dd-root'}) == 0) {
   	   print("root directory has not been filled.\n");
	   return 0;
	}
	
	# Testing if dd-root directory exists.	
	if (! -d $deb_downloader_options{'dd-root'}) {
   	   print("Wrong deb_downloader root directory or it doesn't exist.\n");
	   return 0;
	}
	
	# Testing if output directory directory exists.		
	if (! -d $deb_downloader_options{'output-directory'}) {
   	   print("Output directory doesn't exist.\n");
	   return 0;
	}

	# Testing if output directory directory is writable.		
	if (! -w $deb_downloader_options{'output-directory'}) {
   	   print("Output directory is not writable.\n");
	   return 0;
	}	

	# If there's no action to skip.
	#if ($deb_downloader_options{'install'} eq NO && $deb_downloader_options{'dist-upgrade'} eq NO &&
	#    $deb_downloader_options{'skip-action'} eq YES) {
	#	print("There's no action (dist-upgrade or install) to skip.\n");
	#	return 0;	    
	#}
	
	# mirror-format option not available if target directory is /var/cache/apt/archives.
	if ($deb_downloader_options{'output-directory'} eq DEFAULT_OUTPUT_DIRECTORY &&
	    $deb_downloader_options{'mirror-format'} eq YES) {
		print("mirror-format option not allowed in " . DEFAULT_OUTPUT_DIRECTORY  . " (default directory).\n");
		return 0;
	}
	
	# If output directory is DEFAULT_DIRECTORY or dist-upgrade or install option enabled, user must be root.
	if ($deb_downloader_options{'dist-upgrade'} eq YES || $deb_downloader_options{'install'} ne NO || 
	    $deb_downloader_options{'output-directory'} eq DEFAULT_OUTPUT_DIRECTORY) {
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
# Installing .deb files in our computer.
#
sub install_packages {

	my $files_copied_ok;
	my $RC;
	my @uris_to_copy;


    # Checking available data.
	if (!common_validations()) {
		return 0;
	}

	if (!is_debian_and_is_ready()) {
		return 0;
	}

	# Getting all the needed uris using apt-get install whatever.                
	$RC = system("/usr/bin/apt-get install $deb_downloader_options{'install'} --assume-yes --print-uris  > " . URI_FILE);
	if ($RC ne "0") {
			unlink URI_FILE;
			print("Error getting packages list. Check it manually.\n");
			return 0;
	}

	# Obtaining all the needed uris and removing the temporal file.
	debug_print("Uris --> " . read_file(URI_FILE)  . "\n");
	@uris_to_copy = obtain_uris(read_file(URI_FILE));
	unlink URI_FILE;		

	# If there are uris to process.
	if (scalar(@uris_to_copy) != 0) {
		# Checking if all needed files are available.
		if (! are_all_needed_files_downloaded($deb_downloader_options{'dd-root'}, @uris_to_copy)) {
		   print("There is/are needed file(s) which is/are not downloaded. Please run build and download options.\n");
		   return 0;
		}
		
		# Copy all .deb files into output-directory.
		$files_copied_ok = copy_files($deb_downloader_options{'dd-root'}, 
								      $deb_downloader_options{'output-directory'}, 
								      @uris_to_copy);
		if (!$files_copied_ok) {
		   print("Files can not be copied ok.\n");
		   return 0;
		}
	}

	# If skip-action flag is not enabled, execute apt-get install whatever.
	if ($deb_downloader_options{'skip-action'} eq NO) {	
		debug_print("doing install.\n");
		debug_print("packages to install --> " . $deb_downloader_options{'install'} . "\n");
		$RC = system("/usr/bin/apt-get install $deb_downloader_options{'install'} --assume-yes");
		
		if ($RC ne "0") {
			print("Error installing packages list. Check it manually.\n");
			return 0;
		}
	}

	return 1;

}


#
# Updating our Debian distro version.
#
sub dist_upgrade_distro() {
	
	my $files_copied_ok;
	my $RC;
	my @uris_to_copy;


    # Checking available data.
	if (!common_validations()) {
		return 0;
	}

	if (!is_debian_and_is_ready()) {
		return 0;
	}
	
	# Getting all the needed uris using apt-get dist-upgrade.
	$RC = system("/usr/bin/apt-get dist-upgrade --assume-yes --print-uris  > " . URI_FILE);
	if ($RC ne "0") {
			unlink URI_FILE;
			print("Error getting packages list. Check it manually.\n");
			return 0;
	}

	# Obtaining all the needed uris and removing the uris temporal file.
	@uris_to_copy = obtain_uris(read_file(URI_FILE));
	unlink URI_FILE;		

	# If there are uris to process.	
	if (scalar(@uris_to_copy) != 0) {
		# Checking if all needed files are available.
		if (! are_all_needed_files_downloaded($deb_downloader_options{'dd-root'}, @uris_to_copy)) {
		   print("There is/are needed file(s) which is/are not downloaded. Please run build and download options.\n");
		   return 0;
		}
		
		# Copy all .deb files into output-directory.
		$files_copied_ok = copy_files($deb_downloader_options{'dd-root'}, 
									  $deb_downloader_options{'output-directory'},
									  @uris_to_copy);
									  
		if (!$files_copied_ok) {
		   print("Files can not be copied ok.\n");
		   return 0;
		}
	}

	# If skip-action flag is not enabled, execute apt-get dist-upgrade.	
	if ($deb_downloader_options{'skip-action'} eq NO) {	
		debug_print("doing dist-upgrade.\n");
		$RC = system("/usr/bin/apt-get dist-upgrade --assume-yes");
		
		if ($RC ne "0") {
			print("Error upgrading distro. Check it manually.\n");
			return 0;
		}
	}

	return 1;	
	
}

#
# Copy files into our preferred directory.
#
sub just_copy_files() {
	
	my $files_copied_ok;
	my @uris_to_copy;	


    # Checking if all information is available.	
	if (!common_validations()) {
		return 0;
	}
	
	# Testing if dd-root directory has been filled.
	if (length($deb_downloader_options{'file'}) == 0) {
   	   print("Uris file has not been filled.\n");
	   return 0;
	}

	# Checking if --skip action option is activated.
	if ($deb_downloader_options{'skip-action'} eq YES) {
   	   print("There is not action to skip. You are only copying the files\n");
	}
	
    # Obtaining uris from file (we have not another source from taking the uris).
	@uris_to_copy = obtain_uris(read_file($deb_downloader_options{'file'}));		
	
	# Copy all .deb files into output-directory.
	$files_copied_ok = copy_files($deb_downloader_options{'dd-root'}, 
								  $deb_downloader_options{'output-directory'}, 
								  @uris_to_copy);
								  
	if (!$files_copied_ok) {
   	   print("Files can not be copied.\n");
	   return 0;
	}	
	
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
		elsif ($_[$i] =~ /--dd-root=((?:[^ ]*\+?)+)/) {
			$deb_downloader_options{'dd-root'} = $1;
			if ($deb_downloader_options{'dd-root'} =~ /.*[^\/]/) {
				$deb_downloader_options{'dd-root'} .= '/';
			}
		}
		elsif ($_[$i] =~ /--output-directory=((?:[^ ]*\+?)+)/) {
			$deb_downloader_options{'output-directory'} = $1;	
		}
		elsif ($_[$i] eq "--mirror-format") {
			$deb_downloader_options{'mirror-format'} = YES;
		}
		elsif ($_[$i] eq "--help") {
			$deb_downloader_options{'help'} = YES;
		}
		elsif ($_[$i] eq "--version") {
			$deb_downloader_options{'version'} = YES;
		}
		elsif ($_[$i] eq "copy-files") {
			$deb_downloader_options{'copy-files'} = YES;
		}		
		elsif ($_[$i] eq "dist-upgrade") {
			$deb_downloader_options{'dist-upgrade'} = YES;
		}
		elsif ($_[$i] eq "install") {
			while ($i+1<scalar(@ARGV) && !($ARGV[$i+1] =~ /^(-d|--debug|--file=.*|--dd-root=.*|--output-directory=.*|--mirror-format|--skip-action|--help|--version|dist-upgrade|copy-files)$/)) {
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
		elsif ($_[$i] eq "--skip-action") { # action = dist-upgrade, install or copy-files.
			$deb_downloader_options{'skip-action'} = YES;		
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
	if ($deb_downloader_options{'dist-upgrade'} eq YES) {
		$rcOK = dist_upgrade_distro()
	}
	elsif ($deb_downloader_options{'install'} ne NO) {
		$rcOK = install_packages();
	}
	elsif ($deb_downloader_options{'copy-files'} eq YES) {
		$rcOK = just_copy_files();
	}
	else {
		print("Action not provided.\n");
		deb_downloader_exit(1);	
	}
	
	if (($deb_downloader_options{'dist-upgrade'} eq YES || $deb_downloader_options{'install'} eq YES) &&
		$deb_downloader_options{'skip-action'} ne NO) {
		print("\nPackages installed ". (($rcOK) ? "OK :-)" : "NOK :-(") . "\n\n");
	}
	else {
		print("\nPackages copied ". (($rcOK) ? "OK :-)" : "NOK :-(") . "\n\n");
	}	
	
	if (!$rcOK) {
		deb_downloader_exit(1);
	}
	
}

deb_downloader_exit(0);
