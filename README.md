# bin_bradz
The collection of my scripts

## Scope of this repo

This repo is the collection of the scripts I use to automate my jobs.

They are developed in *quick and dirty* way, so they do not suppose to be an high quality code. There is the better and more usuable, but longest way to do this.

Any contribution in this direction is well accepted.

## The collections

### travel_utils

This is a script that I use to manage a small amount of data that I want to have with me in a USB stick when I am trabvelling.

- **datasync.sh** - This script needs to be run from your destination USB stick path. It sync the directory listed in the file *tosync.txt* (absolute path is required).
- **listModified** - After returning from travel, run this script from the USB stick path. Provide your leave date as input in the format YYYY-MM-DD. The script will show which files were modified on the USB stick during your travel, so you can update the corresponding files on your desktop PC with the latest versions.

### web_scripts

Web oriented scripts.

 - **check_url.sh** - Often there are overloaded websites that we wants to know when they are browsabe, due to lower traffic.
This script repeatedly tries to contact a specified URL variable (*google.it* in this example, but you can change it) using curl until it succeeds.
Each attempt is logged to a file named after the script ( *check_url.sh.log* ).
If curl succeeds (exit code 0), it prints a success message and stops retrying.
If it fails, it prints the exit code and a link to curl exit code documentation.
After a successful connection, it runs an audible alert in a loop, printing "Alert running. Press CTRL+c to stop!" and beeping every second until you manually stop the script.