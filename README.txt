~~~~~~~~~~~~~~~~~~
~ deb-downloader ~
~~~~~~~~~~~~~~~~~~


 OVERVIEW
~~~~~~~~~~

	This is an utility called deb-downloader, a tool implemented for 
a specific GNU/Linux distro called Debian (or Debian based distros). 
deb-downloader was written when my "high speed" internet connection 
was down because of my house moving. 
This event made me think about which was the best way for upgrading my 
Debian Sid (Debian has three versions (stable, testing and sid also 
called Sid (an urban legend says it means System In Development)).

	I had heard about a Debian tool called apt-zip, but I didn't have a
GNU/Linux distro at work so I decided to write this tool. deb-downloader
is written in Perl, so the only requirement for its use is having an 
operating system with a perl interpreter as *nix systems, Macintosh 
(OS 7-9 and X), VMS, Windows, etc. (for more details see cpan page in 
http://www.cpan.org/ports/index.html).

	This utility is divided in three scripts. The first one and the 
third one are executed in a Debian distro and the second one in a 
machine with any operating system containing a perl interpreter.

	I hope it will be useful for everybody who use it.
	

 REQUIREMENTS
~~~~~~~~~~~~~~

	There are two requirements for using deb-downloader.
	
		- Debian GNU/Linux (or Debian based distro) with perl interpre-
		  ter for deb-downloader-build and deb-downloader-install.
		- Perl interpreter with Net::FTP and Net::HTTP modules for 
		  deb-downloader-download.


 INSTALL
~~~~~~~~~

	- tar xvfz deb-downloader-nn.nn.nn.tar.gz target_dir.
	- tar xvfj deb-downloader-nn.nn.nn.tar.bz target_dir.
	.
	.
	.

	
 USE
~~~~~

	These are the three steps :

	- deb-downloader-build : This script is used for recollecting all 
	  the .deb uris needed for downloading the packages. This option is
	  executed in a Debian distro.

		deb-downloader-build --help| --version | ([-d|--debug] --file=filename install package1...packagen|dist-upgrade [--skip-update])
		
		-d|--debug : View execution extra messages. Important for 
	  	  reporting a bug.
		--help : Prints deb-downloader help.
		--version : Prints deb-downloader version.
		--file : Filename where uris will be saved.
		--skip-update : Skip apt-get update execution (with this 
		  option activated, it doesn't have to be executed as root 
		  user.
		install package1...packagen : Select the packages to down-
		  load (apt-get install whatever).
		  dist-upgrade : Upgrade the distro (apt-get dist-upgrade).
			
		
	- deb-downloader-download : This script is used for downloading 
	  the .deb packages needed. It can be executed in any computer 
	  with any operating system with a perl interpreter.
				 
		deb-downloader-download --file=filename1...filenamen [-d|--debug] [--dd-root=directory] [--skip-downloaded]
		
			-d|--debug : View execution extra messages. Important for 
			  reporting a bug.
			--help : Prints deb-downloader help.
			--version : Prints deb-downloader version.			
			--file : Filename(s) where uris are read from.		
			--dd-root : Specify target destination for downloaded .deb 
			  packages (dd-root folder by default).
			--skip-downloaded : If this option is activated, packages 
			  already downloader will not be downloaded  again (if you 
			  have stopped your execution and the process has not fini-
			  shed yet).
				 
	- deb-downloader-install : This script (the last step) is used for 
	  installing the packages into the /var/cache/apt/archives and, if 
	  you want, execute apt-get dist-upgrade, apt-get install whatever 
	  or nothing, as you like.
		
		deb-downloader-install --file=filename [-d|--debug] [install
		package1...packagen|dist-upgrade][--mirror-format] [--dd-root=directory] [--output-directory=directory]
		
			-d|--debug : View execution extra messages. Important for 
			  reporting a bug.
			--help : Prints deb-downloader help.
			--version : Prints deb-downloader version.			
			--file : Filename where uris are read from.		
			--dd-root : Specify source for downloaded .deb packages 
			  (dd-root folder by default).
			--output-directory : Specify target for downloaded .deb pa-
			  ckages (/var/cache/apt/archives folder by default).		
			--mirror-format : With this option activated, packages are 
			  written with mirror structure.		
			--skip-action : This option skips the action (dist-upgrade 
			  or install whatever).
			install package1...packagen : Select the packages to down-
			  load (apt-get install whatever).
			dist-upgrade : Upgrade the distro (apt-get dist-upgrade).
			copy-files : Just copy the files into the specified direc-
			tory.

		
 BUGS, PATCHES, REQUIREMENT & SUGGESTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	Please report all bugs, patches, requirements and suggestions to 
debdownloader@gmail.com, everything will be welcomed (if there's some 
interesting suggestion, I will try to include it in the next release).

	If you want to comment something, you can also post it to the 
deb-downloader  mailing lists, which can be found in the web page 

	http://deb-downloader.berlios.de/lists.php?lang=en.


 LICENSE
~~~~~~~~~

	This program is free software; you can redistribute it and/or modi-
fy it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option) any
later version.

	This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABI-
LITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public 
License for more details.

