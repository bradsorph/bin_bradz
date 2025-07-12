# bin_bradz

A collection of scripts for automating various jobs.

## Scope of this repo

This repo contains mainly Bash scripts I use to automate my work.  
They are developed in a *quick and dirty* way, so they are not intended to be high-quality code.  
There are better and more usable, but longer, ways to do these tasks.

Any contribution to improve these scripts is welcome.

---

## Collections

### travel_utils

Scripts for managing data on a USB stick while traveling.

- **datasync.sh**  
  Run this script from your destination USB stick path. It syncs the directories listed in the file `tosync.txt` (absolute paths required).

- **listModified.sh**  
  After returning from travel, run this script from the USB stick path.  
  Provide your leave date as input in the format `YYYY-MM-DD`.  
  The script will show which files were modified on the USB stick during your travel, so you can update the corresponding files on your desktop PC.

---

### web_scripts

Web-oriented scripts.

- **check_url.sh**  
  Useful for monitoring overloaded websites to know when they become accessible.  
  This script repeatedly tries to contact a specified URL (default: `google.it`) using `curl` until it succeeds.  
  Each attempt is logged to a file named after the script (e.g., `check_url.sh.log`).  
  If `curl` succeeds (exit code 0), it prints a success message and stops retrying.  
  If it fails, it prints the exit code and a link to curl exit code documentation.  
  After a successful connection, it runs an audible alert in a loop, printing "Alert running. Press CTRL+c to stop!" and beeping every second until you manually stop the script.

---

### fs_utils

Scripts for file system management.

- **searchBigFiles.sh**  
  Useful for freeing up disk space by detecting the largest files.  
  The script searches for files larger than 1024 MB (1 GB) in the home directory and its subdirectories (size can be changed).  
  It writes the paths and sizes of these large files to `/tmp/bigfiles.txt`.  
  For each file found, if its size exceeds 1024 MB, it logs the file and adds its size to a running total.  
  It prints a dot periodically to show progress.  
  At the end, it prints the total size of all large files found.  
  The script prints the date at the start and end for timing reference.

---

#### backup-sync

A set of scripts to be placed in your external backup device to sync important directories and configuration of your PC, such as:

- A configurable directory (typically your home directory)
- The `/etc` configuration directory (requires sudo privileges for `rsync`)
- The list of installed packages (works for Debian-based Linux distributions)

**Scripts:**

- **runbackup.sh**  
  Performs a backup operation with pre-cleanup steps, using the variables at the top as input parameters:
    - `DIRTOBKP`: main directory to back up
    - `TEMPDIRS`: temporary directories inside `DIRTOBKP` to check and optionally clean
    - `SCRIPTBKP`: backup script to run (`backupDataNinfo.sh`)

  **Steps:**
  1. For each directory in `TEMPDIRS`, counts the files.
  2. If files are present, prompts the user to delete them.
  3. If the user agrees, deletes all files in that directory.
  4. After checking all temporary directories, starts the backup script (`SCRIPTBKP`) in the background using `nohup`, so it continues running even if the terminal closes. Output goes to `nohup.out`.

- **backupDataNinfo.sh**  
  Performs backup and system info collection, using the variables at the top as input parameters:
    - `DIRTOBKP`: directory to back up
    - `AUDIOALERT`: audio file to play when the backup finishes

  **Steps:**
  1. Backs up `DIRTOBKP` to the current directory using `rsync`, excluding the `.cache` folder.
  2. Backs up `/etc` to the current directory using `rsync`.
  3. If a file named `nohup.out` exists, renames it with a timestamp.
  4. Lists all installed packages and saves the list to a timestamped file.
  5. Plays the audio alert file (`AUDIOALERT`) to signal completion.
  6. Prints `#END` when finished.

- **rotatenohup.sh**  
  Rotates the `nohup.out` file after execution to archive the last run.

---